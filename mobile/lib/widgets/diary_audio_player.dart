import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/widgets/audio_waveform_loader.dart';

/// A compact, local-file audio player used for diary voice attachments.
///
/// The waveform paints extracted audio amplitudes directly, while its played
/// part tracks the real audio position without a large widget tree.
class DiaryAudioPlayer extends StatefulWidget {
  const DiaryAudioPlayer({
    required this.path,
    this.label,
    this.onRemove,
    this.compact = false,
    this.chatStyle = false,
    this.chatStyleHighContrast = false,
    this.loadMetadata = true,
    this.loadWaveform = true,
    this.waveformLoader,
    super.key,
  });

  final String path;
  final String? label;
  final VoidCallback? onRemove;
  final bool compact;
  final bool chatStyle;
  final bool chatStyleHighContrast;
  final bool loadMetadata;
  final bool loadWaveform;
  final DiaryAudioWaveformLoader? waveformLoader;

  @override
  State<DiaryAudioPlayer> createState() => _DiaryAudioPlayerState();
}

class _DiaryAudioPlayerState extends State<DiaryAudioPlayer> {
  AudioPlayer? _player;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration? _dragPosition;
  bool _isLoading = false;
  bool _isPrepared = false;
  bool _isPlaying = false;
  bool _hasError = false;
  int _metadataRequest = 0;
  int _waveformRequest = 0;
  bool _waveformRequested = false;
  DiaryAudioWaveform? _waveform;

  @override
  void initState() {
    super.initState();
    if (widget.loadMetadata) unawaited(_loadMetadata());
    if (widget.loadWaveform) unawaited(_loadWaveform());
  }

