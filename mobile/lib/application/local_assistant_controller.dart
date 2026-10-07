import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/local_assistant_store.dart';
import '../data/assistant_provider_store.dart';
import '../domain/assistant_provider_settings.dart';
import '../data/local_model_store.dart';
import '../domain/local_assistant_message.dart';
import '../services/local_llm_engine.dart';
import '../services/diary_reply_strategy.dart';
import '../services/online_model_adapter.dart';

/// Gives saved entries a short response through an explicitly selected strategy.
class LocalAssistantController extends ChangeNotifier {
  LocalAssistantController({
    required LocalLlmEngine engine,
    LocalAssistantStore? store,
    LocalModelStore? models,
    AssistantProviderStore? providers,
    DiaryReplyStrategy Function(OnlineModelConfiguration, String)?
    onlineStrategyFactory,
    bool? supportedOverride,
    bool Function()? canStart,
    Duration replyDelay = const Duration(milliseconds: 800),
  }) : _engine = engine,
       _store = store ?? LocalAssistantStore(),
       _models = models ?? LocalModelStore(),
       _providers = providers ?? AssistantProviderStore(),
       _onlineStrategyFactory = onlineStrategyFactory ?? _createOnlineStrategy,
       _canStart = canStart ?? (() => true),
       _replyDelay = replyDelay,
       _supported =
           supportedOverride ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static const maxPersonaCharacters = 600;
  static const defaultPersona = defaultLocalAssistantPersona;
  static const maxPendingReplies = 3;
  final LocalLlmEngine _engine;
  final LocalAssistantStore _store;
  final bool Function() _canStart;
  final LocalModelStore _models;
  final AssistantProviderStore _providers;
  final DiaryReplyStrategy Function(OnlineModelConfiguration, String)
  _onlineStrategyFactory;
  AssistantProviderSettings _providerSettings =
      const AssistantProviderSettings();
  final Set<OnlineModelProvider> _providersWithKeys = {};
  DiaryReplyStrategy? _replyStrategy;
  DiaryReplyStrategy? _connectionStrategy;
  bool _testingConnection = false;
  String? _connectionStatus;
  final bool _supported;
  final Duration _replyDelay;
  List<LocalAssistantMessage> _messages = const [];
  final List<_ReplyRequest> _queue = [];
  final Set<String> _forgottenEntryIds = {};
  final Map<String, String> _replyErrors = {};
  final Map<String, int> _entryRevisions = {};
  Future<void>? _initialization;
  bool _initialized = false;
  bool _enabled = false;
  bool _loading = false;
  bool _generating = false;
  bool _installing = false;
  bool _mutating = false;
  bool _draining = false;
  bool _stopping = false;
  bool _disposed = false;
  String? _modelPath;
  String? _modelName;
  List<InstalledLocalModel> _installedModels = const [];
  LocalModelInstallProgress? _installProgress;
  String? _installingModelName;
  String? _error;
  double? _progress;
  LocalAssistantTone _tone = LocalAssistantTone.gentle;
  String _persona = defaultLocalAssistantPersona;
  String? _replyingEntryId;
  bool _replyUpdated = false;
  int _taskVersion = 0;
  int _modelMutationVersion = 0;
  int _queueVersion = 0;
  _ReplyRequest? _activeRequest;
  Timer? _notificationTimer;
  Timer? _replyTimer;
  DateTime? _nextReplyAt;
  LocalModelOperation? _modelOperation;
  Completer<void>? _installationCompletion;
  Completer<void>? _drainCompletion;
  Completer<void>? _stopCompletion;
  StreamSubscription<String>? _generationSubscription;
  Completer<void>? _generationCompletion;

  bool get initialized => _initialized;
  bool get localSupported => _supported;
  bool get supported => source == AssistantReplySource.online || localSupported;
  AssistantReplySource get source => _providerSettings.source;
  OnlineModelProvider get onlineProvider => _providerSettings.provider;
  OnlineModelConfiguration get onlineConfiguration =>
      configurationFor(onlineProvider);
  OnlineModelConfiguration configurationFor(OnlineModelProvider provider) =>
      _providerSettings.configurationFor(provider);
  bool hasApiKeyFor(OnlineModelProvider provider) =>
      _providersWithKeys.contains(provider);
  bool get hasApiKey => hasApiKeyFor(onlineProvider);
  bool get testingConnection => _testingConnection;
  String? get connectionStatus => _connectionStatus;
  bool get canUseSelectedModel {
    if (source == AssistantReplySource.local) return localSupported && hasModel;
    if (!hasApiKey) return false;
    try {
      onlineConfiguration.validate();
      return true;
    } on FormatException {
      return false;
    }
  }

