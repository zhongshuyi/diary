import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/speech_model_store.dart';
import '../services/offline_transcription_engine.dart';

enum AudioTranscriptionStage {
  queued,
  transcribing,
  completed,
  failed,
  cancelled,
}

class AudioTranscriptionState {
  const AudioTranscriptionState({
    required this.stage,
    this.text,
    this.progress,
    this.error,
  });

  final AudioTranscriptionStage stage;
  final String? text;
  final double? progress;
  final String? error;

  bool get active =>
      stage == AudioTranscriptionStage.queued ||
      stage == AudioTranscriptionStage.transcribing;
}

typedef AudioTranscriptGuard =
    FutureOr<bool> Function(String entryId, String audioPath);
typedef AudioTranscriptCompleted =
    Future<void> Function(String entryId, String audioPath, String text);

/// Runs one offline transcription at a time, independently from saving a diary.
/// The host checks the live entry before persisting its separate transcript.
class TranscriptionController extends ChangeNotifier {
  TranscriptionController({
    SpeechModelStore? models,
    TranscriptionEngine? engine,
    AudioTranscriptGuard? isCurrent,
    AudioTranscriptCompleted? onCompleted,
    bool Function()? canStart,
    Duration queueDelay = const Duration(milliseconds: 1200),
  }) : _models = models ?? SpeechModelStore(),
       _engine = engine ?? SherpaOfflineTranscriptionEngine(),
       _isCurrent = isCurrent ?? ((_, _) => true),
       _onCompleted = onCompleted ?? ((_, _, _) async {}),
       _canStart = canStart ?? (() => true),
       _queueDelay = queueDelay;

  static const _maximumQueued = 32;
  final SpeechModelStore _models;
  final TranscriptionEngine _engine;
  final AudioTranscriptGuard _isCurrent;
  final AudioTranscriptCompleted _onCompleted;
  final bool Function() _canStart;
  final Duration _queueDelay;
  final _queue = Queue<_AudioTask>();
  final _states = <_AudioId, AudioTranscriptionState>{};
  final _versions = <_AudioId, int>{};
  final _entryVersions = <String, int>{};
  int _stopEpoch = 0;
  Future<void>? _initialization;
  Future<void>? _drainCompletion;
  Future<void>? _stopCompletion;
  Timer? _timer;
  Timer? _interactionTimer;
  bool _interactionDeferred = false;
  bool _deferred = false;
  SpeechModelFiles? _model;
  _AudioTask? _current;
  bool _initialized = false;
  bool _autoTranscribe = false;
  bool _downloading = false;
  bool _downloadCancelled = false;
  bool _changingSettings = false;
  bool _disposed = false;
  double? _downloadProgress;
  String? _error;

  bool get initialized => _initialized;
  bool get supported => _engine.supported;
  bool get hasModel => _model != null;
  bool get autoTranscribe => _autoTranscribe;
  bool get downloading => _downloading;
  double? get downloadProgress => _downloadProgress;
  String? get error => _error;
  bool get transcribing => _current != null;
  bool get busy => _downloading || _changingSettings || _stopCompletion != null;
  int get queuedCount => _queue.length;

