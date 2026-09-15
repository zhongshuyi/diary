import 'dart:io';

import 'package:flutter/material.dart';

import 'media_kind.dart';

class LocalMediaPreview extends StatelessWidget {
  const LocalMediaPreview({required this.path, required this.kind, super.key});

  final String path;
  final DiaryMediaKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind != DiaryMediaKind.image) {
      return _MediaPlaceholder(kind: kind);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _MediaPlaceholder(kind: kind, missing: true),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.kind, this.missing = false});

  final DiaryMediaKind kind;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          _iconForKind(kind),
          size: 30,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: missing ? .55 : 1),
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