  bool get enabled => _enabled;
  bool get loading => _loading;
  bool get generating => _generating;
  bool get installing => _installing;
  bool get busy =>
      _loading ||
      _generating ||
      _installing ||
      _mutating ||
      _draining ||
      _stopping ||
      _testingConnection;
  bool get ready => _enabled && canUseSelectedModel && !busy;
  String? get modelPath => _modelPath;
  String? get modelName => _modelName;
  double? get progress => _progress;
  LocalModelInstallProgress? get installProgress => _installProgress;
  String? get installingModelName => _installingModelName;
  List<InstalledLocalModel> get installedModels => _installedModels;
  List<LocalModelDescriptor> get recommendedModels => _models.recommendedModels;
  InstalledLocalModel? get currentModel {
    for (final model in _installedModels) {
      if (model.path == _modelPath) return model;
    }
    return null;
  }

  bool get hasModel => currentModel != null;
  String? get error => _error;
  LocalAssistantTone get tone => _tone;
  String get persona => _persona;
  String? get replyingEntryId => _replyingEntryId;
  List<LocalAssistantMessage> get messages => _messages;

  String? replyFor(String entryId) {
    for (final message in _messages.reversed) {
      if (message.id == entryId) return message.text;
    }
    return null;
  }

  String? replyErrorFor(String entryId) => _replyErrors[entryId];

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      _providerSettings = await _providers.readSettings();
      for (final provider in OnlineModelProvider.values) {
        try {
          final key = await _providers.readApiKey(provider);
          if (key?.trim().isNotEmpty == true) _providersWithKeys.add(provider);
        } catch (_) {
          // An unavailable secure store must not prevent offline diary use.
          if (source == AssistantReplySource.online &&
              provider == onlineProvider) {
            rethrow;
          }
        }
      }
      _messages = List.unmodifiable(await _store.load());
      final settings = await _models.readSettings();
      if (_disposed) return;
      _enabled = supported && settings.enabled;
      _tone = settings.tone;
      _persona = settings.persona;
      _installedModels = await _models.listInstalledModels(settings: settings);
      if (settings.path != null && await _models.exists(settings.path!)) {
        _modelPath = settings.path;
        _modelName = settings.name;
      } else if (source == AssistantReplySource.local &&
          (settings.path != null || settings.enabled)) {
        _enabled = false;
        _error = settings.path != null
            ? '模型文件已不存在，请重新选择、下载或导入'
            : '请先选择模型，再启用本地回应';
        await _saveSettings();
      }
      if (source == AssistantReplySource.online &&
          _enabled &&
          !canUseSelectedModel) {
        _enabled = false;
        _error = '请完善线上模型配置与 API Key，再开启日记陪伴';
        await _saveSettings();
      }
    } catch (error) {
      _enabled = false;
      _error = _describeError(error, '无法读取日记陪伴设置');
    } finally {
      if (!_disposed) {
        _initialized = true;
        _notify();
      }
    }
  }

  Future<void> enable(bool value) async {
    if (_disposed || _mutating) return;
    await initialize();
    if (_disposed || _mutating) return;
    if (!supported) {
      _error = '本地回应需要 Android 10 或更新版本及 64 位处理器';
      _notify();
      return;
    }
    final previousSettings = _settings(path: _modelPath, name: _modelName);
    final mutationVersion = _modelMutationVersion;
    _mutating = true;
    _notify();
    try {
      await _stop();
      if (_disposed || _modelMutationVersion != mutationVersion) return;
      final version = ++_taskVersion;
      if (value && source == AssistantReplySource.local) {
        if (_modelPath == null || !await _models.exists(_modelPath!)) {
          _enabled = false;
          _modelPath = null;
          _modelName = null;
          _installedModels = await _models.listInstalledModels(
            settings: _settings(),
          );
          _error = '请先选择已安装的模型，再启用本地回应';
          await _saveSettings();
          return;
        }
        _loading = true;
        _installingModelName = _modelName;
        _updateInstallProgress(
          const LocalModelInstallProgress(
            stage: LocalModelInstallStage.verifying,
          ),
        );
        await _models.validateModel(_modelPath!);
        if (!_active(version)) return;
        _updateInstallProgress(
          const LocalModelInstallProgress(
            stage: LocalModelInstallStage.activating,
          ),
        );
        await _engine.load(_modelPath!);
        if (!_active(version)) return;
      } else if (value) {
        onlineConfiguration.validate();
        final key = await _providers.readApiKey(onlineProvider);
        if (key?.trim().isNotEmpty != true) {
          throw const OnlineModelException('请先保存 API Key，再开启日记陪伴');
        }
        final strategy = _onlineStrategyFactory(onlineConfiguration, key!);
        try {
          await strategy.prepare();
        } finally {
          await strategy.dispose();
        }
        if (!_active(version)) return;
      }
      _enabled = value;
      _error = null;
      await _saveSettings();
      if (value && !_active(version)) {
        _enabled = previousSettings.enabled;
        await _models.writeSettings(previousSettings);
      }
    } catch (error) {
      _enabled = false;
      _error = _describeError(error, '模型配置校验失败，暂未启用日记陪伴');
      try {
        await _saveSettings();
      } catch (_) {}
    } finally {
      await _unload();
      _mutating = false;
      _loading = false;
      _installProgress = null;
      _installingModelName = null;
      _progress = null;
      _notify();
    }
  }

  static DiaryReplyStrategy _createOnlineStrategy(
    OnlineModelConfiguration configuration,
    String apiKey,
  ) => OnlineDiaryReplyStrategy(configuration: configuration, apiKey: apiKey);

  Future<void> setReplySource(AssistantReplySource value) async {
    if (_disposed || _mutating || _testingConnection) return;
    await initialize();
    if (_disposed || _mutating || value == source) return;
    final previous = _providerSettings;
    final previousEnabled = _enabled;
    _mutating = true;
    _notify();
    try {
      await _stop();
      await _unload();
      if (_disposed) return;
      final next = previous.copyWith(source: value);
      await _providers.writeSettings(next);
      _providerSettings = next;
      // Switching to an online provider is an explicit settings action. Missing
      // credentials cannot silently redirect any queued entry to another model.
      if (!canUseSelectedModel) _enabled = false;
      await _saveSettings();
      _error = null;
      _connectionStatus = null;
    } catch (error) {
      _providerSettings = previous;
      _enabled = previousEnabled;
      try {
        await _providers.writeSettings(previous);
      } catch (_) {}
      _error = _describeError(error, '无法切换回复来源');
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<void> saveOnlineConfiguration(
    OnlineModelConfiguration configuration, {
    String? apiKey,
    bool removeApiKey = false,
  }) async {
    if (_disposed || _mutating || _testingConnection) return;
    await initialize();
    if (_disposed || _mutating) return;
    final previous = _providerSettings;
    final previousEnabled = _enabled;
    String? previousKey;
    var keyChanged = false;
    _mutating = true;
    _notify();
    try {
      configuration.validate();
      await _stop();
      await _unload();
      if (_disposed) return;
      previousKey = await _providers.readApiKey(configuration.provider);
      if (removeApiKey) {
        await _providers.deleteApiKey(configuration.provider);
        keyChanged = true;
      } else if (apiKey?.trim().isNotEmpty == true) {
        await _providers.writeApiKey(configuration.provider, apiKey!);
        keyChanged = true;
      }
      final next = previous.copyWith(
        provider: configuration.provider,
        configurations: {
          ...previous.configurations,
          configuration.provider: configuration,
        },
      );
      await _providers.writeSettings(next);
      _providerSettings = next;
      final key = removeApiKey
          ? null
          : keyChanged
          ? apiKey!.trim()
          : previousKey;
      if (key?.isNotEmpty == true) {
        _providersWithKeys.add(configuration.provider);
      } else {
        _providersWithKeys.remove(configuration.provider);
      }
      if (source == AssistantReplySource.online && !canUseSelectedModel) {
        _enabled = false;
      }
      await _saveSettings();
      _error = null;
      _connectionStatus = null;
    } catch (error) {
      _providerSettings = previous;
      _enabled = previousEnabled;
      if (keyChanged) {
        try {
          if (previousKey == null) {
            await _providers.deleteApiKey(configuration.provider);
          } else {
            await _providers.writeApiKey(configuration.provider, previousKey);
          }
          if (previousKey?.isNotEmpty == true) {
            _providersWithKeys.add(configuration.provider);
          } else {
            _providersWithKeys.remove(configuration.provider);
          }
        } catch (_) {
          _providersWithKeys.remove(configuration.provider);
        }
      }
      try {
        await _providers.writeSettings(previous);
      } catch (_) {}
      _error = _describeError(error, '无法保存线上模型配置');
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<void> removeOnlineApiKey(OnlineModelProvider provider) async {
    if (_disposed || _mutating || _testingConnection) return;
    await initialize();
    if (_disposed || _mutating) return;
    _mutating = true;
    _notify();
    try {
      await _stop();
      await _unload();
      await _providers.deleteApiKey(provider);
      _providersWithKeys.remove(provider);
      if (source == AssistantReplySource.online && provider == onlineProvider) {
        _enabled = false;
        await _saveSettings();
      }
      _error = null;
      _connectionStatus = null;
    } catch (error) {
      _error = _describeError(error, '无法删除 API Key');
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<bool> testOnlineConnection(
    OnlineModelConfiguration configuration, {
    String? apiKey,
  }) async {
    if (_disposed || busy) return false;
    await initialize();
    if (_disposed || busy) return false;
    _testingConnection = true;
    _connectionStatus = null;
    _error = null;
    final version = ++_taskVersion;
    DiaryReplyStrategy? strategy;
    _notify();
    try {
      configuration.validate();
      final key = apiKey?.trim().isNotEmpty == true
          ? apiKey!.trim()
          : await _providers.readApiKey(configuration.provider);
      if (key?.isNotEmpty != true) {
        throw const OnlineModelException('请先填写 API Key');
      }
      strategy = _onlineStrategyFactory(
        configuration.copyWith(sendImages: false),
        key!,
      );
      _connectionStrategy = strategy;
      await strategy.prepare();
      if (!_active(version)) return false;
      var response = '';
      await for (final text in strategy.generate([
        LocalAssistantMessage(
          id: 'connection-test',
          role: LocalAssistantRole.user,
          text: '今天散步看到了晚霞，心情不错。',
          createdAt: DateTime.utc(2026),
        ),
      ])) {
        response = text;
      }
      if (!_active(version)) return false;
      if (response.trim().isEmpty) {
        throw const OnlineModelException('服务没有返回正文，请检查模型配置');
      }
      _connectionStatus = '连接成功，可以使用这个模型';
      return true;
    } catch (error) {
      if (_active(version)) {
        _connectionStatus = _describeError(error, '连接失败，请检查服务地址、模型和 API Key');
      }
      return false;
    } finally {
      await strategy?.dispose();
      if (identical(_connectionStrategy, strategy)) _connectionStrategy = null;
      _testingConnection = false;
      _notify();
      _scheduleDrain();
    }
  }

  Future<void> setReplyStyle({
    required LocalAssistantTone tone,
    required String persona,
  }) async {
    if (_disposed || _mutating) return;
    await initialize();
    if (_disposed || _mutating) return;
    final trimmed = persona.trim();
    if (trimmed.length > maxPersonaCharacters) {
      _error = '人设请控制在 $maxPersonaCharacters 字以内';
      _notify();
      return;
    }
    final previousTone = _tone;
    final previousPersona = _persona;
    _mutating = true;
    _notify();
    try {
      await _stop();
      if (_disposed) return;
      _tone = tone;
      _persona = trimmed.isEmpty ? defaultLocalAssistantPersona : trimmed;
      _error = null;
      await _saveSettings();
    } catch (error) {
      _tone = previousTone;
      _persona = previousPersona;
      _error = _describeError(error, '无法保存语气和人设');
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<void> importModel(String path) => _installModel(
    (operation, progress, installProgress) => _models.importModel(
      path,
      operation: operation,
      onProgress: progress,
      onInstallProgress: installProgress,
    ),
    name: p.basename(path),
    stage: LocalModelInstallStage.importing,
  );

  Future<void> downloadRecommendedModel([
    LocalModelDescriptor? descriptor,
  ]) async {
    if (_disposed) return;
    final mutationVersion = _modelMutationVersion;
    await initialize();
    if (!_supported ||
        busy ||
        _disposed ||
        _modelMutationVersion != mutationVersion) {
      return;
    }
    final candidate = descriptor ?? recommendedModels.first;
    for (final model in _installedModels) {
      if (candidate.matches(model) && await _models.exists(model.path)) {
        if (_disposed || _modelMutationVersion != mutationVersion || busy) {
          return;
        }
        await selectModel(model.path);
        return;
      }
    }
    if (_disposed || _modelMutationVersion != mutationVersion || busy) return;
    await _installModel(
      (operation, progress, installProgress) =>
          _models.downloadRecommendedModel(
            model: candidate,
            operation: operation,
            onProgress: progress,
            onInstallProgress: installProgress,
          ),
      name: candidate.name,
      stage: LocalModelInstallStage.connecting,
    );
  }

  Future<void> _installModel(
    Future<InstalledLocalModel> Function(
      LocalModelOperation operation,
      void Function(double?) progress,
      void Function(LocalModelInstallProgress) installProgress,
    )
    install, {
    required String name,
    required LocalModelInstallStage stage,
  }) async {
    if (_disposed) return;
    final mutationVersion = _modelMutationVersion;
    await initialize();
    if (!_supported ||
        busy ||
        _disposed ||
        _modelMutationVersion != mutationVersion) {
      return;
    }
    await _stop();
    if (!_supported ||
        busy ||
        _disposed ||
        _modelMutationVersion != mutationVersion) {
      return;
    }
    final previousSettings = _settings(path: _modelPath, name: _modelName);
    final version = ++_taskVersion;
    final operation = LocalModelOperation();
    final completion = Completer<void>();
    _installationCompletion = completion;
    _modelOperation = operation;
    _installing = true;
    _progress = 0;
    _installingModelName = name;
    _installProgress = LocalModelInstallProgress(stage: stage);
    _error = null;
    _notify();
    InstalledLocalModel? installed;
    var committed = false;
    var loadedInstalled = false;
    try {
      installed = await install(
        operation,
        (progress) {
          if (!_active(version)) return;
          _progress = progress;
          _notifyThrottled();
        },
        (progress) {
          if (_active(version)) _updateInstallProgress(progress);
        },
      );
      if (!_active(version)) return;
      operation.check();
      _updateInstallProgress(
        LocalModelInstallProgress(
          stage: LocalModelInstallStage.activating,
          receivedBytes: installed.sizeBytes,
          totalBytes: installed.sizeBytes,
        ),
      );
      if (_enabled && source == AssistantReplySource.local) {
        _loading = true;
        _notify();
        await _engine.load(installed.path);
        loadedInstalled = true;
        if (!_active(version)) return;
        _loading = false;
      }
      await _models.writeSettings(
        _settings(path: installed.path, name: installed.name),
      );
      if (!_active(version)) {
        await _models.writeSettings(previousSettings);
        return;
      }
      committed = true;
      if (_disposed) return;
      _modelPath = installed.path;
      _modelName = installed.name;
      _installedModels = await _models.listInstalledModels(
        settings: _settings(path: _modelPath, name: _modelName),
      );
    } on LocalModelCancelled {
      // User cancellation preserves the previous model.
    } catch (error) {
      if (_active(version)) {
        _error = _describeError(error, '无法安装模型，请检查存储空间后重试');
      }
    } finally {
      try {
        if (loadedInstalled) await _unload();
        if (installed != null && !committed) {
          try {
            await _models.removeModel(installed.path);
          } catch (_) {}
          try {
            _installedModels = await _models.listInstalledModels(
              settings: _settings(path: _modelPath, name: _modelName),
            );
          } catch (_) {}
        }
        if (_active(version)) {
          _modelOperation = null;
          _installing = false;
          _loading = false;
          _progress = null;
          _installProgress = null;
          _installingModelName = null;
          _notify();
        }
      } finally {
        if (identical(_installationCompletion, completion)) {
          _installationCompletion = null;
        }
        completion.complete();
      }
    }
  }

  void _updateInstallProgress(LocalModelInstallProgress progress) {
    final stageChanged = _installProgress?.stage != progress.stage;
    _installProgress = progress;
    _progress = progress.fraction;
    if (stageChanged) {
      _notify();
    } else {
      _notifyThrottled();
    }
  }

  Future<void> selectModel(String path) async {
    if (_disposed || _mutating || _installing) return;
    await initialize();
    if (_disposed || _mutating || _installing) return;
    final model = _installedModels
        .where((model) => model.path == path)
        .firstOrNull;
    if (model == null) {
      _error = '请从已安装的模型列表中选择';
      _notify();
      return;
    }
    _mutating = true;
    _loading = true;
    final previousSettings = _settings(path: _modelPath, name: _modelName);
    final mutationVersion = _modelMutationVersion;
    _installingModelName = model.name;
    _notify();
    try {
      await _stop();
      if (_disposed || _modelMutationVersion != mutationVersion) return;
      final version = ++_taskVersion;
      _loading = true;
      _installingModelName = model.name;
      _updateInstallProgress(
        const LocalModelInstallProgress(
          stage: LocalModelInstallStage.verifying,
        ),
      );
      await _models.validateModel(path);
      if (!_active(version)) return;
      if (_enabled && source == AssistantReplySource.local) {
        _updateInstallProgress(
          const LocalModelInstallProgress(
            stage: LocalModelInstallStage.activating,
          ),
        );
        await _engine.load(path);
        if (!_active(version)) return;
      }
      await _models.writeSettings(_settings(path: path, name: model.name));
      if (!_active(version)) {
        await _models.writeSettings(previousSettings);
        return;
      }
      _modelPath = path;
      _modelName = model.name;
      _error = null;
    } catch (error) {
      _error = _describeError(error, '无法切换模型，已保留原来的选择');
    } finally {
      await _unload();
      _mutating = false;
      _loading = false;
      _installProgress = null;
      _installingModelName = null;
      _progress = null;
      _notify();
    }
  }

  Future<void> removeModel() async {
    await initialize();
    final path = _modelPath;
    if (path != null) await removeInstalledModel(path);
  }

  Future<void> removeInstalledModel(String path) async {
    if (_disposed || _mutating) return;
    await initialize();
    if (_disposed || _mutating) return;
    final previousSettings = _settings(path: _modelPath, name: _modelName);
    final removingSelected = path == _modelPath;
    _mutating = true;
    _notify();
    try {
      if (removingSelected) {
        await _stop();
        if (_disposed) return;
        _loading = true;
        await _unload();
      }
      if (path == _modelPath) {
        await _models.writeSettings(
          LocalModelSettings(
            enabled: source == AssistantReplySource.online && _enabled,
            tone: _tone,
            persona: _persona,
          ),
        );
        if (source == AssistantReplySource.local) _enabled = false;
        _modelPath = null;
        _modelName = null;
      }
      await _models.removeModel(path);
      _installedModels = await _models.listInstalledModels(
        settings: _settings(path: _modelPath, name: _modelName),
      );
      _error = null;
    } catch (error) {
      if (removingSelected && await _models.exists(path)) {
        _enabled = previousSettings.enabled;
        _modelPath = previousSettings.path;
        _modelName = previousSettings.name;
        try {
          await _models.writeSettings(previousSettings);
        } catch (_) {}
      }
      _error = _describeError(error, '无法移除模型');
    } finally {
      _mutating = false;
      _loading = false;
      _notify();
      _scheduleDrain();
    }
  }

  /// Called only after a newly written diary entry has been saved successfully.
  /// The delay lets keyboard, entry insertion, and sync settle before inference.
  void scheduleReply(
    String entryId,
    String text, {
    List<String> imagePaths = const [],
  }) {
    if (_disposed) return;
    if (_replyingEntryId == entryId) {
      unawaited(updateEntryReply(entryId, text, imagePaths: imagePaths));
      return;
    }
    if (!_initialized) {
      final version = _queueVersion;
      unawaited(
        initialize().then((_) {
          if (!_disposed && _queueVersion == version) {
            _enqueue(entryId, text, imagePaths: imagePaths);
          }
        }),
      );
      return;
    }
    _enqueue(entryId, text, imagePaths: imagePaths);
  }

  Future<void> replyToEntry(
    String entryId,
    String text, {
    List<String> imagePaths = const [],
  }) async {
    if (_disposed) return;
    final version = _queueVersion;
    await initialize();
    if (_disposed || _queueVersion != version) return;
    final request = _enqueue(entryId, text, imagePaths: imagePaths);
    if (request != null) await request.completion.future;
  }

  /// An edited entry must never keep a response generated from its old text.
  /// Per-entry revisions also coalesce edits while cancellation/storage awaits.
  Future<void> updateEntryReply(
    String entryId,
    String text, {
    bool Function()? isCurrent,
    List<String> imagePaths = const [],
  }) async {
    if (_disposed || (isCurrent != null && !isCurrent())) return;
    final revision = (_entryRevisions[entryId] ?? 0) + 1;
    _entryRevisions[entryId] = revision;
    final queueVersion = _queueVersion;
    await _forgetReply(entryId, invalidateUpdate: false);
    if (_disposed ||
        _queueVersion != queueVersion ||
        _entryRevisions[entryId] != revision ||
        (text.trim().isEmpty && !_canSendImages(imagePaths)) ||
        (isCurrent != null && !isCurrent())) {
      return;
    }
    scheduleReply(entryId, text, imagePaths: imagePaths);
  }

  bool _canSendImages(List<String> paths) =>
      source == AssistantReplySource.online &&
      onlineConfiguration.sendImages &&
      paths.isNotEmpty;

  _ReplyRequest? _enqueue(
    String entryId,
    String text, {
    List<String> imagePaths = const [],
  }) {
    final input = text.trim();
    if (!_canReply ||
        _mutating ||
        _installing ||
        entryId.trim().isEmpty ||
        (input.isEmpty && !_canSendImages(imagePaths)) ||
        _replyingEntryId == entryId) {
      return null;
    }
    _forgottenEntryIds.remove(entryId);
    for (final old
        in _queue.where((request) => request.entryId == entryId).toList()) {
      _queue.remove(old);
      old.complete();
    }
    // Bound the transient prompt before placing it in the queue. It is never
    // copied to preferences, conversation storage, diary records, or sync.
    var start = input.length > 1200 ? input.length - 1200 : 0;
    if (start > 0 &&
        input.codeUnitAt(start) >= 0xdc00 &&
        input.codeUnitAt(start) <= 0xdfff) {
      start++;
    }
    final request = _ReplyRequest(
      entryId,
      input.substring(start),
      _canSendImages(imagePaths)
          ? List.unmodifiable(imagePaths.take(4))
          : const [],
    );
    _queue.add(request);
    while (_queue.length > maxPendingReplies) {
      _queue.removeAt(0).complete();
    }
    _nextReplyAt = DateTime.now().add(_replyDelay);
    _scheduleDrain();
    return request;
  }

  bool get _canReply =>
      !_disposed &&
      !_stopping &&
      !_testingConnection &&
      supported &&
      _enabled &&
      canUseSelectedModel;

  bool get _canStartNow {
    if (source == AssistantReplySource.online) return true;
    try {
      return _canStart();
    } catch (_) {
      return false;
    }
  }

  void _scheduleDrain({Duration? retryDelay}) {
    if (!_canReply || _queue.isEmpty || _mutating || _installing) return;
    _replyTimer?.cancel();
    final remaining = (_nextReplyAt ?? DateTime.now()).difference(
      DateTime.now(),
    );
    _replyTimer = Timer(
      retryDelay ?? (remaining.isNegative ? Duration.zero : remaining),
      () {
        _replyTimer = null;
        unawaited(_drainQueue());
      },
    );
  }

  Future<void> _drainQueue() async {
    if (_draining || !_canReply || _mutating || _installing || _queue.isEmpty) {
      return;
    }
    if (!_canStartNow) {
      _scheduleDrain(retryDelay: const Duration(milliseconds: 300));
      return;
    }
    final remaining = (_nextReplyAt ?? DateTime.now()).difference(
      DateTime.now(),
    );
    if (!remaining.isNegative && remaining != Duration.zero) {
      _scheduleDrain();
      return;
    }
    _draining = true;
    final completion = Completer<void>();
    _drainCompletion = completion;
    try {
      while (_canReply &&
          _canStartNow &&
          !_mutating &&
          !_installing &&
          _queue.isNotEmpty) {
        final remaining = (_nextReplyAt ?? DateTime.now()).difference(
          DateTime.now(),
        );
        if (!remaining.isNegative && remaining != Duration.zero) break;
        final request = _queue.removeAt(0);
        await _runReply(request);
      }
    } finally {
      // Entry responses are one-shot: keep native RAM only during a reply burst.
      await _unload();
      _draining = false;
      if (identical(_drainCompletion, completion)) _drainCompletion = null;
      completion.complete();
      _notify();
      _scheduleDrain(
        retryDelay: _canStartNow ? null : const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _runReply(_ReplyRequest request) async {
    final version = ++_taskVersion;
    _activeRequest = request;
    _replyingEntryId = request.entryId;
    _replyUpdated = false;
    _replyErrors.remove(request.entryId);
    _loading = true;
    _error = null;
    _notify();
    try {
      if (_replyStrategy == null) {
        if (source == AssistantReplySource.local) {
          _replyStrategy = LocalDiaryReplyStrategy(
            engine: _engine,
            modelPath: _modelPath!,
          );
        } else {
          final configuration = onlineConfiguration;
          final key = await _providers.readApiKey(configuration.provider);
          if (!_active(version)) return;
          if (key?.trim().isNotEmpty != true) {
            throw const OnlineModelException('API Key 已不可用，请重新保存');
          }
          _replyStrategy = _onlineStrategyFactory(configuration, key!);
        }
        await _replyStrategy!.prepare();
        if (!_active(version)) return;
      }
      if (!_active(version) || _forgottenEntryIds.contains(request.entryId)) {
        return;
      }
      final prompt = LocalAssistantMessage(
        id: request.entryId,
        role: LocalAssistantRole.user,
        text: request.text,
        createdAt: DateTime.now(),
        imagePaths: request.imagePaths,
      );
      final completion = Completer<void>();
      _generationCompletion = completion;
      _loading = false;
      _generating = true;
      _notify();
      _generationSubscription = _replyStrategy!
          .generate([prompt], tone: _tone, persona: _persona)
          .listen(
            (response) {
              if (!_active(version) ||
                  !_generating ||
                  _forgottenEntryIds.contains(request.entryId)) {
                return;
              }
              _setReply(request.entryId, response);
              _replyUpdated = true;
              _notifyThrottled();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (_active(version)) {
                _error = _describeError(error, '生成回应失败');
                _replyErrors[request.entryId] = _error!;
                unawaited(_settleGeneration());
              }
            },
            onDone: () {
              if (_active(version)) unawaited(_settleGeneration());
            },
            cancelOnError: true,
          );
      await completion.future;
    } catch (error) {
      if (_active(version)) {
        _error = _describeError(error, '无法运行当前模型');
        _replyErrors[request.entryId] = _error!;
        await _settleGeneration();
      }
    } finally {
      if (_replyingEntryId == request.entryId) {
        _replyingEntryId = null;
        _loading = false;
      }
      request.complete();
      if (identical(_activeRequest, request)) _activeRequest = null;
      _notify();
    }
  }

  void _setReply(String entryId, String text) {
    final retained = _messages
        .where((message) => message.id != entryId)
        .toList();
    if (text.trim().isNotEmpty) {
      retained.add(
        LocalAssistantMessage(
          id: entryId,
          role: LocalAssistantRole.assistant,
          text: text.length > 16000 ? text.substring(0, 16000) : text,
          createdAt: DateTime.now(),
        ),
      );
    }
    _messages = List.unmodifiable(
      retained.length > LocalAssistantStore.maxMessages
          ? retained.sublist(retained.length - LocalAssistantStore.maxMessages)
          : retained,
    );
  }

  Future<void> _settleGeneration({bool persist = true}) async {
    final completion = _generationCompletion;
    if (completion == null) return;
    final version = _taskVersion;
    final updated = _replyUpdated;
    _generationCompletion = null;
    _generationSubscription = null;
    _generating = false;
    _loading = false;
    _replyUpdated = false;
    _notify();
    try {
      if (persist && updated) await _store.save(_messages);
    } catch (error) {
      if (_active(version)) {
        _error = _describeError(error, '无法保存本地回应');
        _notify();
      }
    } finally {
      if (!completion.isCompleted) completion.complete();
    }
  }

  Future<void> stop() {
    if (_disposed) return Future<void>.value();
    // An external stop must invalidate an enable/select/import that is still
    // joining an earlier stop, before that operation assigns its task version.
    ++_modelMutationVersion;
    ++_taskVersion;
    ++_queueVersion;
    return _stop();
  }

  Future<void> _stop() async {
    if (_disposed) return;
    final previousStop = _stopCompletion;
    if (previousStop != null) {
      await previousStop.future;
      return;
    }
    final completion = Completer<void>();
    _stopCompletion = completion;
    _stopping = true;
    ++_queueVersion;
    ++_taskVersion;
    _cancelQueuedReplies();
    _modelOperation?.cancel();
    _modelOperation = null;
    final installation = _installationCompletion;
    final drain = _drainCompletion;
    final subscription = _generationSubscription;
    try {
      await _connectionStrategy?.cancel();
      await _replyStrategy?.cancel();
      await _engine.cancel();
    } catch (_) {}
    try {
      await subscription?.cancel();
    } catch (_) {}
    await _settleGeneration();
    await installation?.future;
    await drain?.future;
    _loading = false;
    _installing = false;
    _progress = null;
    _installProgress = null;
    _installingModelName = null;
    _replyingEntryId = null;
    _replyErrors.clear();
    _stopping = false;
    _stopCompletion = null;
    completion.complete();
    _notify();
  }

  void _cancelQueuedReplies() {
    _replyTimer?.cancel();
    _replyTimer = null;
    _nextReplyAt = null;
    for (final request in _queue) {
      request.complete();
    }
    _queue.clear();
  }

  Future<void> forgetReply(String entryId) => _forgetReply(entryId);

  Future<void> _forgetReply(
    String entryId, {
    bool invalidateUpdate = true,
  }) async {
    if (_disposed) return;
    if (invalidateUpdate) {
      _entryRevisions[entryId] = (_entryRevisions[entryId] ?? 0) + 1;
    }
    await initialize();
    if (_disposed) return;
    _forgottenEntryIds.add(entryId);
    _replyErrors.remove(entryId);
    for (final request
        in _queue.where((request) => request.entryId == entryId).toList()) {
      _queue.remove(request);
      request.complete();
    }
    final removed = _messages.any((message) => message.id == entryId);
    _messages = List.unmodifiable(
      _messages.where((message) => message.id != entryId),
    );
    _notify();
    if (_replyingEntryId == entryId) {
      final activeRequest = _activeRequest;
      ++_taskVersion;
      final subscription = _generationSubscription;
      try {
        await _replyStrategy?.cancel();
        await _engine.cancel();
      } catch (_) {}
      await subscription?.cancel();
      await _settleGeneration(persist: false);
      // Wait for this entry only. Other queued entries are neither cleared nor
      // awaited, so a new edit can enqueue after the old native call settles.
      await activeRequest?.completion.future;
    }
    if (removed) {
      try {
        await _store.save(_messages);
      } catch (error) {
        if (!_disposed) {
          _error = _describeError(error, '无法删除本地回应');
          _notify();
        }
      }
    }
  }

  Future<void> clearConversation() async {
    if (_disposed || _mutating) return;
    await initialize();
    if (_disposed || _mutating) return;
    _mutating = true;
    _notify();
    try {
      await _stop();
      if (_disposed) return;
      _messages = const [];
      _forgottenEntryIds.clear();
      _replyErrors.clear();
      _error = null;
      await _store.save(_messages);
    } catch (error) {
      _error = _describeError(error, '无法清空本地回应');
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<void> suspend() async {
    if (_disposed) return;
    await stop();
    await _unload();
  }

  Future<void> _unload() async {
    final strategy = _replyStrategy;
    _replyStrategy = null;
    try {
      if (strategy != null) {
        await strategy.dispose();
      } else {
        await _engine.unload();
      }
    } catch (error) {
      if (!_disposed) _error = _describeError(error, '无法释放模型资源');
    }
  }

  LocalModelSettings _settings({String? path, String? name}) =>
      LocalModelSettings(
        enabled: _enabled,
        path: path,
        name: name,
        tone: _tone,
        persona: _persona,
      );

  Future<void> _saveSettings() =>
      _models.writeSettings(_settings(path: _modelPath, name: _modelName));

  bool _active(int version) => !_disposed && _taskVersion == version;

  void _notifyThrottled() {
    if (_disposed || _notificationTimer != null) return;
    _notificationTimer = Timer(const Duration(milliseconds: 80), () {
      _notificationTimer = null;
      if (!_disposed) notifyListeners();
    });
  }

  void _notify() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    if (!_disposed) notifyListeners();
  }

  String _describeError(Object error, String fallback) {
    if (error is OnlineModelException) return error.message;
    if (error is FormatException && error.message.isNotEmpty) {
      return error.message;
    }
    if (error is TimeoutException) return '操作超时，请检查网络后重试';
    return fallback;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_queueVersion;
    ++_taskVersion;
    _notificationTimer?.cancel();
    _cancelQueuedReplies();
    _modelOperation?.cancel();
    final subscription = _generationSubscription;
    final completion = _generationCompletion;
    final updated = _replyUpdated;
    _generationCompletion = null;
    final retained = _messages;
    unawaited(() async {
      try {
        await _connectionStrategy?.cancel();
        await _replyStrategy?.cancel();
        await _engine.cancel();
        await subscription?.cancel();
        if (updated) await _store.save(retained);
      } catch (_) {
      } finally {
        if (completion != null && !completion.isCompleted) {
          completion.complete();
        }
        try {
          await _connectionStrategy?.dispose();
          await _replyStrategy?.dispose();
          await _engine.dispose();
        } catch (_) {}
      }
    }());
    super.dispose();
  }
}

class _ReplyRequest {
  _ReplyRequest(this.entryId, this.text, this.imagePaths);
  final String entryId;
  final String text;
  final List<String> imagePaths;
  final Completer<void> completion = Completer<void>();

  void complete() {
    if (!completion.isCompleted) completion.complete();
  }
}
