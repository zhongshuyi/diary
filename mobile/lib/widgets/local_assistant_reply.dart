import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/local_assistant_controller.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_chat_appearance.dart';

/// A device-only response attached to an entry without modifying its content.
class LocalAssistantReply extends StatefulWidget {
  const LocalAssistantReply({
    required this.entryId,
    required this.controller,
    this.chatStyle = DiaryChatStyle.diary,
    this.showAvatar = false,
    this.companionAvatarPath,
    this.companionName = diaryDefaultCompanionName,
    this.onAvatarTap,
    super.key,
  });

  final String entryId;
  final LocalAssistantController controller;
  final DiaryChatStyle chatStyle;
  final bool showAvatar;
  final String? companionAvatarPath;
  final String companionName;
  final VoidCallback? onAvatarTap;

  @override
  State<LocalAssistantReply> createState() => _LocalAssistantReplyState();
}

class _LocalAssistantReplyState extends State<LocalAssistantReply> {
  late (String?, String?, bool) _reply;

  (String?, String?, bool) _readReply() {
    final controller = widget.controller;
    final id = widget.entryId;
    return (
      controller.replyFor(id),
      controller.replyErrorFor(id),
      controller.replyingEntryId == id &&
          (controller.loading || controller.generating),
    );
  }

  @override
  void initState() {
    super.initState();
    _reply = _readReply();
    widget.controller.addListener(_onReplyChanged);
  }

  @override
  void didUpdateWidget(covariant LocalAssistantReply oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onReplyChanged);
      widget.controller.addListener(_onReplyChanged);
    }
    _reply = _readReply();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onReplyChanged);
    super.dispose();
  }

  void _onReplyChanged() {
    final reply = _readReply();
    if (reply != _reply) setState(() => _reply = reply);
  }

  @override
  Widget build(BuildContext context) {
    final (text, failure, isResponding) = _reply;
    final hasText = text != null && text.isNotEmpty;
    if (!hasText && !isResponding && failure == null) {
      return const SizedBox.shrink();
    }
    final entryId = widget.entryId;
    final chatStyle = widget.chatStyle;
    final avatar = widget.showAvatar
        ? DiaryChatParticipantAvatar(
            key: ValueKey('chat-companion-avatar-$entryId'),
            style: chatStyle,
            imagePath: widget.companionAvatarPath,
            companion: true,
            size: chatStyle == DiaryChatStyle.diary ? 24 : 40,
            onTap: widget.onAvatarTap,
            semanticLabel: '打开陪伴外观设置',
          )
        : null;
    final colors = DiaryThemeColors.of(context);
    final appearance = DiaryChatAppearance.of(context, chatStyle);
    final bubble = RepaintBoundary(
      child: Material(
        key: ValueKey('assistant-reply-bubble-$entryId'),
        color: appearance.incomingColor,
        shape: chatStyle == DiaryChatStyle.diary
            ? RoundedRectangleBorder(
                side: BorderSide(color: colors.line),
                borderRadius: BorderRadius.circular(16),
              )
            : appearance.bubbleShape(outgoing: false),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chatStyle == DiaryChatStyle.diary)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child:
                      avatar ??
                      Icon(
                        Icons.spa_outlined,
                        size: 17,
                        color: colors.terracotta,
                      ),
                ),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasText || isResponding)
                      Text(
                        hasText ? text : '正在轻声回应…',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appearance.incomingTextColor,
                          height: 1.5,
                        ),
                      ),
                    if (failure != null)
                      Tooltip(
                        message: failure,
                        child: Padding(
                          padding: EdgeInsets.only(top: hasText ? 6 : 0),
                          child: Text(
                            '这次回应未完成，可在日记陪伴设置中检查模型。',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.mutedInk, height: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isResponding)
                IconButton(
                  key: ValueKey('assistant-stop-$entryId'),
                  tooltip: '停止回应',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => unawaited(widget.controller.stop()),
                  icon: Icon(
                    Icons.stop_rounded,
                    size: 18,
                    color: colors.mutedInk,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      key: ValueKey('assistant-reply-$entryId'),
      padding: const EdgeInsets.only(top: 10, right: 28, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null && chatStyle != DiaryChatStyle.diary) ...[
                avatar,
                const SizedBox(width: 8),
              ],
              Flexible(child: bubble),
            ],
          ),
        ),
      ),
    );
  }
}
