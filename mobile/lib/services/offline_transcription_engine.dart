import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../data/speech_model_store.dart';

abstract interface class TranscriptionEngine {
  bool get supported;
  Future<bool> checkSupported();
  Future<String> transcribe(
    String audioPath, {
    required SpeechModelFiles model,
    void Function(double)? onProgress,
  });
  Future<void> cancel();
  Future<void> dispose();
}

class TranscriptionException implements Exception {
  const TranscriptionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TranscriptionCancelled implements Exception {
  const TranscriptionCancelled();
}

/// Model loading, PCM parsing and synchronous ONNX calls run in a worker.
/// Only local file paths, progress and the final text cross the isolate boundary.
class SherpaOfflineTranscriptionEngine implements TranscriptionEngine {
  SherpaOfflineTranscriptionEngine({
    MethodChannel channel = const MethodChannel(
      'com.ling.diary/offline_transcription',
    ),
    this.timeout = const Duration(minutes: 5),
    this.nativeLibraryDirectory,
    Abi? abi,
  }) : _channel = channel,
       _abi = abi ?? Abi.current();

  static const maxAudioBytes = 50 * 1024 * 1024;
  static const maxDurationSeconds = 180;
  final MethodChannel _channel;
  final Duration timeout;
  final String? nativeLibraryDirectory;
  final Abi _abi;
  bool _androidSupported = false;
  Future<bool>? _capabilityCheck;
  _TranscriptionOperation? _active;
  bool _disposed = false;

  @override
  bool get supported =>
      !_disposed &&
      (_abi == Abi.windowsX64 ||
          (_abi == Abi.androidArm64 && _androidSupported));

  @override
  Future<bool> checkSupported() {
    if (_disposed) return Future.value(false);
    if (_abi == Abi.windowsX64) return Future.value(true);
    if (_abi != Abi.androidArm64) return Future.value(false);
    return _capabilityCheck ??= _checkAndroidCapabilities();
  }

