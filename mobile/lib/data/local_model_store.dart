import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/local_llm_engine.dart';
import '../domain/local_assistant_message.dart';

class LocalModelSettings {
  const LocalModelSettings({
    this.enabled = false,
    this.path,
    this.name,
    this.tone = LocalAssistantTone.gentle,
    this.persona = defaultLocalAssistantPersona,
  });

  final bool enabled;
  final String? path;
  final String? name;
  final LocalAssistantTone tone;
  final String persona;
}

class LocalModelCancelled implements Exception {
  const LocalModelCancelled();
}

/// A cancellation handle shared by import, download and validation.
class LocalModelOperation {
  bool _cancelled = false;
  bool _timedOut = false;
  void Function()? _abort;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _abort?.call();
  }

  void check() {
    if (_timedOut) throw TimeoutException('模型传输超时');
    if (_cancelled) throw const LocalModelCancelled();
  }

  void _timeout() {
    _timedOut = true;
    cancel();
  }
}

enum LocalModelInstallStage {
  connecting,
  downloading,
  importing,
  verifying,
  activating,
}

class LocalModelInstallProgress {
  const LocalModelInstallProgress({
    required this.stage,
    this.receivedBytes = 0,
    this.totalBytes,
  });

  final LocalModelInstallStage stage;
  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    if ((stage != LocalModelInstallStage.downloading &&
            stage != LocalModelInstallStage.importing) ||
        totalBytes == null ||
        totalBytes! <= 0) {
      return null;
    }
    return (receivedBytes / totalBytes!).clamp(0, 1);
  }
}

class LocalModelDescriptor {
  const LocalModelDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
    this.isRecommended = false,
    this.legacyNames = const [],
  });

  final String id;
  final String name;
  final String description;
  final String url;
  final String sha256;
  final int sizeBytes;
  final bool isRecommended;
  final List<String> legacyNames;

  bool matches(InstalledLocalModel model) => model.modelId != null
      ? model.modelId == id
      : _matchesLegacyName(model.name);

  bool _matchesLegacyName(String value) {
    if (value == name || legacyNames.contains(value)) return true;
    String normalized(String text) =>
        text.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final fileName = Uri.parse(url).pathSegments.last;
    final signature = normalized(fileName.replaceFirst(RegExp(r'\.gguf$'), ''));
    return signature.isNotEmpty && normalized(value).contains(signature);
  }

  LocalModelDescriptor _withDownloadOverride(Uri? uri, String? digest) =>
      LocalModelDescriptor(
        id: id,
        name: name,
        description: description,
        url: uri?.toString() ?? url,
        sha256: digest ?? sha256,
        // Existing constructor injection accepts tiny local-server fixtures.
        sizeBytes: uri != null || digest != null ? 0 : sizeBytes,
        isRecommended: isRecommended,
        legacyNames: legacyNames,
      );
}

const _qualityModelName = 'Qwen3-4B Instruct · 质量优先';
const _qualityModelUrl =
    'https://huggingface.co/bartowski/Qwen_Qwen3-4B-Instruct-2507-GGUF/resolve/main/Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf';
const _qualityModelSha256 =
    '2fde00ce69dd4899c70d020845e2638353015bba0fdf161b3eb965f2bca4464e';

const localBalancedModel = LocalModelDescriptor(
  id: 'qwen3-1.7b-q4_k_m',
  name: 'Qwen3-1.7B · 均衡',
  description: '约 1.28 GB，在模型大小与回复能力之间取平衡；比轻量版占用更多，效果仍取决于设备与内容。',
  url:
      'https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf',
  sha256: 'd2387ca2dbfee2ffabce7120d3770dadca0b293052bc2f0e138fdc940d9bc7b5',
  sizeBytes: 1282439264,
  legacyNames: ['Qwen3-1.7B · 质量优先'],
);

const localInstructModel = LocalModelDescriptor(
  id: 'qwen3-4b-instruct-2507-q4_k_m',
  name: _qualityModelName,
  description:
      '约 2.50 GB，非思考 Instruct 模型，优先尝试更自然的回应；需要更多内存，加载和回复可能更慢，效果仍取决于设备与内容。',
  url: _qualityModelUrl,
  sha256: _qualityModelSha256,
  sizeBytes: 2497280736,
  isRecommended: true,
  legacyNames: ['Qwen3-4B Instruct · 大模型'],
);

