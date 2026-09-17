import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/widgets/local_media_preview.dart';

Future<void> showDiaryImageViewer(
  BuildContext context, {
  required List<String> imagePaths,
  required int initialIndex,
}) {
  if (imagePaths.isEmpty) return Future.value();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          DiaryImageViewer(imagePaths: imagePaths, initialIndex: initialIndex),
    ),
  );
}

class DiaryImageThumbnail extends StatelessWidget {
  const DiaryImageThumbnail({
    required this.entryId,
    required this.imagePaths,
    required this.index,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.expand = false,
    super.key,
  }) : assert(expand || (width != null && height != null));

  final String entryId;
  final List<String> imagePaths;
  final int index;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool expand;

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
          imagePaths: imagePaths,
          initialIndex: index,
        ),
        child: expand
            ? SizedBox.expand(child: _imagePreview())
            : SizedBox(width: width, height: height, child: _imagePreview()),
      ),
    );
  }

  Widget _imagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: LocalMediaPreview(
        path: imagePaths[index],
        kind: DiaryMediaKind.image,
      ),
    );
  }
}

class DiaryImageGallery extends StatelessWidget {
  const DiaryImageGallery({
    required this.entryId,
    required this.imagePaths,
    this.maxGridHeight = 260,
    super.key,
  });

  final String entryId;
  final List<String> imagePaths;
  final double maxGridHeight;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();
    final colors = DiaryThemeColors.of(context);
    final isSingleImage = imagePaths.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    required this.imagePaths,
    required this.initialIndex,
    super.key,
  });

  final List<String> imagePaths;
  final int initialIndex;

  @override
  State<DiaryImageViewer> createState() => _DiaryImageViewerState();
}

class _DiaryImageViewerState extends State<DiaryImageViewer> {
  static const _loopStart = 1000;
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    final initialPage = widget.imagePaths.length > 1
        ? (_loopStart * widget.imagePaths.length) + _currentIndex
        : 0;
    _controller = PageController(initialPage: initialPage);
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
              onPageChanged: (page) => setState(
                () => _currentIndex = page % widget.imagePaths.length,
              ),
              itemBuilder: (context, page) {
                final index = page % widget.imagePaths.length;
                return Semantics(
                  image: true,
                  label: '第 ${index + 1} 张图片，共 ${widget.imagePaths.length} 张',
                  child: Center(
                    child: LocalMediaPreview(
                      path: widget.imagePaths[index],
                      kind: DiaryMediaKind.image,
                      fit: BoxFit.contain,
                    ),
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