  Future<bool> _checkAndroidCapabilities() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getCapabilities')
          .timeout(const Duration(seconds: 3));
      final sdk = result?['sdkInt'];
      _androidSupported =
          !_disposed && result?['supported'] == true && sdk is int && sdk >= 27;
    } catch (_) {
      // An unavailable platform channel must not enable downloads/inference.
      _androidSupported = false;
    }
    return _androidSupported;
  }

  @override
  Future<String> transcribe(
    String audioPath, {
    required SpeechModelFiles model,
    void Function(double)? onProgress,
  }) async {
    if (_disposed) throw const TranscriptionException('录音转写已经关闭。');
    if (_active != null) throw const TranscriptionException('另一条录音正在转写，请稍候。');
    final operation = _TranscriptionOperation();
    _active = operation;
    String? temporaryPcm;
    ReceivePort? messages;
    ReceivePort? exit;
    ReceivePort? errors;
    StreamSubscription<dynamic>? messageSubscription;
    StreamSubscription<dynamic>? exitSubscription;
    StreamSubscription<dynamic>? errorSubscription;
    Timer? deadline;
    try {
      deadline = Timer(timeout, () {
        operation.timedOut = true;
        unawaited(cancel());
      });
      final deviceSupported = await _wait(operation, checkSupported());
      operation.check();
      if (!deviceSupported) {
        throw const TranscriptionException(
          '离线录音转写需要 Android 8.1 或更新版本的 64 位 ARM 设备，或 64 位 Windows。',
        );
      }
      final audio = File(audioPath);
      if (!await audio.exists()) {
        throw const TranscriptionException('录音文件不存在或已经删除。');
      }
      final bytes = await audio.length();
      if (bytes <= 0 || bytes > maxAudioBytes) {
        throw const TranscriptionException('录音文件为空或超过 50 MB，无法转写。');
      }
      if (!await File(model.modelPath).exists() ||
          !await File(model.tokensPath).exists()) {
        throw const TranscriptionException('请先在设置中下载离线语音模型。');
      }
      operation.check();
      onProgress?.call(0);
      final headerFile = await audio.open();
      late final Uint8List header;
      try {
        header = await headerFile.read(12);
      } finally {
        await headerFile.close();
      }
      final wave =
          header.length >= 12 &&
          _tag(header, 0) == 'RIFF' &&
          _tag(header, 8) == 'WAVE';
      var inputPath = audioPath;
      if (!wave) {
        if (!Platform.isAndroid) {
          throw const TranscriptionException(
            'Windows 目前支持 WAV 录音转写；AAC/m4a 请在 Android 上转写。',
          );
        }
        operation.androidDecode = true;
        final decoded = await _wait(
          operation,
          _channel
              .invokeMapMethod<String, dynamic>('decodeToPcm16', {
                'audioPath': audioPath,
                'requestId': operation.id,
              })
              .then((value) async {
                if (operation.cancelled && value?['pcmPath'] is String) {
                  await _releasePcm(value!['pcmPath'] as String);
                }
                return value;
              }),
        );
        operation.androidDecode = false;
        if (decoded?['pcmPath'] is! String || decoded?['sampleRate'] != 16000) {
          throw const TranscriptionException('无法读取录音，请检查录音格式。');
        }
        temporaryPcm = decoded!['pcmPath'] as String;
        inputPath = temporaryPcm;
      }
      operation.check();
      onProgress?.call(0.15);
      messages = ReceivePort();
      exit = ReceivePort();
      errors = ReceivePort();
      final finished = Completer<String>();
      messageSubscription = messages.listen((event) {
        if (event is! List || event.isEmpty) return;
        if (event[0] == 'control' &&
            event.length == 2 &&
            event[1] is SendPort) {
          operation.control = event[1] as SendPort;
          if (operation.cancelled) operation.control?.send('cancel');
        } else if (event[0] == 'progress' &&
            event.length == 2 &&
            event[1] is num) {
          if (!operation.cancelled) {
            onProgress?.call(
              0.15 + (event[1] as num).toDouble().clamp(0, 1) * 0.85,
            );
          }
        } else if (event[0] == 'result' &&
            event.length == 2 &&
            event[1] is String) {
          if (!finished.isCompleted) finished.complete(event[1] as String);
        } else if (event[0] == 'error' &&
            event.length == 2 &&
            event[1] is String) {
          if (!finished.isCompleted) {
            finished.completeError(TranscriptionException(event[1] as String));
          }
        } else if (event[0] == 'cancelled') {
          if (!finished.isCompleted) {
            finished.completeError(const TranscriptionCancelled());
          }
        }
      });
      errorSubscription = errors.listen((_) {
        if (!finished.isCompleted) {
          finished.completeError(
            const TranscriptionException('离线语音引擎无法运行，请检查设备或重新下载模型。'),
          );
        }
      });
      exitSubscription = exit.listen((_) {
        if (!operation.workerExited.isCompleted) {
          operation.workerExited.complete();
        }
        // Worker results are sent before exit; allow queued result delivery.
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          if (!finished.isCompleted) {
            finished.completeError(
              const TranscriptionException('离线语音引擎提前停止，请重新转写。'),
            );
          }
        });
      });
      operation.worker = await Isolate.spawn<List<Object>>(
        _transcribeWorker,
        [
          messages.sendPort,
          inputPath,
          model.modelPath,
          model.tokensPath,
          !wave,
          nativeLibraryDirectory ?? '',
        ],
        onExit: exit.sendPort,
        onError: errors.sendPort,
        errorsAreFatal: true,
        debugName: 'diary-offline-transcription',
      );
      if (operation.cancelled) operation.control?.send('cancel');
      final text = await _wait(operation, finished.future);
      operation.check();
      if (text.trim().isEmpty) {
        throw const TranscriptionException('这段录音没有识别到清晰语音，可以重新转写。');
      }
      onProgress?.call(1);
      return text.trim();
    } on TranscriptionCancelled {
      rethrow;
    } on TranscriptionException {
      rethrow;
    } on PlatformException catch (error) {
      operation.check();
      throw TranscriptionException(switch (error.code) {
        'AUDIO_TOO_LONG' => '录音超过 3 分钟，请使用较短的录音转写。',
        'AUDIO_TOO_LARGE' => '录音文件超过 50 MB，无法转写。',
        'AUDIO_CANCELLED' => '录音转写已取消。',
        _ => '无法读取录音，请检查录音格式或重新录制。',
      });
    } catch (_) {
      operation.check();
      throw const TranscriptionException('录音转写失败，请检查录音文件或重新下载语音模型。');
    } finally {
      deadline?.cancel();
      operation.control?.send('cancel');
      if (operation.worker != null && !operation.workerExited.isCompleted) {
        // Cancellation is cooperative between bounded decode segments. Killing
        // a native FFI call would skip its free() and leak the model allocation.
        await operation.workerExited.future;
      }
      await messageSubscription?.cancel();
      await exitSubscription?.cancel();
      await errorSubscription?.cancel();
      messages?.close();
      exit?.close();
      errors?.close();
      if (temporaryPcm != null) await _releasePcm(temporaryPcm);
      if (identical(_active, operation)) _active = null;
      if (!operation.done.isCompleted) operation.done.complete();
    }
  }

  Future<T> _wait<T>(_TranscriptionOperation operation, Future<T> future) =>
      Future.any<T>([
        future,
        operation.signal.future.then<T>((_) {
          operation.check();
          throw const TranscriptionCancelled();
        }),
      ]);

  Future<void> _releasePcm(String path) async {
    try {
      await _channel.invokeMethod<void>('releaseDecodedAudio', path);
    } catch (_) {
      // Native output stays in application cache and is cleaned on later decode.
    }
  }

  @override
  Future<void> cancel() async {
    final operation = _active;
    if (operation == null) return;
    await operation.cancel();
    if (operation.androidDecode) {
      try {
        await _channel.invokeMethod<void>('cancelDecode', operation.id);
      } catch (_) {
        // Completion is still guarded by the cancelled operation.
      }
    }
    await operation.done.future;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await cancel();
  }
}