const localQualityModel = localInstructModel;

const localLightweightModel = LocalModelDescriptor(
  id: 'qwen3-0.6b-q4_0',
  name: 'Qwen3-0.6B · 轻量',
  description: '约 429 MB，占用较小，加载和回复通常更快，适合简单回应。',
  url:
      'https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_0.gguf',
  sha256: 'da2572f16c06133561ce56accaa822216f2391ef4d37fba427801cd6736417d4',
  sizeBytes: 428970080,
);

const localRecommendedModels = [
  localQualityModel,
  localBalancedModel,
  localLightweightModel,
];

class InstalledLocalModel {
  const InstalledLocalModel({
    required this.path,
    required this.name,
    this.sizeBytes = 0,
    this.isRecommended = false,
    this.modelId,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final bool isRecommended;
  final String? modelId;

  Map<String, Object?> toJson() => {
    'path': path,
    'name': name,
    'sizeBytes': sizeBytes,
    'isRecommended': isRecommended,
    'modelId': modelId,
  };
}

/// Model files and preferences live outside the diary and its synchronization.
class LocalModelStore {
  LocalModelStore({
    this.rootDirectory,
    Uri? recommendedModelUri,
    String? recommendedSha256,
    List<LocalModelDescriptor>? recommendedModels,
  }) : assert(recommendedModels == null || recommendedModels.isNotEmpty),
       _recommendedUri = recommendedModelUri,
       _recommendedSha256 = recommendedSha256,
       recommendedModels = List.unmodifiable(
         recommendedModels ?? localRecommendedModels,
       );

  static const recommendedModelName = _qualityModelName;
  static const recommendedModelUrl = _qualityModelUrl;
  static const recommendedModelSha256 = _qualityModelSha256;
  static const maxModelBytes = 3 * 1024 * 1024 * 1024;
  static const transferTimeout = Duration(minutes: 20);
  static const maxInstalledModels = 32;
  final Directory? rootDirectory;
  final Uri? _recommendedUri;
  final String? _recommendedSha256;
  final List<LocalModelDescriptor> recommendedModels;
  Future<void> _writes = Future<void>.value();
  Future<void> _catalogWrites = Future<void>.value();
  int _fileSequence = 0;

  Future<Directory> _root() async =>
      rootDirectory ??
      Directory(
        p.join(
          (await getApplicationSupportDirectory()).path,
          'local-assistant',
        ),
      );

  Future<Directory> _models() async =>
      Directory(p.join((await _root()).path, 'models'));

  Future<LocalModelSettings> readSettings() async {
    await _writes;
    final file = File(p.join((await _root()).path, 'model-settings.json'));
    if (!await file.exists()) return const LocalModelSettings();
    if (await file.length() > 4096) {
      throw const FormatException('本地模型设置格式不正确');
    }
    final value = jsonDecode(await file.readAsString());
    if (value is! Map ||
        value['version'] != 1 ||
        value['enabled'] is! bool ||
        (value['path'] != null && value['path'] is! String) ||
        (value['name'] != null && value['name'] is! String)) {
      throw const FormatException('本地模型设置格式不正确');
    }
    final path = value['path'] as String?;
    if (path != null && !await _owns(path)) {
      throw const FormatException('本地模型路径不正确，请重新导入');
    }
    return LocalModelSettings(
      enabled: value['enabled'] as bool,
      path: path,
      name: value['name'] as String?,
      tone: LocalAssistantTone.values.firstWhere(
        (tone) => tone.name == value['tone'],
        orElse: () => LocalAssistantTone.gentle,
      ),
      persona:
          value['persona'] is String &&
              (value['persona'] as String).trim().isNotEmpty &&
              (value['persona'] as String).length <= 600
          ? (value['persona'] as String).trim()
          : defaultLocalAssistantPersona,
    );
  }

  Future<void> writeSettings(LocalModelSettings settings) {
    final contents = jsonEncode({
      'version': 1,
      'enabled': settings.enabled,
      'path': settings.path,
      'name': settings.name,
      'tone': settings.tone.name,
      'persona': settings.persona,
    });
    final write = _writes.then((_) async {
      final root = await _root();
      await root.create(recursive: true);
      final destination = File(p.join(root.path, 'model-settings.json'));
      final staging = File('${destination.path}.part');
      try {
        await staging.writeAsString(contents, flush: true);
        await staging.rename(destination.path);
      } finally {
        if (await staging.exists()) await staging.delete();
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  Future<bool> exists(String path) async =>
      await _owns(path) && await File(path).exists();

  Future<void> validateModel(String path) async {
    if (!await exists(path)) {
      throw const FormatException('所选模型文件不存在，请重新选择或导入');
    }
    await validateLocalLlmModel(path);
  }

  Future<List<InstalledLocalModel>> listInstalledModels({
    LocalModelSettings? settings,
  }) async {
    await _catalogWrites;
    var models = await _readCatalog();
    final selected = settings ?? await readSettings();
    // Older versions only recorded the selected model. Recover it by stat,
    // without hashing every model or loading a native inference engine.
    if (selected.path != null &&
        await exists(selected.path!) &&
        !models.any((model) => model.path == selected.path)) {
      final name = selected.name ?? p.basename(selected.path!);
      final descriptor = _descriptorForName(name);
      final legacy = InstalledLocalModel(
        path: selected.path!,
        name: name,
        sizeBytes: await File(selected.path!).length(),
        // This hint only affects UI grouping; validation never trusts the name.
        isRecommended: descriptor?.isRecommended ?? false,
        modelId: descriptor?.id,
      );
      await _recordModel(legacy);
      models = await _readCatalog();
    }
    return List.unmodifiable(models);
  }

  LocalModelDescriptor? _descriptorForName(String name) => recommendedModels
      .where((model) => model._matchesLegacyName(name))
      .firstOrNull;

  LocalModelDescriptor _downloadDescriptor(LocalModelDescriptor? model) {
    final selected = model ?? recommendedModels.first;
    return selected.id == recommendedModels.first.id
        ? selected._withDownloadOverride(_recommendedUri, _recommendedSha256)
        : selected;
  }

  Future<List<InstalledLocalModel>> _readCatalog() async {
    final file = File(p.join((await _root()).path, 'model-catalog.json'));
    if (!await file.exists()) return [];
    if (await file.length() > 128 * 1024) {
      throw const FormatException('本地模型列表过大');
    }
    final value = jsonDecode(await file.readAsString());
    if (value is! Map ||
        value['version'] != 1 ||
        value['models'] is! List ||
        (value['models'] as List).length > maxInstalledModels) {
      throw const FormatException('本地模型列表格式不正确');
    }
    final result = <InstalledLocalModel>[];
    final seen = <String>{};
    for (final raw in value['models'] as List) {
      if (raw is! Map ||
          raw['path'] is! String ||
          raw['name'] is! String ||
          (raw['name'] as String).length > 512 ||
          raw['sizeBytes'] is! int ||
          raw['isRecommended'] is! bool ||
          (raw['modelId'] != null &&
              (raw['modelId'] is! String ||
                  (raw['modelId'] as String).length > 128))) {
        throw const FormatException('本地模型列表格式不正确');
      }
      final path = raw['path'] as String;
      if (!await _owns(path)) throw const FormatException('本地模型列表路径不正确');
      if (!seen.add(path) || !await File(path).exists()) continue;
      final modelId = raw['modelId'] as String?;
      final descriptor = modelId == null
          ? _descriptorForName(raw['name'] as String)
          : recommendedModels.where((model) => model.id == modelId).firstOrNull;
      result.add(
        InstalledLocalModel(
          path: path,
          name: raw['name'] as String,
          sizeBytes: await File(path).length(),
          isRecommended:
              descriptor?.isRecommended ?? raw['isRecommended'] as bool,
          modelId: modelId ?? descriptor?.id,
        ),
      );
    }
    return result;
  }

  Future<void> _recordModel(InstalledLocalModel model) =>
      _mutateCatalog((models) {
        final result = models.where((old) => old.path != model.path).toList()
          ..add(model);
        if (result.length > maxInstalledModels) {
          throw const FormatException('最多保存 32 个本地模型，请先移除不需要的模型');
        }
        return result;
      });

  Future<void> _mutateCatalog(
    List<InstalledLocalModel> Function(List<InstalledLocalModel>) update,
  ) {
    final write = _catalogWrites.then((_) async {
      final models = update(await _readCatalog());
      final root = await _root();
      await root.create(recursive: true);
      final destination = File(p.join(root.path, 'model-catalog.json'));
      final staging = File('${destination.path}.part');
      try {
        await staging.writeAsString(
          jsonEncode({
            'version': 1,
            'models': models.map((model) => model.toJson()).toList(),
          }),
          flush: true,
        );
        await staging.rename(destination.path);
      } finally {
        if (await staging.exists()) await staging.delete();
      }
    });
    _catalogWrites = write.catchError((Object _) {});
    return write;
  }

  Future<bool> _owns(String path) async {
    final root = p.normalize(p.absolute((await _models()).path));
    final target = p.normalize(p.absolute(path));
    return p.isWithin(root, target) && p.extension(target) == '.gguf';
  }

  Future<void> removeModel(String path) async {
    if (!await _owns(path)) {
      throw const FileSystemException('模型不在应用存储目录中');
    }
    final file = File(path);
    final previous = (await listInstalledModels())
        .where((model) => model.path == path)
        .firstOrNull;
    await _mutateCatalog(
      (models) => models.where((model) => model.path != path).toList(),
    );
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      if (previous != null) await _recordModel(previous);
      rethrow;
    }
  }

  Future<InstalledLocalModel> importModel(
    String path, {
    required LocalModelOperation operation,
    void Function(double? progress)? onProgress,
    void Function(LocalModelInstallProgress progress)? onInstallProgress,
  }) async {
    operation.check();
    final source = File(path);
    if (!await source.exists()) {
      throw const FileSystemException('所选模型文件不可用');
    }
    final length = await source.length();
    _checkLength(length);
    return _install(
      source.openRead().timeout(const Duration(seconds: 30)),
      length: length,
      name: p.basename(path),
      operation: operation,
      onProgress: onProgress,
      onInstallProgress: onInstallProgress,
      transferStage: LocalModelInstallStage.importing,
    );
  }

  Future<InstalledLocalModel> downloadRecommendedModel({
    LocalModelDescriptor? model,
    required LocalModelOperation operation,
    void Function(double? progress)? onProgress,
    void Function(LocalModelInstallProgress progress)? onInstallProgress,
  }) async {
    final descriptor = _downloadDescriptor(model);
    operation.check();
    onInstallProgress?.call(
      const LocalModelInstallProgress(stage: LocalModelInstallStage.connecting),
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);
    operation._abort = () => client.close(force: true);
    try {
      final request = await client
          .getUrl(Uri.parse(descriptor.url))
          .timeout(const Duration(seconds: 30));
      operation.check();
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('模型下载失败（HTTP ${response.statusCode}）');
      }
      final length = response.contentLength;
      if (length >= 0) _checkLength(length);
      if (length >= 0 &&
          descriptor.sizeBytes > 0 &&
          length != descriptor.sizeBytes) {
        throw const FormatException('模型文件大小不匹配，请重新下载');
      }
      return await _install(
        response.timeout(const Duration(seconds: 30)),
        length: length >= 0
            ? length
            : descriptor.sizeBytes > 0
            ? descriptor.sizeBytes
            : null,
        name: descriptor.name,
        expectedSha256: descriptor.sha256,
        downloadedModel: descriptor,
        operation: operation,
        onProgress: onProgress,
        onInstallProgress: onInstallProgress,
        transferStage: LocalModelInstallStage.downloading,
      );
    } catch (_) {
      operation.check();
      rethrow;
    } finally {
      operation._abort = null;
      client.close(force: true);
    }
  }

  Future<InstalledLocalModel> _install(
    Stream<List<int>> bytes, {
    required int? length,
    required String name,
    required LocalModelOperation operation,
    String? expectedSha256,
    LocalModelDescriptor? downloadedModel,
    void Function(double? progress)? onProgress,
    void Function(LocalModelInstallProgress progress)? onInstallProgress,
    required LocalModelInstallStage transferStage,
  }) async {
    final directory = await _models();
    await directory.create(recursive: true);
    final destination = File(
      p.join(
        directory.path,
        'model-${DateTime.now().microsecondsSinceEpoch}-${_fileSequence++}.gguf',
      ),
    );
    final staging = File('${destination.path}.part');
    final deadline = Timer(transferTimeout, operation._timeout);
    IOSink? sink;
    try {
      operation.check();
      sink = staging.openWrite();
      var written = 0;
      onProgress?.call(length == null ? null : 0);
      onInstallProgress?.call(
        LocalModelInstallProgress(stage: transferStage, totalBytes: length),
      );
      await for (final chunk in bytes) {
        operation.check();
        written += chunk.length;
        if (written > maxModelBytes) {
          throw const FormatException('模型文件超过支持的大小（3 GiB）');
        }
        sink.add(chunk);
        // Flush applies backpressure instead of queueing a whole model in RAM.
        await sink.flush();
        onProgress?.call(
          length == null ? null : (written / length).clamp(0, 1),
        );
        onInstallProgress?.call(
          LocalModelInstallProgress(
            stage: transferStage,
            receivedBytes: written,
            totalBytes: length,
          ),
        );
      }
      await sink.close();
      sink = null;
      operation.check();
      _checkLength(written);
      if (length != null && written != length) {
        throw const FormatException('模型文件传输不完整，请重试');
      }
      final stagingPath = staging.path;
      onInstallProgress?.call(
        LocalModelInstallProgress(
          stage: LocalModelInstallStage.verifying,
          receivedBytes: written,
          totalBytes: written,
        ),
      );
      final digest = await _validateFileInIsolate(stagingPath, expectedSha256);
      operation.check();
      // Metadata bounds and tensor shapes are checked before native allocation.
      await validateLocalLlmModel(stagingPath);
      operation.check();
      await staging.rename(destination.path);
      final descriptor =
          downloadedModel ??
          recommendedModels
              .where(
                (candidate) => _downloadDescriptor(candidate).sha256 == digest,
              )
              .firstOrNull;
      final installed = InstalledLocalModel(
        path: destination.path,
        name: name,
        sizeBytes: written,
        isRecommended: descriptor?.isRecommended ?? false,
        // New imports that do not match a pinned digest must not acquire a
        // download identity merely because their source file has a familiar name.
        modelId: descriptor?.id ?? 'custom',
      );
      try {
        await _recordModel(installed);
        operation.check();
      } catch (_) {
        await removeModel(installed.path);
        rethrow;
      }
      return installed;
    } catch (_) {
      operation.check();
      rethrow;
    } finally {
      deadline.cancel();
      await sink?.close();
      if (await staging.exists()) await staging.delete();
    }
  }

  static void _checkLength(int length) {
    if (length < 24) throw const FormatException('模型文件为空或不完整');
    if (length > maxModelBytes) {
      throw const FormatException('模型文件超过支持的大小（3 GiB）');
    }
  }
}

Future<String> _validateFileInIsolate(String path, String? expectedSha256) =>
    Isolate.run(() => _validateFile(path, expectedSha256));

Future<String> _validateFile(String path, String? expectedSha256) async {
  final file = File(path);
  final length = await file.length();
  LocalModelStore._checkLength(length);
  final reader = await file.open();
  try {
    final bytes = await reader.read(24);
    if (bytes.length != 24 ||
        bytes[0] != 0x47 ||
        bytes[1] != 0x47 ||
        bytes[2] != 0x55 ||
        bytes[3] != 0x46) {
      throw const FormatException('请选择 GGUF 格式的模型文件');
    }
    final header = ByteData.sublistView(Uint8List.fromList(bytes));
    final version = header.getUint32(4, Endian.little);
    final tensors = header.getUint64(8, Endian.little);
    final metadata = header.getUint64(16, Endian.little);
    if ((version != 2 && version != 3) ||
        tensors < 1 ||
        tensors > 1024 ||
        metadata > 128 ||
        tensors > length ~/ 16 ||
        metadata > length ~/ 12) {
      throw const FormatException('模型头信息不正确或不受支持');
    }
  } finally {
    await reader.close();
  }
  final digest = (await sha256.bind(file.openRead()).first).toString();
  if (expectedSha256 != null) {
    if (digest != expectedSha256) {
      throw const FormatException('模型校验失败，请重新下载');
    }
  }
  return digest;
}
