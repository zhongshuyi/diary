import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:diary/app/app_theme.dart';

/// A lightweight video card that creates a real frame preview without keeping
/// a video decoder alive in scrolling surfaces such as the conversation.
class DiaryVideoPreview extends StatefulWidget {
  const DiaryVideoPreview({
    required this.path,
    this.label = '视频',
    this.onTap,
    this.onLongPress,
    this.compact = false,
    super.key,
  });

  final String path;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  @override
  State<DiaryVideoPreview> createState() => _DiaryVideoPreviewState();
}

class _DiaryVideoPreviewState extends State<DiaryVideoPreview> {
  late Future<Uint8List?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = _DiaryVideoThumbnails.load(
      widget.path,
      compact: widget.compact,
    );
  }

  @override
  void didUpdateWidget(covariant DiaryVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.compact != widget.compact) {
      _thumbnail = _DiaryVideoThumbnails.load(
        widget.path,
        compact: widget.compact,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final radius = BorderRadius.circular(widget.compact ? 14 : 20);
    final iconSize = widget.compact ? 24.0 : 34.0;
    final preview = Semantics(
      button: true,
      label: '${widget.label}，点按播放',
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: colors.hero,
          child: InkWell(
            onTap:
                widget.onTap ??
                () => showDiaryVideoPlayer(
                  context,
                  path: widget.path,
                  title: widget.label,
                ),
            onLongPress: widget.onLongPress,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<Uint8List?>(
                  future: _thumbnail,
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return Center(
                        child: Icon(
                          Icons.movie_outlined,
                          size: widget.compact ? 29 : 42,
                          color: colors.onHero.withValues(alpha: .78),
                        ),
                      );
                    }
                    return Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .08),
                        Colors.black.withValues(alpha: .58),
                      ],
                      stops: const [.42, 1],
                    ),
                  ),
                ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .38),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.onHero.withValues(alpha: .72),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(widget.compact ? 8 : 11),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: iconSize,
                        color: colors.onHero,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: widget.compact ? 9 : 14,
                  right: widget.compact ? 9 : 14,
                  bottom: widget.compact ? 8 : 12,
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: widget.compact ? 14 : 17,
                        color: colors.onHero,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onHero,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return widget.compact
        ? preview
        : AspectRatio(aspectRatio: 16 / 9, child: preview);
  }
}

class _DiaryVideoThumbnails {
  static const _maxCachedThumbnails = 48;
  static final Map<_VideoThumbnailKey, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> load(String path, {required bool compact}) {
    final key = _VideoThumbnailKey(path: path, compact: compact);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    while (_cache.length >= _maxCachedThumbnails) {
      _cache.remove(_cache.keys.first);
    }
    final thumbnail = VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: compact ? 360 : 640,
      timeMs: 750,
      quality: 76,
    ).catchError((Object _) => null);
    _cache[key] = thumbnail;
    return thumbnail;
  }
}

class _VideoThumbnailKey {
  const _VideoThumbnailKey({required this.path, required this.compact});

  final String path;
  final bool compact;

  @override
  bool operator ==(Object other) =>
      other is _VideoThumbnailKey &&
      other.path == path &&
      other.compact == compact;

  @override
  int get hashCode => Object.hash(path, compact);
}

Future<void> showDiaryVideoPlayer(
  BuildContext context, {
  required String path,
  String title = '视频',
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _DiaryVideoPlayerPage(path: path, title: title),
  ),
);

class _DiaryVideoPlayerPage extends StatefulWidget {
  const _DiaryVideoPlayerPage({required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<_DiaryVideoPlayerPage> createState() => _DiaryVideoPlayerPageState();
}

class _DiaryVideoPlayerPageState extends State<_DiaryVideoPlayerPage> {
  VideoPlayerController? _videoController;
  String? _errorMessage;
  bool _isSpeedBoosting = false;
  bool _isFullscreen = false;
  double? _speedBeforeBoost;
  int _speedBoostSession = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoController = VideoPlayerController.file(
      File(widget.path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    try {
      await videoController.initialize();
      if (!mounted) {
        await videoController.dispose();
        return;
      }
      setState(() {
        _videoController = videoController;
      });
      await videoController.play();
    } on Object {
      await videoController.dispose();
      if (mounted) {
        setState(() => _errorMessage = '这个视频暂时无法播放');
      }
    }
  }

  Future<void> _toggleFullscreen() async {
    final shouldEnterFullscreen = !_isFullscreen;
    setState(() => _isFullscreen = shouldEnterFullscreen);
    if (shouldEnterFullscreen) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _startSpeedBoost() async {
    final videoController = _videoController;
    if (videoController == null || _isSpeedBoosting) return;

    final session = ++_speedBoostSession;
    final previousSpeed = videoController.value.playbackSpeed;
    setState(() {
      _isSpeedBoosting = true;
      _speedBeforeBoost = previousSpeed;
    });
    try {
      await videoController.setPlaybackSpeed(2);
    } on Object {
      if (mounted && session == _speedBoostSession) {
        setState(() {
          _isSpeedBoosting = false;
          _speedBeforeBoost = null;
        });
      }
    }
  }

  Future<void> _stopSpeedBoost() async {
    if (!_isSpeedBoosting) return;

    final videoController = _videoController;
    final previousSpeed = _speedBeforeBoost;
    ++_speedBoostSession;
    setState(() {
      _isSpeedBoosting = false;
      _speedBeforeBoost = null;
    });
    if (videoController == null || previousSpeed == null) return;

    try {
      await videoController.setPlaybackSpeed(previousSpeed);
    } on Object {
      // The video may have been closed while the pointer was being released.
    }
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController;
    final player = _errorMessage != null
        ? _VideoPlaybackError(message: _errorMessage!)
        : videoController == null
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : _VideoCanvas(controller: videoController);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label: '${widget.title}视频播放器',
                    child: player,
                  ),
                ),
                if (videoController != null)
                  Positioned.fill(
                    child: _VideoSpeedBoostGestureLayer(
                      onBoostStart: _startSpeedBoost,
                      onBoostEnd: _stopSpeedBoost,
                    ),
                  ),
              ],
            ),
          ),
          if (videoController != null)
            _VideoPlaybackToolbar(
              controller: videoController,
              isFullscreen: _isFullscreen,
              onFullscreenPressed: _toggleFullscreen,
            ),
        ],
      ),
    );
  }
}

