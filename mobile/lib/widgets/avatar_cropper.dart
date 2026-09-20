import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

/// Lets people frame a square avatar with familiar drag and pinch gestures.
/// The result is a standalone PNG, so changing the source image never leaves a
/// stale cached avatar behind.
Future<Uint8List?> cropDiaryAvatar(BuildContext context, String sourcePath) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _AvatarCropperPage(sourcePath: sourcePath),
    ),
  );
}

class _AvatarCropperPage extends StatefulWidget {
  const _AvatarCropperPage({required this.sourcePath});

  final String sourcePath;

  @override
  State<_AvatarCropperPage> createState() => _AvatarCropperPageState();
}

class _AvatarCropperPageState extends State<_AvatarCropperPage> {
  late final Future<ui.Image> _imageFuture = _loadImage();
  ui.Image? _image;
  double _scale = 1;
  double _startScale = 1;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _cropSide = 0;
  bool _isSaving = false;
  String? _error;

  Future<ui.Image> _loadImage() async {
    final bytes = await File(widget.sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _image = frame.image;
    return frame.image;
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _startCrop(ScaleStartDetails details) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocalPoint = details.localFocalPoint;
  }

  void _updateCrop(
    ScaleUpdateDetails details,
    ui.Image image,
    double cropSide,
  ) {
    final scale = (_startScale * details.scale).clamp(1, 4).toDouble();
    final delta = details.localFocalPoint - _startFocalPoint;
    setState(() {
      _scale = scale;
      _offset = _clampOffset(image, cropSide, scale, _startOffset + delta);
    });
  }

  void _resetCrop() {
    setState(() {
      _scale = 1;
      _offset = Offset.zero;
    });
  }

  Future<void> _save(ui.Image image) async {
    if (_isSaving || _cropSide <= 0) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final bytes = await _renderCrop(image, _cropSide);
      if (mounted) Navigator.pop(context, bytes);
    } on Object {
      if (mounted) setState(() => _error = '暂时无法裁剪这张图片，请换一张再试。');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<Uint8List> _renderCrop(ui.Image image, double cropSide) async {
    final imageScale = _baseScale(image, cropSide) * _scale;
    final renderedWidth = image.width * imageScale;
    final renderedHeight = image.height * imageScale;
    final renderedLeft = cropSide / 2 - renderedWidth / 2 + _offset.dx;
    final renderedTop = cropSide / 2 - renderedHeight / 2 + _offset.dy;
    final source = Rect.fromLTRB(
      (-renderedLeft / imageScale).clamp(0, image.width).toDouble(),
      (-renderedTop / imageScale).clamp(0, image.height).toDouble(),
      ((cropSide - renderedLeft) / imageScale).clamp(0, image.width).toDouble(),
      ((cropSide - renderedTop) / imageScale).clamp(0, image.height).toDouble(),
    );
    if (source.width <= 0 || source.height <= 0) {
      throw StateError('头像裁剪范围无效');
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      source,
      const Rect.fromLTWH(0, 0, 512, 512),
      Paint()..filterQuality = FilterQuality.high,
    );
    final output = await recorder.endRecording().toImage(512, 512);
    try {
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('无法编码头像图片');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      output.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('调整头像'),
        actions: [
          TextButton(
            key: const Key('avatar-crop-save'),
            onPressed: _isSaving || _image == null
                ? null
                : () => _save(_image!),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('完成', style: TextStyle(color: colors.terracotta)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<ui.Image>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final image = snapshot.data;
          if (image == null || snapshot.hasError) {
            return _AvatarCropError(
              onBack: () => Navigator.pop(context),
              message: '无法读取这张图片，请换一张再试。',
            );
          }
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = math.min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      _cropSide = side;
                      return Center(
                        child: _AvatarCropCanvas(
                          image: image,
                          side: side,
                          scale: _scale,
                          offset: _offset,
                          onScaleStart: _startCrop,
                          onScaleUpdate: (details) =>
                              _updateCrop(details, image, side),
                          onDoubleTap: _resetCrop,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '拖动调整位置，双指缩放图片',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '头像会显示为圆形；双击图片可恢复初始位置。',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      key: const Key('avatar-crop-reset'),
                      onPressed: _resetCrop,
                      icon: const Icon(Icons.center_focus_strong_outlined),
                      label: const Text('重置调整'),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.terracotta,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarCropCanvas extends StatelessWidget {
  const _AvatarCropCanvas({
    required this.image,
    required this.side,
    required this.scale,
    required this.offset,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onDoubleTap,
  });

  final ui.Image image;
  final double side;
  final double scale;
  final Offset offset;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final baseScale = _baseScale(image, side);
    return Semantics(
      label: '头像裁剪区域',
      child: GestureDetector(
        key: const Key('avatar-crop-canvas'),
        behavior: HitTestBehavior.opaque,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onDoubleTap: onDoubleTap,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: colors.ink,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surface, width: 4),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: .18),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: Center(
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: image.width * baseScale,
                    height: image.height * baseScale,
                    child: RawImage(
                      image: image,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCropError extends StatelessWidget {
  const _AvatarCropError({required this.onBack, required this.message});

  final VoidCallback onBack;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onBack, child: const Text('返回')),
          ],
        ),
      ),
    );
  }
}

double _baseScale(ui.Image image, double cropSide) =>
    math.max(cropSide / image.width, cropSide / image.height);

Offset _clampOffset(
  ui.Image image,
  double cropSide,
  double scale,
  Offset value,
) {
  final baseScale = _baseScale(image, cropSide) * scale;
  final maxX = math.max(0, (image.width * baseScale - cropSide) / 2);
  final maxY = math.max(0, (image.height * baseScale - cropSide) / 2);
  return Offset(
    value.dx.clamp(-maxX, maxX).toDouble(),
    value.dy.clamp(-maxY, maxY).toDouble(),
  );
}
