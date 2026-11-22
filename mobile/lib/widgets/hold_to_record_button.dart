import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/data/quick_audio_recorder.dart';

import 'recording_feedback.dart';

class HoldToRecordButton extends StatefulWidget {
  const HoldToRecordButton({
    required this.onRecorded,
    this.buttonKey,
    this.enabled = true,
    this.showRecordingOverlay = false,
    this.onActivityChanged,
    this.onError,
    this.recorder,
    super.key,
  });

  final Future<void> Function(String path) onRecorded;
  final Key? buttonKey;
  final bool enabled;
  final bool showRecordingOverlay;
  final ValueChanged<bool>? onActivityChanged;
  final ValueChanged<String>? onError;
  final QuickAudioRecorder? recorder;

  @override
  State<HoldToRecordButton> createState() => _HoldToRecordButtonState();
}

class _HoldToRecordButtonState extends State<HoldToRecordButton> {
  static const _slideToCancelDistance = 64.0;
  static const _waveformBarCount = 17;
  late final QuickAudioRecorder _recorder;
  final _overlayController = OverlayPortalController();
  final _waveform = ValueNotifier(List<double>.filled(_waveformBarCount, 0));
  StreamSubscription<double>? _levelSubscription;
  Timer? _durationTimer;
  DateTime? _startedAt;
  Duration _duration = Duration.zero;
  int? _pointer;
  double _pointerDownY = 0;
  bool _cancelOnRelease = false;
  bool _starting = false;
  bool _recording = false;
  bool _finishing = false;
  bool _activityReported = false;

  bool get _busy => _starting || _recording || _finishing;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorder ?? createQuickAudioRecorder();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    unawaited(_levelSubscription?.cancel());
    _waveform.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _start(PointerDownEvent event) async {
    if (!widget.enabled || _busy || event.buttons != kPrimaryButton) return;
    _pointer = event.pointer;
    _pointerDownY = event.position.dy;
    _reportActivity(true);
    setState(() {
      _starting = true;
      _cancelOnRelease = false;
    });
    try {
      final allowed = await _recorder.start();
      if (!mounted) {
        await _recorder.cancel();
        return;
      }
      if (!allowed) {
        widget.onError?.call('请允许麦克风权限后再录音');
        return;
      }
      if (_pointer == null) {
        await _recorder.cancel();
        return;
      }
      _startedAt = DateTime.now();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final startedAt = _startedAt;
        if (!mounted || !_recording || startedAt == null) return;
        setState(() => _duration = DateTime.now().difference(startedAt));
      });
      setState(() {
        _starting = false;
        _recording = true;
        _duration = Duration.zero;
      });
      if (widget.showRecordingOverlay) {
        _waveform.value = List<double>.filled(_waveformBarCount, 0);
        _overlayController.show();
        _levelSubscription = _recorder.levels.listen((level) {
          _waveform.value = [..._waveform.value.skip(1), level];
        }, onError: (Object _, StackTrace _) {});
      }
    } catch (_) {
      if (mounted) widget.onError?.call('录音没有开始，请重试');
    } finally {
      if (!_recording) {
        _pointer = null;
        if (mounted) setState(() => _starting = false);
        _reportActivity(false);
      }
    }
  }

  bool _aboveCancelThreshold(Offset position) =>
      _pointerDownY - position.dy >= _slideToCancelDistance;

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final cancel = _aboveCancelThreshold(event.position);
    if (cancel == _cancelOnRelease) return;
    setState(() => _cancelOnRelease = cancel);
    if (_recording) unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _finish(PointerEvent event) async {
    if (event.pointer != _pointer) return;
    final cancel =
        event is PointerCancelEvent || _aboveCancelThreshold(event.position);
    _pointer = null;
    if (!_recording) return;
    _durationTimer?.cancel();
    if (_overlayController.isShowing) _overlayController.hide();
    unawaited(_levelSubscription?.cancel());
    _levelSubscription = null;
    setState(() {
      _recording = false;
      _finishing = true;
      _cancelOnRelease = cancel;
    });
    try {
      if (cancel) {
        await _recorder.cancel();
        return;
      }
      final path = await _recorder.stop();
      if (!mounted) return;
      if (path == null) {
        widget.onError?.call('没有录到声音，请按住后再试');
        return;
      }
      await widget.onRecorded(path);
    } catch (_) {
      if (mounted) widget.onError?.call(cancel ? '录音取消失败，请重试' : '录音保存失败，请重试');
    } finally {
      if (mounted) {
        setState(() {
          _finishing = false;
          _duration = Duration.zero;
        });
      }
      _reportActivity(false);
    }
  }

  void _reportActivity(bool active) {
    if (_activityReported == active) return;
    _activityReported = active;
    widget.onActivityChanged?.call(active);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final theme = Theme.of(context);
    final isActive = _starting || _recording;
    final elapsed = _formatDuration(_duration);
    final releaseHint = _cancelOnRelease ? '松开取消' : '松开添加';
    final label = _recording
        ? '正在录音'
        : _starting
        ? '正在连接麦克风…'
        : _finishing
        ? (_cancelOnRelease ? '正在取消录音…' : '正在添加录音…')
        : '按住录音';
    final button = Semantics(
      button: true,
      enabled: widget.enabled,
      label: _recording ? '正在录音，$releaseHint' : label,
      value: _recording ? elapsed : null,
      excludeSemantics: true,
      child: Listener(
        key: widget.buttonKey,
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.enabled && !_busy
            ? (event) => unawaited(_start(event))
            : null,
        onPointerMove: _move,
        onPointerUp: (event) => unawaited(_finish(event)),
        onPointerCancel: (event) => unawaited(_finish(event)),
        child: AnimatedContainer(
          duration: DiaryMotion.duration(
            context,
            const Duration(milliseconds: 140),
          ),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _recording && _cancelOnRelease
                ? theme.colorScheme.errorContainer
                : isActive
                ? colors.terracottaSoft
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? colors.terracotta : colors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isActive ? colors.terracotta : colors.terracottaSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _recording ? Icons.fiber_manual_record : Icons.mic_rounded,
                  color: isActive ? theme.colorScheme.onPrimary : colors.ink,
                  size: _recording ? 14 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_recording)
                      Text(releaseHint, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              if (_recording) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        elapsed,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!widget.showRecordingOverlay) return button;
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) => RecordingFeedback(
        elapsed: elapsed,
        cancelOnRelease: _cancelOnRelease,
        waveform: _waveform,
      ),
      child: button,
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
