import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/widgets/local_media_preview.dart';

Future<void> showDiaryImageViewer(
  BuildContext context, {
  required String entryId,
  required List<String> imagePaths,
  required int initialIndex,
  required String heroScope,
}) {
  if (imagePaths.isEmpty) return Future.value();
  final duration = DiaryMotion.duration(context, DiaryMotion.emphasized);
  final curve = DiaryMotion.curve(context, Curves.easeOutCubic);
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => DiaryImageViewer(
        entryId: entryId,
        imagePaths: imagePaths,
        initialIndex: initialIndex,
        heroScope: heroScope,
      ),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curvedAnimation),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    ),
  );
}

String diaryImageHeroTag(
  String entryId,
  int index, {
  String scope = 'default',
}) => 'diary-image:$scope:$entryId:$index';

class DiaryImageThumbnail extends StatelessWidget {
  const DiaryImageThumbnail({
    required this.entryId,
    required this.imagePaths,
    required this.index,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.expand = false,
    this.heroScope = 'default',
    super.key,
  }) : assert(expand || (width != null && height != null));

  final String entryId;
  final List<String> imagePaths;
  final int index;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool expand;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= imagePaths.length) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: '预览第 ${index + 1} 张，共 ${imagePaths.length} 张图片',
      child: GestureDetector(
        key: Key('diary-image-thumbnail-$entryId-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => showDiaryImageViewer(
          context,
          entryId: entryId,
          imagePaths: imagePaths,
          initialIndex: index,
          heroScope: heroScope,
        ),
        child: expand
            ? SizedBox.expand(child: _imagePreview())
            : SizedBox(width: width, height: height, child: _imagePreview()),
      ),
    );
  }

  Widget _imagePreview() {
    return Hero(
      tag: diaryImageHeroTag(entryId, index, scope: heroScope),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: LocalMediaPreview(
          path: imagePaths[index],
          kind: DiaryMediaKind.image,
        ),
      ),
    );
  }
}

class DiaryImageGallery extends StatelessWidget {
  const DiaryImageGallery({
    required this.entryId,
    required this.imagePaths,
    this.maxGridHeight = 260,
    this.heroScope = 'detail',
    this.showHeader = true,
    super.key,
  });

  final String entryId;
  final List<String> imagePaths;
  final double maxGridHeight;
  final String heroScope;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();
    final colors = DiaryThemeColors.of(context);
    final isSingleImage = imagePaths.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Text('照片', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 7),
              Text(
                '${imagePaths.length} 张',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            if (isSingleImage) {
              return SizedBox(
                width: math.min<double>(constraints.maxWidth, maxGridHeight),
                height: maxGridHeight,
                child: DiaryImageThumbnail(
                  entryId: entryId,
                  imagePaths: imagePaths,
                  index: 0,
                  borderRadius: 14,
                  expand: true,
                  heroScope: heroScope,
                ),
              );
            }
            final thumbnailSize = math.min<double>(
              (constraints.maxWidth - 7) / 2,
              maxGridHeight / 2,
            );
            return Wrap(
              key: Key('diary-image-gallery-$entryId'),
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var index = 0; index < imagePaths.length; index++)
                  SizedBox(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    child: DiaryImageThumbnail(
                      entryId: entryId,
                      imagePaths: imagePaths,
                      index: index,
                      borderRadius: 10,
                      expand: true,
                      heroScope: heroScope,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DiaryImageViewer extends StatefulWidget {
  const DiaryImageViewer({
    required this.entryId,
    required this.imagePaths,
    required this.initialIndex,
    required this.heroScope,
    super.key,
  });

  final String entryId;
  final List<String> imagePaths;
  final int initialIndex;
  final String heroScope;

  @override
  State<DiaryImageViewer> createState() => _DiaryImageViewerState();
}

class _DiaryImageViewerState extends State<DiaryImageViewer> {
  static const _loopStart = 1000;
  late final PageController _controller;
  late final int _initialPage;
  late int _activePage;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _initialPage = widget.imagePaths.length > 1
        ? (_loopStart * widget.imagePaths.length) + _currentIndex
        : 0;
    _activePage = _initialPage;
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changePage(int delta) {
    if (widget.imagePaths.length < 2) return;
    final target = _controller.page!.round() + delta;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: DiaryMotion.duration(context, DiaryMotion.standard),
        curve: DiaryMotion.curve(context, Curves.easeOutCubic),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final hasMultiple = widget.imagePaths.length > 1;
    return Scaffold(
      key: const Key('diary-image-viewer'),
      backgroundColor: colors.hero,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              key: const Key('diary-image-pager'),
              controller: _controller,
              onPageChanged: (page) => setState(() {
                _activePage = page;
                _currentIndex = page % widget.imagePaths.length;
              }),
              itemBuilder: (context, page) {
                final index = page % widget.imagePaths.length;
                final preview = DiaryZoomableImage(
                  key: ValueKey('diary-image-page-$page'),
                  path: widget.imagePaths[index],
                  onTapOutsideImage: () => Navigator.maybePop(context),
                );
                return Semantics(
                  image: true,
                  label: '第 ${index + 1} 张图片，共 ${widget.imagePaths.length} 张',
                  child: Center(
                    child: page == _activePage
                        ? Hero(
                            tag: diaryImageHeroTag(
                              widget.entryId,
                              index,
                              scope: widget.heroScope,
                            ),
                            child: preview,
                          )
                        : preview,
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: '关闭图片预览',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: colors.hero.withValues(alpha: .58),
                  foregroundColor: colors.onHero,
                ),
                icon: const Icon(Icons.close),
              ),
            ),
            if (hasMultiple)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '上一张',
                      onPressed: () => _changePage(-1),
                      color: colors.onHero,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_currentIndex + 1} / ${widget.imagePaths.length}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.onHero),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '下一张',
                      onPressed: () => _changePage(1),
                      color: colors.onHero,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DiaryZoomableImage extends StatefulWidget {
  const DiaryZoomableImage({
    required this.path,
    required this.onTapOutsideImage,
    super.key,
  });

  final String path;
  final VoidCallback onTapOutsideImage;

  @override
  State<DiaryZoomableImage> createState() => _DiaryZoomableImageState();
}

class _DiaryZoomableImageState extends State<DiaryZoomableImage> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Size? _imageSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant DiaryZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _resolveImageSize();
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    super.dispose();
  }

  void _resolveImageSize() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageSize = null;
    final stream = FileImage(
      File(widget.path),
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (image, _) {
        if (!mounted) return;
        setState(
          () => _imageSize = Size(
            image.image.width.toDouble(),
            image.image.height.toDouble(),
          ),
        );
      },
      onError: (_, _) {
        if (mounted) setState(() => _imageSize = null);
      },
    );
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  Rect? _imageRect(BoxConstraints constraints) {
    final imageSize = _imageSize;
    if (imageSize == null ||
        imageSize.isEmpty ||
        !constraints.hasBoundedWidth ||
        !constraints.hasBoundedHeight) {
      return null;
    }
    final viewport = constraints.biggest;
    final fitted = applyBoxFit(BoxFit.contain, imageSize, viewport);
    return Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & viewport,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageRect = _imageRect(constraints);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            if (imageRect == null ||
                !imageRect.contains(details.localPosition)) {
              widget.onTapOutsideImage();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: InteractiveViewer(
              minScale: 0.9,
              maxScale: 4,
              child: SizedBox.expand(
                child: LocalMediaPreview(
                  path: widget.path,
                  kind: DiaryMediaKind.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