class _TranscriptionOperation {
  final id = 'speech-${DateTime.now().microsecondsSinceEpoch}';
  final signal = Completer<void>();
  final done = Completer<void>();
  final workerExited = Completer<void>();
  Isolate? worker;
  SendPort? control;
  bool cancelled = false;
  bool timedOut = false;
  bool androidDecode = false;

  Future<void> cancel() async {
    if (cancelled) return;
    cancelled = true;
    signal.complete();
    control?.send('cancel');
  }

  void check() {
    if (timedOut) throw const TranscriptionException('录音转写超时，请稍后重试。');
    if (cancelled) throw const TranscriptionCancelled();
  }
}

@pragma('vm:entry-point')
Future<void> _transcribeWorker(List<Object> arguments) async {
  final reply = arguments[0] as SendPort;
  final controls = ReceivePort();
  var cancelled = false;
  final subscription = controls.listen((event) {
    if (event == 'cancel') cancelled = true;
  });
  reply.send(['control', controls.sendPort]);
  sherpa.OfflineRecognizer? recognizer;
  try {
    final source = File(arguments[1] as String);
    final length = source.lengthSync();
    if (length <= 0 ||
        length > SherpaOfflineTranscriptionEngine.maxAudioBytes) {
      throw const TranscriptionException('录音文件为空或超过 50 MB，无法转写。');
    }
    final handle = source.openSync();
    late final Uint8List bytes;
    try {
      bytes = handle.readSync(length + 1);
    } finally {
      handle.closeSync();
    }
    if (bytes.length != length) {
      throw const TranscriptionException('录音文件不完整或内容已变化，请重新转写。');
    }
    final audio = arguments[4] == true
        ? _decodePcm16(bytes)
        : decodePcmWave(bytes);
    if (cancelled) throw const TranscriptionCancelled();
    if (File(arguments[2] as String).lengthSync() > 300 * 1024 * 1024 ||
        File(arguments[3] as String).lengthSync() > 2 * 1024 * 1024) {
      throw const TranscriptionException('语音模型文件不正确，请重新下载。');
    }
    var libraryDirectory = arguments[5] as String;
    if (Platform.isWindows) {
      // Windows resolves transitive DLLs using the process search order. An
      // absolute c-api path alone can load another app's incompatible ORT.
      // Preload the runtime shipped alongside our executable before Sherpa.
      libraryDirectory = libraryDirectory.isEmpty
          ? File(Platform.resolvedExecutable).parent.absolute.path
          : Directory(libraryDirectory).absolute.path;
      final runtime = File(p.join(libraryDirectory, 'onnxruntime.dll'));
      final bindings = File(p.join(libraryDirectory, 'sherpa-onnx-c-api.dll'));
      if (!runtime.existsSync() || !bindings.existsSync()) {
        throw const TranscriptionException('语音运行库缺失，请重新安装完整应用。');
      }
      DynamicLibrary.open(runtime.path);
    }
    await sherpa.initBindingsAsync(
      libraryDirectory.isEmpty ? null : libraryDirectory,
    );
    if (cancelled) throw const TranscriptionCancelled();
    recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        feat: const sherpa.FeatureConfig(sampleRate: 16000),
        model: sherpa.OfflineModelConfig(
          senseVoice: sherpa.OfflineSenseVoiceModelConfig(
            model: arguments[2] as String,
            language: 'auto',
            useInverseTextNormalization: true,
          ),
          tokens: arguments[3] as String,
          numThreads: math.max(1, math.min(2, Platform.numberOfProcessors - 1)),
          debug: false,
          provider: 'cpu',
        ),
      ),
    );
    final segments = splitSpeechSegments(
      audio.samples,
      sampleRate: audio.sampleRate,
    );
    final text = <String>[];
    for (var index = 0; index < segments.length; index++) {
      await Future<void>.delayed(Duration.zero);
      if (cancelled) throw const TranscriptionCancelled();
      final stream = recognizer.createStream();
      try {
        stream.acceptWaveform(
          samples: segments[index],
          sampleRate: audio.sampleRate,
        );
        recognizer.decode(stream);
        final result = recognizer
            .getResult(stream)
            .text
            .replaceAll(RegExp(r'<\|[^>]{1,64}\|>'), '')
            .trim();
        if (result.isNotEmpty) text.add(result);
      } finally {
        stream.free();
      }
      reply.send(['progress', (index + 1) / segments.length]);
    }
    await Future<void>.delayed(Duration.zero);
    if (cancelled) throw const TranscriptionCancelled();
    reply.send(['result', text.join(' ')]);
  } on TranscriptionCancelled {
    reply.send(['cancelled']);
  } on TranscriptionException catch (error) {
    reply.send(['error', error.message]);
  } catch (_) {
    reply.send(['error', '离线语音引擎无法读取录音或模型，请检查文件后重试。']);
  } finally {
    recognizer?.free();
    await subscription.cancel();
    controls.close();
  }
}