  @override
  void didUpdateWidget(covariant DiaryAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) return;
    _waveformRequest++;
    setState(() {
      _duration = Duration.zero;
      _position = Duration.zero;
      _dragPosition = null;
      _isPrepared = false;
      _hasError = false;
      _waveform = null;
      _waveformRequested = false;
    });
    if (_player != null) {
      unawaited(_prepare());
    } else if (widget.loadMetadata) {
      unawaited(_loadMetadata());
    }
    if (widget.loadWaveform) unawaited(_loadWaveform());
  }

  Future<void> _loadWaveform() async {
    if (_waveformRequested) return;
    _waveformRequested = true;
    final request = ++_waveformRequest;
    final waveform =
        await (widget.waveformLoader ?? createDiaryAudioWaveformLoader()).load(
          widget.path,
        );
    if (!mounted || request != _waveformRequest) return;
    if (waveform == null) {
      _waveformRequested = false;
      return;
    }
    setState(() => _waveform = waveform);
  }

  Future<void> _loadMetadata() async {
    final request = ++_metadataRequest;
    final probe = AudioPlayer();
    try {
      final duration = await probe.setFilePath(widget.path);
      if (!mounted || request != _metadataRequest || _player != null) return;
      if (duration != null) setState(() => _duration = duration);
    } catch (_) {
      // Loading the visible duration is optional. Playback reports real errors.
    } finally {
      try {
        await probe.dispose();
      } catch (_) {
        // There is nothing to clean up when a platform player was not created.
      }
    }
  }

  Future<void> _prepare({bool playAfterLoad = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isPlaying = false;
        _position = Duration.zero;
        _dragPosition = null;
      });
    }
    try {
      final player = _ensurePlayer();
      final duration = await player.setFilePath(widget.path);
      if (!mounted) return;
      setState(() {
        _duration = duration ?? Duration.zero;
        _isLoading = false;
        _isPrepared = true;
      });
      if (playAfterLoad) await player.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onPlayerState(PlayerState state) {
    if (!mounted) return;
    final completed = state.processingState == ProcessingState.completed;
    setState(() {
      _isPlaying = state.playing && !completed;
      if (completed && _duration > Duration.zero) _position = _duration;
    });
  }

  Future<void> _togglePlayback() async {
    if (!_waveformRequested) unawaited(_loadWaveform());
    if (!_isPrepared) {
      await _prepare(playAfterLoad: true);
      return;
    }
    if (_hasError) {
      await _prepare(playAfterLoad: true);
      return;
    }
    if (_isLoading) return;
    try {
      if (_isPlaying) {
        await _player?.pause();
      } else {
        if (_duration > Duration.zero && _position >= _duration) {
          await _player?.seek(Duration.zero);
        }
        await _player?.play();
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _previewSeek(Duration position) {
    setState(() => _dragPosition = _clampPosition(position));
  }

  Future<void> _commitSeek(Duration position) async {
    final target = _clampPosition(position);
    if (!_isPrepared) await _prepare();
    final player = _player;
    if (player == null || !_isPrepared) return;
    try {
      await player.seek(target);
      if (mounted) {
        setState(() {
          _position = target;
          _dragPosition = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _dragPosition = null);
    }
  }

  Duration _clampPosition(Duration value) {
    if (_duration <= Duration.zero) return Duration.zero;
    return Duration(
      microseconds: value.inMicroseconds.clamp(0, _duration.inMicroseconds),
    );
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  AudioPlayer _ensurePlayer() {
    final player = _player ??= AudioPlayer();
    _durationSubscription ??= player.durationStream.listen((duration) {
      if (mounted && duration != null) setState(() => _duration = duration);
    });
    _positionSubscription ??= player.positionStream.listen((position) {
      if (mounted && _dragPosition == null) {
        setState(() => _position = position);
      }
    });
    _stateSubscription ??= player.playerStateStream.listen(_onPlayerState);
    return player;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final shownPosition = _dragPosition ?? _position;
    final progress = _duration <= Duration.zero
        ? 0.0
        : (shownPosition.inMilliseconds / _duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final label = widget.label ?? '语音';
    final playTooltip = _hasError
        ? '重新加载音频'
        : _isPlaying
        ? '暂停'
        : shownPosition >= _duration && _duration > Duration.zero
        ? '重新播放'
        : '播放';

    final chatForeground = widget.chatStyleHighContrast
        ? colors.onHero
        : colors.terracotta;
    final chatInactiveWaveform = widget.chatStyleHighContrast
        ? Color.lerp(colors.terracotta, colors.onHero, .55)!
        : colors.terracotta;
    final playButton = IconButton.filled(
      tooltip: playTooltip,
      onPressed: _isLoading ? null : _togglePlayback,
      style: IconButton.styleFrom(
        backgroundColor: colors.terracotta,
        foregroundColor: colors.onHero,
        minimumSize: const Size.square(40),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _hasError
                  ? Icons.refresh_rounded
                  : _isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
    );
    final waveform = _WaveformSeekBar(
      progress: progress,
      duration: _duration,
      activeColor: widget.chatStyle
          ? (widget.chatStyleHighContrast ? colors.onHero : colors.ink)
          : colors.terracotta,
      inactiveColor: widget.chatStyle ? chatInactiveWaveform : colors.line,
      amplitudes: _waveform?.amplitudes,
      enabled: !_isLoading && !_hasError && _duration > Duration.zero,
      onPreview: _previewSeek,
      onCommit: (position) => unawaited(_commitSeek(position)),
    );

    if (widget.chatStyle) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 260.0);
          return Semantics(
            container: true,
            label:
                '语音，${_formatDuration(shownPosition)} / ${_formatDuration(_duration)}',
            child: SizedBox(
              width: width,
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: playTooltip,
                    onPressed: _isLoading ? null : _togglePlayback,
                    style: IconButton.styleFrom(
                      backgroundColor: widget.chatStyleHighContrast
                          ? colors.onHero
                          : colors.terracotta,
                      foregroundColor: widget.chatStyleHighContrast
                          ? colors.terracotta
                          : colors.onHero,
                      minimumSize: const Size.square(34),
                      maximumSize: const Size.square(34),
                      padding: EdgeInsets.zero,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _hasError
                                ? Icons.refresh_rounded
                                : _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: waveform),
                  const SizedBox(width: 8),
                  Text(
                    _hasError
                        ? '重试'
                        : '${_formatDuration(shownPosition)} / ${_formatDuration(_duration)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: chatForeground),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tiny = constraints.maxWidth < 180 && widget.onRemove == null;
        return Semantics(
          container: true,
          label: '$label，音频播放器',
          child: Container(
            padding: tiny
                ? const EdgeInsets.all(6)
                : EdgeInsets.symmetric(
                    horizontal: widget.compact ? 10 : 12,
                    vertical: widget.compact ? 8 : 10,
                  ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.line),
            ),
            child: tiny
                ? Row(
                    children: [
                      playButton,
                      const SizedBox(width: 5),
                      Expanded(child: waveform),
                    ],
                  )
                : Row(
                    children: [
                      playButton,
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _hasError
                                      ? '无法播放'
                                      : '${_formatDuration(shownPosition)} / ${_formatDuration(_duration)}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: _hasError
                                            ? colors.terracotta
                                            : colors.mutedInk,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            waveform,
                          ],
                        ),
                      ),
                      if (widget.onRemove != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: '移除录音',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onRemove,
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _WaveformSeekBar extends StatefulWidget {
  const _WaveformSeekBar({
    required this.progress,
    required this.duration,
    required this.activeColor,
    required this.inactiveColor,
    required this.amplitudes,
    required this.enabled,
    required this.onPreview,
    required this.onCommit,
  });

  final double progress;
  final Duration duration;
  final Color activeColor;
  final Color inactiveColor;
  final List<double>? amplitudes;
  final bool enabled;
  final ValueChanged<Duration> onPreview;
  final ValueChanged<Duration> onCommit;

  @override
  State<_WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<_WaveformSeekBar> {
  Duration _lastPosition = Duration.zero;

  Duration _positionFor(double dx, double width) {
    if (widget.duration <= Duration.zero || width <= 0) return Duration.zero;
    final fraction = (dx / width).clamp(0.0, 1.0);
    return Duration(
      microseconds: (widget.duration.inMicroseconds * fraction).round(),
    );
  }

  void _preview(double dx, double width) {
    _lastPosition = _positionFor(dx, width);
    widget.onPreview(_lastPosition);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          slider: true,
          label: '音频播放进度',
          value: '${(widget.progress * 100).round()}%',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.enabled
                ? (details) {
                    final position = _positionFor(
                      details.localPosition.dx,
                      width,
                    );
                    widget.onPreview(position);
                    widget.onCommit(position);
                  }
                : null,
            onHorizontalDragStart: widget.enabled
                ? (details) => _preview(details.localPosition.dx, width)
                : null,
            onHorizontalDragUpdate: widget.enabled
                ? (details) => _preview(details.localPosition.dx, width)
                : null,
            onHorizontalDragEnd: widget.enabled
                ? (_) => widget.onCommit(_lastPosition)
                : null,
            child: SizedBox(
              height: 32,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _WaveformPainter(
                    progress: widget.progress,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                    amplitudes: widget.amplitudes,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.amplitudes,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final List<double>? amplitudes;

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = (size.width / 6).floor().clamp(18, 56);
    final spacing = size.width / barCount;
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < barCount; index++) {
      final amplitude = _amplitudeFor(index, barCount);
      final height = (size.height * (.14 + math.sqrt(amplitude) * .86)).clamp(
        4.0,
        size.height,
      );
      final x = spacing * (index + .5);
      paint.color = x / size.width <= progress ? activeColor : inactiveColor;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        !identical(oldDelegate.amplitudes, amplitudes);
  }

  double _amplitudeFor(int index, int barCount) {
    final samples = amplitudes;
    if (samples == null || samples.isEmpty) return .06;
    final start = index * samples.length ~/ barCount;
    final end = math.max(start + 1, (index + 1) * samples.length ~/ barCount);
    var peak = 0.0;
    for (
      var sampleIndex = start;
      sampleIndex < end && sampleIndex < samples.length;
      sampleIndex++
    ) {
      peak = math.max(peak, samples[sampleIndex]);
    }
    return peak.clamp(0.0, 1.0);
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final minutePart = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
  final secondPart = seconds.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutePart:$secondPart'
      : '$minutePart:$secondPart';
}
