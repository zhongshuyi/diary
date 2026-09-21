import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/widgets/local_media_preview.dart';

/// The local, self-owned avatar used in the profile and outgoing chat messages.
class DiaryUserAvatar extends StatelessWidget {
  const DiaryUserAvatar({
    this.imagePath,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final String? imagePath;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  bool get _hasImage => imagePath != null && imagePath!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Semantics(
      image: true,
      label: _hasImage ? '我的头像' : '默认头像',
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor ?? colors.butter,
            shape: BoxShape.circle,
            border: Border.all(color: colors.line),
          ),
          child: ClipOval(
            child: _hasImage
                ? LocalMediaPreview(
                    key: ValueKey('user-avatar-image-$imagePath'),
                    path: imagePath!,
                    kind: DiaryMediaKind.image,
                    cacheWidth: (size * 2).round(),
                    cacheHeight: (size * 2).round(),
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: size * .52,
                    color: iconColor ?? colors.ink,
                  ),
          ),
        ),
      ),
    );
  }
}
