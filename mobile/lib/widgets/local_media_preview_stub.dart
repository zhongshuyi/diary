import 'package:flutter/material.dart';

import 'media_kind.dart';

class LocalMediaPreview extends StatelessWidget {
  const LocalMediaPreview({
    required this.path,
    required this.kind,
    this.showRetry = false,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    super.key,
  });

  final String path;
  final DiaryMediaKind kind;
  final bool showRetry;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    return _MediaPlaceholder(kind: kind, showRetry: showRetry);
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.kind, required this.showRetry});

  final DiaryMediaKind kind;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: showRetry
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconForKind(kind), size: 30),
                  const SizedBox(height: 6),
                  Text('文件不可用', style: Theme.of(context).textTheme.labelSmall),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: '重新加载',
                    onPressed: () {},
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ],
              )
            : Tooltip(
                message: diaryMediaKindLabel(kind),
                child: Icon(_iconForKind(kind), size: 24),
              ),
      ),
    );
  }
}

IconData _iconForKind(DiaryMediaKind kind) {
  switch (kind) {
    case DiaryMediaKind.image:
      return Icons.image_outlined;
    case DiaryMediaKind.audio:
      return Icons.graphic_eq;
    case DiaryMediaKind.video:
      return Icons.movie_outlined;
    case DiaryMediaKind.file:
      return Icons.insert_drive_file_outlined;
  }
}