class _VideoCanvas extends StatelessWidget {
  const _VideoCanvas({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = controller.value.aspectRatio;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio.isFinite && aspectRatio > 0
              ? aspectRatio
              : 16 / 9,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _VideoPlaybackToolbar extends StatefulWidget {
  const _VideoPlaybackToolbar({
    required this.controller,
    required this.isFullscreen,
    required this.onFullscreenPressed,
  });

  final VideoPlayerController controller;
  final bool isFullscreen;
  final Future<void> Function() onFullscreenPressed;

  @override
  State<_VideoPlaybackToolbar> createState() => _VideoPlaybackToolbarState();
}

class _VideoPlaybackToolbarState extends State<_VideoPlaybackToolbar> {
  Duration? _previewPosition;
  bool _resumeAfterSeeking = false;

  VideoPlayerController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: const Color(0xFF101010),
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final duration = value.duration;
            final position = _clampPosition(
              _previewPosition ?? value.position,
              duration,
            );
            final hasDuration = duration.inMilliseconds > 0;
            return SizedBox(
              height: 76,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 8, 6),
                child: Column(
                  children: [
                    SizedBox(
                      height: 26,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: const Color(0x55FFFFFF),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: hasDuration
                              ? position.inMilliseconds /
                                    duration.inMilliseconds
                              : 0,
                          onChangeStart: hasDuration
                              ? (_) {
                                  _resumeAfterSeeking = value.isPlaying;
                                  if (_resumeAfterSeeking) _controller.pause();
                                }
                              : null,
                          onChanged: hasDuration
                              ? (progress) => setState(() {
                                  _previewPosition = Duration(
                                    milliseconds:
                                        (duration.inMilliseconds * progress)
                                            .round(),
                                  );
                                })
                              : null,
                          onChangeEnd: hasDuration
                              ? (progress) => _finishSeeking(
                                  duration,
                                  progress,
                                  _resumeAfterSeeking,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: value.isPlaying ? '暂停' : '继续播放',
                            onPressed: () {
                              if (value.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            },
                            color: Colors.white,
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          Text(
                            '${_formatDuration(position)} / '
                            '${_formatDuration(duration)}',
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontFeatures: [FontFeature.tabularFigures()],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<double>(
                            tooltip: '播放速度',
                            onSelected: _controller.setPlaybackSpeed,
                            color: const Color(0xFF272727),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: .5, child: Text('0.5×')),
                              PopupMenuItem(value: 1.0, child: Text('1×')),
                              PopupMenuItem(value: 1.5, child: Text('1.5×')),
                              PopupMenuItem(value: 2.0, child: Text('2×')),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 8,
                              ),
                              child: Text(
                                '${_formatSpeed(value.playbackSpeed)}×',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: widget.isFullscreen ? '退出横屏' : '横屏播放',
                            onPressed: widget.onFullscreenPressed,
                            color: Colors.white,
                            icon: Icon(
                              widget.isFullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _finishSeeking(
    Duration duration,
    double progress,
    bool resumePlayback,
  ) async {
    final target = Duration(
      milliseconds: (duration.inMilliseconds * progress).round(),
    );
    setState(() => _previewPosition = null);
    await _controller.seekTo(target);
    if (resumePlayback) await _controller.play();
  }

  Duration _clampPosition(Duration position, Duration duration) {
    if (duration <= Duration.zero) return Duration.zero;
    if (position < Duration.zero) return Duration.zero;
    if (position > duration) return duration;
    return position;
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSpeed(double speed) {
    return speed == speed.roundToDouble()
        ? speed.toStringAsFixed(0)
        : speed.toStringAsFixed(1);
  }
}

class _VideoSpeedBoostGestureLayer extends StatelessWidget {
  const _VideoSpeedBoostGestureLayer({
    required this.onBoostStart,
    required this.onBoostEnd,
  });

  final Future<void> Function() onBoostStart;
  final Future<void> Function() onBoostEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final edgeWidth = (constraints.maxWidth * .18)
            .clamp(72.0, 128.0)
            .toDouble();
        return Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _SpeedBoostTouchZone(
                width: edgeWidth,
                onBoostStart: onBoostStart,
                onBoostEnd: onBoostEnd,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _SpeedBoostTouchZone(
                width: edgeWidth,
                onBoostStart: onBoostStart,
                onBoostEnd: onBoostEnd,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpeedBoostTouchZone extends StatelessWidget {
  const _SpeedBoostTouchZone({
    required this.width,
    required this.onBoostStart,
    required this.onBoostEnd,
  });

  final double width;
  final Future<void> Function() onBoostStart;
  final Future<void> Function() onBoostEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '长按可两倍速播放，松开恢复原速度',
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (_) => onBoostStart(),
          onLongPressEnd: (_) => onBoostEnd(),
          onLongPressCancel: () => onBoostEnd(),
        ),
      ),
    );
  }
}

class _VideoPlaybackError extends StatelessWidget {
  const _VideoPlaybackError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_file_outlined,
              size: 46,
              color: Colors.white,
            ),
            const SizedBox(height: 14),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
