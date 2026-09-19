import 'package:flutter/material.dart';

import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/local_media_preview.dart';

/// Draws a readable photo backdrop without making the conversation itself a
/// surface. The image is deliberately low-opacity: diary messages must remain
/// more important than decoration.
class DiaryChatBackgroundLayer extends StatelessWidget {
  const DiaryChatBackgroundLayer({
    required this.background,
    required this.fallbackColor,
    required this.child,
    this.imageKey,
    super.key,
  });

  final DiaryChatBackground background;
  final Color fallbackColor;
  final Widget child;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fallbackColor),
        if (background.hasImage)
          IgnorePointer(
            child: Opacity(
              opacity: background.opacity,
              child: ClipRect(
                child: Transform.scale(
                  scale: background.scale,
                  alignment: Alignment(
                    background.alignmentX,
                    background.alignmentY,
                  ),
                  child: LocalMediaPreview(
                    key: imageKey,
                    path: background.imagePath!,
                    kind: DiaryMediaKind.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
