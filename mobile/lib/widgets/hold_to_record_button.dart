import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/data/quick_audio_recorder.dart';

class HoldToRecordButton extends StatefulWidget {
  const HoldToRecordButton({
    required this.onRecorded,
    this.buttonKey,
    this.enabled = true,
    this.onActivityChanged,
    this.onError,
    this.recorder,
    super.key,
  });

  final Future<void> Function(String path) onRecorded;
  final Key? buttonKey;
  final bool enabled;
  final ValueChanged<bool>? onActivityChanged;
  final ValueChanged<String>? onError;
  final QuickAudioRecorder? recorder;

  @override
  State<HoldToRecordButton> createState() => _HoldToRecordButtonState();
}

class _HoldToRecordButtonState extends State<HoldToRecordButton> {
  late final QuickAudioRecorder _recorder;
  Timer? _durationTimer;
  DateTime? _startedAt;
  Duration _duration = Duration.zero;
  bool _pointerDown = false;
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
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _start() async {
    if (!widget.enabled || _busy) return;
    _pointerDown = true;
    _reportActivity(true);
    setState(() => _starting = true);
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
      if (!_pointerDown) {
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
    } catch (_) {
      if (mounted) widget.onError?.call('录音没有开始，请重试');
    } finally {
      if (mounted && !_recording) setState(() => _starting = false);
      if (!_recording) _reportActivity(false);
    }
  }

  Future<void> _stop() async {
    _pointerDown = false;
    if (!_recording) return;
    _durationTimer?.cancel();
    setState(() {
      _recording = false;
      _finishing = true;
    });
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      if (path == null) {
        widget.onError?.call('没有录到声音，请按住后再试');
        return;
      }
      await widget.onRecorded(path);
    } catch (_) {
      if (mounted) widget.onError?.call('录音保存失败，请重试');
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
    final isActive = _starting || _recording;
    final label = _recording
        ? '正在录音 ${_formatDuration(_duration)} · 松开添加'
        : _starting
        ? '正在连接麦克风…'
        : _finishing
        ? '正在添加录音…'
        : '按住录音';
    return Semantics(
      button: true,
      label: _recording ? '正在录音，松开后添加到日记' : '按住录音',
      child: Listener(
        key: widget.buttonKey,
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.enabled && !_busy
            ? (_) => unawaited(_start())
            : null,
        onPointerUp: widget.enabled ? (_) => unawaited(_stop()) : null,
        onPointerCancel: widget.enabled ? (_) => unawaited(_stop()) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? colors.terracottaSoft : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? colors.terracotta : colors.line,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _recording ? Icons.mic : Icons.mic_none_outlined,
                color: isActive ? colors.terracotta : colors.ink,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive ? colors.terracotta : colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