class PcmAudioData {
  const PcmAudioData({required this.samples, required this.sampleRate});
  final Float32List samples;
  final int sampleRate;
}

/// Bounded WAV parsing keeps malformed headers away from native allocations.
/// PCM 8/16/24/32-bit and IEEE float32 WAV, with 1–8 channels, are accepted.
PcmAudioData decodePcmWave(Uint8List bytes) {
  if (bytes.length < 44 ||
      bytes.length > SherpaOfflineTranscriptionEngine.maxAudioBytes ||
      _tag(bytes, 0) != 'RIFF' ||
      _tag(bytes, 8) != 'WAVE') {
    throw const TranscriptionException('WAV 录音格式不正确或超过 50 MB。');
  }
  final view = ByteData.sublistView(bytes);
  final declaredEnd = view.getUint32(4, Endian.little) + 8;
  if (declaredEnd > bytes.length || declaredEnd < 44) {
    throw const TranscriptionException('WAV 录音不完整，无法转写。');
  }
  int? encoding;
  int? channels;
  int? rate;
  int? bits;
  int? dataOffset;
  int? dataLength;
  for (var offset = 12; offset + 8 <= declaredEnd;) {
    final length = view.getUint32(offset + 4, Endian.little);
    final end = offset + 8 + length;
    if (end > declaredEnd) {
      throw const TranscriptionException('WAV 录音不完整，无法转写。');
    }
    final name = _tag(bytes, offset);
    if (name == 'fmt ' && length >= 16) {
      encoding = view.getUint16(offset + 8, Endian.little);
      channels = view.getUint16(offset + 10, Endian.little);
      rate = view.getUint32(offset + 12, Endian.little);
      bits = view.getUint16(offset + 22, Endian.little);
    } else if (name == 'data' && dataOffset == null) {
      dataOffset = offset + 8;
      dataLength = length;
    }
    offset = end + (length & 1);
  }
  if (encoding == null ||
      channels == null ||
      channels < 1 ||
      channels > 8 ||
      rate == null ||
      rate < 8000 ||
      rate > 96000 ||
      bits == null ||
      (encoding != 1 && encoding != 3) ||
      (encoding == 1 && !const {8, 16, 24, 32}.contains(bits)) ||
      (encoding == 3 && bits != 32) ||
      dataOffset == null ||
      dataLength == null) {
    throw const TranscriptionException('暂不支持这段 WAV 录音的编码，请使用 PCM WAV。');
  }
  final frameBytes = (bits ~/ 8) * channels;
  if (dataLength == 0 || dataLength % frameBytes != 0) {
    throw const TranscriptionException('WAV 录音没有有效音频或数据不完整。');
  }
  final frames = dataLength ~/ frameBytes;
  if (frames > rate * SherpaOfflineTranscriptionEngine.maxDurationSeconds) {
    throw const TranscriptionException('录音超过 3 分钟，请使用较短的录音转写。');
  }
  final samples = Float32List(frames);
  for (var frame = 0; frame < frames; frame++) {
    var sum = 0.0;
    for (var channel = 0; channel < channels; channel++) {
      final offset = dataOffset + frame * frameBytes + channel * (bits ~/ 8);
      final sample = switch ((encoding, bits)) {
        (3, 32) => view.getFloat32(offset, Endian.little),
        (1, 8) => (view.getUint8(offset) - 128) / 128,
        (1, 16) => view.getInt16(offset, Endian.little) / 32768,
        (1, 24) => _int24(view, offset) / 8388608,
        _ => view.getInt32(offset, Endian.little) / 2147483648,
      };
      sum += sample.isFinite ? sample.clamp(-1, 1) : 0;
    }
    samples[frame] = sum / channels;
  }
  return PcmAudioData(samples: samples, sampleRate: rate);
}

