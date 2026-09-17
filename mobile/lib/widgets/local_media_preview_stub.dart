import 'package:flutter/material.dart';

import 'media_kind.dart';

class LocalMediaPreview extends StatelessWidget {
  const LocalMediaPreview({
    required this.path,
    required this.kind,
    this.showRetry = false,
    super.key,
  });

  final String path;
  final DiaryMediaKind kind;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return _MediaPlaceholder(kind: kind);
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.kind});

  final DiaryMediaKind kind;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(_iconForKind(kind), size: 30)),
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
