import 'dart:io';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

/// A consistent local-image avatar for profile and conversation surfaces.
///
/// When [onTap] is supplied, the avatar itself is the edit target and carries
/// a compact camera indicator instead of requiring a separate action row.
class DiaryAvatar extends StatelessWidget {
  const DiaryAvatar({
    super.key,
    this.imagePath,
    required this.size,
    this.onTap,
    this.editIndicatorKey,
    this.semanticLabel,
  });

  final String? imagePath;
  final double size;
  final VoidCallback? onTap;
  final Key? editIndicatorKey;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final path = imagePath?.trim();
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.butter,
      foregroundColor: colors.ink,
      child: ClipOval(
        child: SizedBox.expand(
          child: path == null || path.isEmpty
              ? Icon(Icons.person_outline, size: size * .44)
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.person_outline, size: size * .44),
                ),
        ),
      ),
    );

    if (onTap == null) {
      return SizedBox(width: size, height: size, child: avatar);
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? '编辑头像',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: avatar,
                ),
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: IgnorePointer(
                child: Container(
                  key: editIndicatorKey,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.terracotta,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 13,
                    color:
                        ThemeData.estimateBrightnessForColor(
                              colors.terracotta,
                            ) ==
                            Brightness.dark
                        ? colors.surface
                        : colors.hero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
