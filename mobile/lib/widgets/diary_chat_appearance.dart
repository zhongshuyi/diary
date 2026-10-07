import 'dart:io';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_chat_background.dart';

class DiaryChatAppearance {
  const DiaryChatAppearance({
    required this.style,
    required this.backgroundColor,
    required this.outgoingColor,
    required this.incomingColor,
    required this.outgoingTextColor,
    required this.incomingTextColor,
    required this.outgoingVoiceColor,
  });

  factory DiaryChatAppearance.of(BuildContext context, DiaryChatStyle style) {
    final colors = DiaryThemeColors.of(context);
    return DiaryChatAppearance(
      style: style,
      backgroundColor: colors.paper,
      outgoingColor: Color.lerp(colors.terracottaSoft, colors.terracotta, .12)!,
      incomingColor: colors.surface,
      outgoingTextColor: colors.ink,
      incomingTextColor: colors.ink,
      outgoingVoiceColor: colors.terracotta,
    );
  }

  final DiaryChatStyle style;
  final Color backgroundColor;
  final Color outgoingColor;
  final Color incomingColor;
  final Color outgoingTextColor;
  final Color incomingTextColor;
  final Color outgoingVoiceColor;

  ShapeBorder bubbleShape({required bool outgoing}) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(switch (style) {
      DiaryChatStyle.diary => 18,
      DiaryChatStyle.messenger => 14,
      DiaryChatStyle.soft => 25,
    }),
  );
}

/// Both participants use thumbnail decoding and identical tap targets.
class DiaryChatParticipantAvatar extends StatelessWidget {
  const DiaryChatParticipantAvatar({
    required this.style,
    this.imagePath,
    this.size = 40,
    this.onTap,
    this.semanticLabel,
    this.companion = false,
    super.key,
  });

  final DiaryChatStyle style;
  final String? imagePath;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool companion;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final radius = BorderRadius.circular(
      style == DiaryChatStyle.messenger ? 11 : size / 2,
    );
    final path = imagePath?.trim();
    final fallback = Icon(
      companion ? Icons.face_outlined : Icons.person_outline,
      size: size * .45,
      color: colors.ink,
    );
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(48, 192);
    return Semantics(
      image: true,
      button: onTap != null,
      label: semanticLabel ?? (companion ? '陪伴头像' : '我的头像'),
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: companion ? colors.sage : colors.butter,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: path == null || path.isEmpty
                ? fallback
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    cacheWidth: decodeSize,
                    cacheHeight: decodeSize,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}

/// A static sample, using the same bubble shapes and avatars as the chat page.
class DiaryChatAppearancePreview extends StatelessWidget {
  const DiaryChatAppearancePreview({
    required this.style,
    this.showAvatars = true,
    this.selfAvatarPath,
    this.companionAvatarPath,
    this.companionName = diaryDefaultCompanionName,
    this.title = diaryDefaultChatTitle,
    this.background = const DiaryChatBackground(),
    this.onSelfAvatarTap,
    this.onCompanionAvatarTap,
    super.key,
  });

  final DiaryChatStyle style;
  final bool showAvatars;
  final String? selfAvatarPath;
  final String? companionAvatarPath;
  final String companionName;
  final String title;
  final DiaryChatBackground background;
  final VoidCallback? onSelfAvatarTap;
  final VoidCallback? onCompanionAvatarTap;

  @override
  Widget build(BuildContext context) {
    final appearance = DiaryChatAppearance.of(context, style);
    final conversation = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          key: Key('chat-appearance-preview-title-${style.name}'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: appearance.incomingTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 22),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: appearance.outgoingColor,
                  shape: appearance.bubbleShape(outgoing: true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Text(
                      '今天有些疲惫，但也完成了一件小事。',
                      style: TextStyle(
                        color: appearance.outgoingTextColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (showAvatars) ...[
              const SizedBox(width: 8),
              DiaryChatParticipantAvatar(
                style: style,
                imagePath: selfAvatarPath,
                size: 34,
                onTap: onSelfAvatarTap,
                semanticLabel: '预览我的头像',
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatars && style != DiaryChatStyle.diary) ...[
              DiaryChatParticipantAvatar(
                style: style,
                imagePath: companionAvatarPath,
                size: 34,
                companion: true,
                onTap: onCompanionAvatarTap,
                semanticLabel: '预览陪伴头像',
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: appearance.incomingColor,
                    shape: appearance.bubbleShape(outgoing: false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showAvatars && style == DiaryChatStyle.diary) ...[
                            DiaryChatParticipantAvatar(
                              style: style,
                              imagePath: companionAvatarPath,
                              companion: true,
                              size: 24,
                              onTap: onCompanionAvatarTap,
                              semanticLabel: '预览陪伴头像',
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              '已经很努力了，给自己一点休息吧。',
                              style: TextStyle(
                                color: appearance.incomingTextColor,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: DiaryChatBackgroundLayer(
              background: background,
              fallbackColor: appearance.backgroundColor,
              child: const SizedBox.expand(),
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: conversation),
        ],
      ),
    );
  }
}