PcmAudioData _decodePcm16(Uint8List bytes) {
  if (bytes.isEmpty ||
      bytes.length.isOdd ||
      bytes.length >
          16000 * 2 * SherpaOfflineTranscriptionEngine.maxDurationSeconds) {
    throw const TranscriptionException('录音超过 3 分钟或音频数据不完整，无法转写。');
  }
  final view = ByteData.sublistView(bytes);
  final samples = Float32List(bytes.length ~/ 2);
  for (var index = 0; index < samples.length; index++) {
    samples[index] = view.getInt16(index * 2, Endian.little) / 32768;
  }
  return PcmAudioData(samples: samples, sampleRate: 16000);
}

int _int24(ByteData view, int offset) {
  final value =
      view.getUint8(offset) |
      (view.getUint8(offset + 1) << 8) |
      (view.getUint8(offset + 2) << 16);
  return (value & 0x800000) == 0 ? value : value - 0x1000000;
}

String _tag(Uint8List bytes, int offset) =>
    String.fromCharCodes(bytes.sublist(offset, offset + 4));

/// Split long recordings near a quiet boundary to bound each native call.
/// Every sample is retained; clips longer than the supported limit are errors.
List<Float32List> splitSpeechSegments(
  Float32List samples, {
  required int sampleRate,
}) {
  if (sampleRate <= 0 ||
      samples.isEmpty ||
      samples.length >
          sampleRate * SherpaOfflineTranscriptionEngine.maxDurationSeconds) {
    throw const TranscriptionException('录音为空或超过 3 分钟，无法转写。');
  }
  final segments = <Float32List>[];
  var start = 0;
  while (start < samples.length) {
    final maximumEnd = math.min(samples.length, start + 20 * sampleRate);
    var end = maximumEnd;
    if (end < samples.length) {
      var quietest = double.infinity;
      final window = math.max(1, sampleRate ~/ 4);
      for (
        var candidate = start + 12 * sampleRate;
        candidate + window <= maximumEnd;
        candidate += window
      ) {
        var energy = 0.0;
        for (var index = candidate; index < candidate + window; index++) {
          energy += samples[index] * samples[index];
        }
        if (energy <= quietest) {
          quietest = energy;
          end = candidate + window;
        }
      }
    }
    segments.add(Float32List.sublistView(samples, start, end));
    start = end;
  }
  return segments;
}
