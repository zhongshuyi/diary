import 'dart:io';

import 'package:flutter/material.dart';

import 'media_kind.dart';

class LocalMediaPreview extends StatefulWidget {
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
  State<LocalMediaPreview> createState() => _LocalMediaPreviewState();
}

class _LocalMediaPreviewState extends State<LocalMediaPreview> {
  int _reloadToken = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.kind != DiaryMediaKind.image) {
      return _MediaPlaceholder(kind: widget.kind);
    }
    return Image.file(
      File(widget.path),
      key: ValueKey(_reloadToken),
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      errorBuilder: (context, error, stackTrace) => _MediaPlaceholder(
        kind: widget.kind,
        missing: true,
        showRetry: widget.showRetry,
        onRetry: () => setState(() => _reloadToken++),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.kind,
    this.missing = false,
    this.showRetry = false,
    this.onRetry,
  });

  final DiaryMediaKind kind;
  final bool missing;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 72 || constraints.maxWidth < 80;
          final iconColor = Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: missing ? .55 : 1);
          if (compact) {
            return Tooltip(
              message: missing ? '文件不可用' : diaryMediaKindLabel(kind),
              child: Center(
                child: Icon(_iconForKind(kind), size: 24, color: iconColor),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForKind(kind), size: 30, color: iconColor),
                if (missing) ...[
                  const SizedBox(height: 6),
                  Text('文件不可用', style: Theme.of(context).textTheme.labelSmall),
                  if (showRetry)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '重新加载',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                    ),
                ],
              ],
            ),
          );
        },
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
