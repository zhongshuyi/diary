import 'package:flutter/material.dart';

import 'diary_image_viewer.dart';
import 'local_media_preview.dart';

class SelectedPhotoStrip extends StatelessWidget {
  const SelectedPhotoStrip({
    required this.paths,
    required this.onRemove,
    this.keyPrefix = 'selected-photo',
    super.key,
  });

  final List<String> paths;
  final ValueChanged<String> onRemove;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已选 ${paths.length} 张',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 4, right: 4),
            itemCount: paths.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final path = paths[index];
              final thumbnailCacheSize =
                  (88 * MediaQuery.devicePixelRatioOf(context)).round();
              return SizedBox(
                width: 88,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: InkWell(
                        key: Key('$keyPrefix-preview-$index'),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => _PhotoViewer(
                            paths: List.of(paths),
                            initialIndex: index,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LocalMediaPreview(
                            path: path,
                            kind: DiaryMediaKind.image,
                            cacheWidth: thumbnailCacheSize,
                            cacheHeight: thumbnailCacheSize,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      bottom: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .65),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton.filledTonal(
                        tooltip: '移除第 ${index + 1} 张照片',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => onRemove(path),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.paths, required this.initialIndex});

  final List<String> paths;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.initialIndex;
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '关闭照片预览',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  '${_index + 1} / ${widget.paths.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: PageView.builder(
                key: const Key('selected-photo-pages'),
                controller: _pageController,
                itemCount: widget.paths.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => DiaryZoomableImage(
                  path: widget.paths[index],
                  onTapOutsideImage: () => Navigator.maybePop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