  AudioTranscriptionState? stateFor(String entryId, String audioPath) =>
      _states[_AudioId(entryId, audioPath)];

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      await _engine.checkSupported();
      if (_disposed) return;
      final model = await _models.installed();
      final automatic = await _models.readAutoTranscribe();
      if (_disposed) return;
      _model = model;
      _autoTranscribe = automatic && model != null && supported;
      if (automatic && !_autoTranscribe) {
        await _models.writeAutoTranscribe(false);
      }
    } catch (_) {
      if (!_disposed) _error = '无法读取语音转写设置，请重新准备模型。';
    } finally {
      _initialized = true;
      _notify();
    }
  }

  Future<void> downloadModel() async {
    if (_disposed || busy) return;
    await initialize();
    if (_disposed || busy) return;
    if (!supported) {
      _error = '当前设备暂不支持本地语音转写。';
      _notify();
      return;
    }
    _downloading = true;
    _downloadCancelled = false;
    _downloadProgress = null;
    _error = null;
    _notify();
    try {
      await stop();
      if (_disposed || _downloadCancelled) return;
      final model = await _models.download(
        onProgress: (progress) {
          if (_disposed || _downloadCancelled) return;
          final normalized = progress.clamp(0.0, 1.0);
          if (_downloadProgress != null &&
              (normalized - _downloadProgress!).abs() < .005) {
            return;
          }
          _downloadProgress = normalized;
          _notify();
        },
      );
      if (_disposed || _downloadCancelled) return;
      _model = model;
    } catch (error) {
      if (!_disposed && !_downloadCancelled) {
        _error = error is SpeechModelException
            ? error.message
            : '语音模型下载未完成，请检查网络和存储空间后重试。';
      }
    } finally {
      _downloading = false;
      _downloadProgress = null;
      _notify();
    }
  }

  Future<void> cancelDownload() async {
    if (!_downloading) return;
    _downloadCancelled = true;
    await _models.cancelDownload();
  }

  Future<void> setAutoTranscribe(bool enabled) async {
    if (_disposed || busy) return;
    await initialize();
    if (_disposed || busy) return;
    if (enabled && (!hasModel || !supported)) {
      _error = '先下载可用的离线语音模型，再开启自动转写。';
      _notify();
      return;
    }
    _changingSettings = true;
    _error = null;
    _notify();
    try {
      if (!enabled) await stop();
      await _models.writeAutoTranscribe(enabled);
      if (!_disposed) _autoTranscribe = enabled;
    } catch (_) {
      if (!_disposed) _error = '自动转写设置未保存，请重试。';
    } finally {
      _changingSettings = false;
      _notify();
    }
  }

  Future<void> removeModel() async {
    if (_disposed || busy) return;
    await initialize();
    if (_disposed || busy) return;
    _changingSettings = true;
    _error = null;
    _notify();
    try {
      await stop();
      await _models.writeAutoTranscribe(false);
      _autoTranscribe = false;
      await _models.remove();
      _model = null;
    } catch (_) {
      if (!_disposed) _error = '模型未移除，请稍后重试。';
    } finally {
      _changingSettings = false;
      _notify();
    }
  }

  /// Automatic calls are opt-in. A manual retry also works with auto mode off.
  Future<void> enqueue(
    String entryId,
    String audioPath, {
    bool manual = false,
  }) async {
    if (_disposed || entryId.isEmpty || audioPath.isEmpty) return;
    final epoch = _stopEpoch;
    final id = _AudioId(entryId, audioPath);
    final entryVersion = _entryVersions[entryId] ?? 0;
    final previousVersion = _versions[id] ?? 0;
    await initialize();
    if (_disposed ||
        epoch != _stopEpoch ||
        entryVersion != (_entryVersions[entryId] ?? 0) ||
        previousVersion != (_versions[id] ?? 0) ||
        busy ||
        (!manual && !_autoTranscribe)) {
      return;
    }
    if (_states[id]?.active == true) return;
    if (!hasModel || !supported) {
      if (manual) {
        _states[id] = const AudioTranscriptionState(
          stage: AudioTranscriptionStage.failed,
          error: '先在设置中下载可用的离线语音模型。',
        );
        _notify();
      }
      return;
    }
    if (!manual && _states[id]?.stage == AudioTranscriptionStage.completed) {
      return;
    }
    if (_queue.length >= _maximumQueued) {
      _states[id] = const AudioTranscriptionState(
        stage: AudioTranscriptionStage.failed,
        error: '转写队列较长，请稍后手动重试。',
      );
      _notify();
      return;
    }
    final version = (_versions[id] ?? 0) + 1;
    _versions[id] = version;
    _queue.add(_AudioTask(id, version));
    _states[id] = AudioTranscriptionState(
      stage: AudioTranscriptionStage.queued,
      text: _states[id]?.text,
    );
    _notify();
    _schedule();
  }

  Future<void> retry(String entryId, String audioPath) =>
      enqueue(entryId, audioPath, manual: true);

  /// Briefly wait for a keyboard transition or other foreground interaction.
  void deferForInteraction({
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (_disposed) return;
    _interactionDeferred = true;
    _interactionTimer?.cancel();
    _interactionTimer = Timer(duration, () {
      _interactionDeferred = false;
      _interactionTimer = null;
      _schedule(delay: Duration.zero);
    });
    if (_current != null) return;
    _timer?.cancel();
    _timer = null;
    _schedule(delay: duration);
  }

  Future<void> cancel(String entryId, String audioPath) async {
    final id = _AudioId(entryId, audioPath);
    _versions[id] = (_versions[id] ?? 0) + 1;
    _queue.removeWhere((task) => task.id == id);
    final state = _states[id];
    if (state?.active == true) {
      _states[id] = AudioTranscriptionState(
        stage: AudioTranscriptionStage.cancelled,
        text: state?.text,
      );
    }
    _notify();
    if (_current?.id == id) await _engine.cancel();
  }

  Future<void> removeEntry(String entryId) async {
    _entryVersions[entryId] = (_entryVersions[entryId] ?? 0) + 1;
    final ids = _states.keys.where((id) => id.entryId == entryId).toList();
    for (final id in ids) {
      _versions[id] = (_versions[id] ?? 0) + 1;
      _states.remove(id);
    }
    _queue.removeWhere((task) => task.id.entryId == entryId);
    _notify();
    if (_current?.id.entryId == entryId) await _engine.cancel();
  }

  Future<void> stop() {
    _stopEpoch++;
    return _stopCompletion ??= _stop().whenComplete(() {
      _stopCompletion = null;
      _schedule();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    _interactionTimer?.cancel();
    _interactionTimer = null;
    _interactionDeferred = false;
    for (final entry in _states.entries.toList()) {
      if (!entry.value.active) continue;
      _versions[entry.key] = (_versions[entry.key] ?? 0) + 1;
      _states[entry.key] = AudioTranscriptionState(
        stage: AudioTranscriptionStage.cancelled,
        text: entry.value.text,
      );
    }
    _queue.clear();
    _notify();
    await _engine.cancel();
    await _drainCompletion;
  }

  bool get _canStartNow {
    if (_interactionDeferred) return false;
    try {
      return _canStart();
    } catch (_) {
      return false;
    }
  }

  void _schedule({Duration? delay}) {
    if (_disposed ||
        _downloading ||
        _changingSettings ||
        _queue.isEmpty ||
        _drainCompletion != null ||
        _stopCompletion != null ||
        _timer != null) {
      return;
    }
    _timer = Timer(delay ?? _queueDelay, () {
      _timer = null;
      if (!_canStartNow) {
        _schedule(delay: const Duration(milliseconds: 300));
        return;
      }
      _drainCompletion = _drain().whenComplete(() {
        _drainCompletion = null;
        final deferred = _deferred;
        _deferred = false;
        _schedule(delay: deferred ? const Duration(milliseconds: 300) : null);
      });
    });
  }

  bool _active(_AudioTask task) =>
      !_disposed && _versions[task.id] == task.version;

  Future<bool> _stillCurrent(_AudioTask task) async =>
      _active(task) &&
      await _isCurrent(task.id.entryId, task.id.audioPath) &&
      _active(task);

  Future<void> _drain() async {
    while (!_disposed && _queue.isNotEmpty && _model != null) {
      if (!_canStartNow) {
        _deferred = true;
        return;
      }
      final task = _queue.removeFirst();
      if (!_active(task)) continue;
      try {
        if (!await _stillCurrent(task)) {
          if (_active(task)) _states.remove(task.id);
          continue;
        }
        // An asynchronous entry check can outlive the CPU/foreground permit.
        if (!_canStartNow) {
          _queue.addFirst(task);
          _deferred = true;
          return;
        }
        _current = task;
        _states[task.id] = AudioTranscriptionState(
          stage: AudioTranscriptionStage.transcribing,
          text: _states[task.id]?.text,
        );
        _notify();
        final text = (await _engine.transcribe(
          task.id.audioPath,
          model: _model!,
          onProgress: (progress) {
            if (!_active(task)) return;
            final state = _states[task.id];
            final value = progress.clamp(0.0, 1.0);
            if (state?.progress != null &&
                (state!.progress! - value).abs() < .01) {
              return;
            }
            _states[task.id] = AudioTranscriptionState(
              stage: AudioTranscriptionStage.transcribing,
              text: state?.text,
              progress: value,
            );
            _notify();
          },
        )).trim();
        if (!await _stillCurrent(task)) {
          if (_active(task)) _states.remove(task.id);
          continue;
        }
        if (text.isEmpty) throw const FormatException('没有识别到清晰的人声');
        if (text.length > 16000) throw const FormatException('转写内容过长，请使用较短的录音');
        await _onCompleted(task.id.entryId, task.id.audioPath, text);
        if (!await _stillCurrent(task)) {
          if (_active(task)) _states.remove(task.id);
          continue;
        }
        _states[task.id] = AudioTranscriptionState(
          stage: AudioTranscriptionStage.completed,
          text: text,
        );
      } catch (error) {
        if (_active(task)) {
          _states[task.id] = AudioTranscriptionState(
            stage: AudioTranscriptionStage.failed,
            text: _states[task.id]?.text,
            error: _describeError(error),
          );
        }
      } finally {
        if (identical(_current, task)) _current = null;
        _notify();
      }
    }
  }

  String _describeError(Object error) {
    if (error is TranscriptionException) return error.message;
    if (error is FormatException &&
        const {'没有识别到清晰的人声', '转写内容过长，请使用较短的录音'}.contains(error.message)) {
      return error.message.toString();
    }
    // Native errors can contain private paths or decoder input. Keep them out
    // of notifications and logs; retry leaves the recording untouched.
    return '语音转写未完成，请确认录音可播放且不超过 3 分钟，再重试。';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _interactionTimer?.cancel();
    _interactionTimer = null;
    _queue.clear();
    _downloadCancelled = true;
    try {
      await _models.cancelDownload();
    } catch (_) {}
    try {
      await _engine.cancel();
    } catch (_) {}
    try {
      await _drainCompletion;
    } catch (_) {}
    try {
      await _models.dispose();
    } catch (_) {}
    await _engine.dispose();
  }

  @override
  void dispose() {
    unawaited(close().catchError((Object _) {}));
    super.dispose();
  }
}

class _AudioId {
  const _AudioId(this.entryId, this.audioPath);
  final String entryId;
  final String audioPath;

  @override
  bool operator ==(Object other) =>
      other is _AudioId &&
      entryId == other.entryId &&
      audioPath == other.audioPath;

  @override
  int get hashCode => Object.hash(entryId, audioPath);
}

class _AudioTask {
  const _AudioTask(this.id, this.version);
  final _AudioId id;
  final int version;
}
