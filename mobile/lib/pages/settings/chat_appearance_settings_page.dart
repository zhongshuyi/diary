import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_chat_appearance.dart';

class ChatAppearanceSettingsPage extends StatefulWidget {
  const ChatAppearanceSettingsPage({
    required this.controller,
    this.onPickOwnAvatar,
    this.onClearOwnAvatar,
    this.onPickCompanionAvatar,
    this.onClearCompanionAvatar,
    super.key,
  });

  final SettingsController controller;
  final Future<void> Function()? onPickOwnAvatar;
  final Future<void> Function()? onClearOwnAvatar;
  final Future<void> Function()? onPickCompanionAvatar;
  final Future<void> Function()? onClearCompanionAvatar;

  @override
  State<ChatAppearanceSettingsPage> createState() =>
      _ChatAppearanceSettingsPageState();
}

class _ChatAppearanceSettingsPageState
    extends State<ChatAppearanceSettingsPage> {
  bool _changingAvatar = false;

  Future<void> _changeAvatar(Future<void> Function()? callback) async {
    if (callback == null || _changingAvatar) return;
    setState(() => _changingAvatar = true);
    try {
      await callback();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('头像更新失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _changingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final settings = widget.controller.settings;
        final colors = DiaryThemeColors.of(context);
        final ownAvatar = _AvatarCard(
          key: const Key('chat-appearance-own-avatar'),
          title: '我的头像',
          style: settings.chatStyle,
          imagePath: settings.profileAvatarPath,
          onPick: widget.onPickOwnAvatar == null || _changingAvatar
              ? null
              : () => unawaited(_changeAvatar(widget.onPickOwnAvatar)),
          onClear: widget.onClearOwnAvatar == null || _changingAvatar
              ? null
              : () => unawaited(_changeAvatar(widget.onClearOwnAvatar)),
        );
        final companionAvatar = _AvatarCard(
          key: const Key('chat-appearance-companion-avatar'),
          title: '陪伴者头像',
          style: settings.chatStyle,
          imagePath: settings.companionAvatarPath,
          companion: true,
          onPick: widget.onPickCompanionAvatar == null || _changingAvatar
              ? null
              : () => unawaited(_changeAvatar(widget.onPickCompanionAvatar)),
          onClear: widget.onClearCompanionAvatar == null || _changingAvatar
              ? null
              : () => unawaited(_changeAvatar(widget.onClearCompanionAvatar)),
        );

        return Scaffold(
          backgroundColor: colors.paper,
          appBar: AppBar(
            backgroundColor: colors.paper,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: const Text('对话外观'),
          ),
          body: ListView(
            key: const Key('chat-appearance-list'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                '选择喜欢的布局和头像。配色沿用当前主题，背景沿用已设置的对话背景。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.mutedInk,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle('对话布局'),
              for (final style in DiaryChatStyle.values) ...[
                _StyleCard(
                  style: style,
                  settings: settings,
                  onTap: () => unawaited(widget.controller.setChatStyle(style)),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              const _SectionTitle('双方头像'),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 420) {
                    return Column(
                      children: [
                        ownAvatar,
                        const SizedBox(height: 12),
                        companionAvatar,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ownAvatar),
                      const SizedBox(width: 12),
                      Expanded(child: companionAvatar),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _SurfaceCard(
                child: SwitchListTile.adaptive(
                  key: const Key('chat-appearance-show-avatars'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  title: const Text('对话显示头像'),
                  subtitle: const Text('在日记和陪伴回应旁显示双方头像'),
                  value: settings.showChatAvatar,
                  onChanged: (value) =>
                      unawaited(widget.controller.setShowChatAvatar(value)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: DiaryThemeColors.of(context).ink,
      ),
    ),
  );
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.settings,
    required this.onTap,
  });

  final DiaryChatStyle style;
  final DiarySettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final selected = style == settings.chatStyle;
    return Semantics(
      button: true,
      selected: selected,
      label: '${style.label}，${selected ? '已选择' : '选择此布局'}',
      child: Material(
        key: Key('chat-appearance-style-${style.name}'),
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? colors.terracotta : colors.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        style.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: selected
                          ? Key('chat-appearance-selected-${style.name}')
                          : null,
                      color: selected ? colors.terracotta : colors.mutedInk,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  style.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedInk,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                DiaryChatAppearancePreview(
                  style: style,
                  title: settings.chatTitle,
                  background: settings.chatBackground,
                  showAvatars: settings.showChatAvatar,
                  selfAvatarPath: settings.profileAvatarPath,
                  companionAvatarPath: settings.companionAvatarPath,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.title,
    required this.style,
    this.imagePath,
    this.companion = false,
    this.onPick,
    this.onClear,
    super.key,
  });

  final String title;
  final DiaryChatStyle style;
  final String? imagePath;
  final bool companion;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return _SurfaceCard(
      child: InkWell(
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              DiaryChatParticipantAvatar(
                imagePath: imagePath,
                style: style,
                companion: companion,
                size: 48,
                semanticLabel: title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      imagePath == null ? '默认头像 · 点按更换' : '自定义头像 · 点按更换',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                key: Key(
                  companion
                      ? 'chat-appearance-companion-avatar-menu'
                      : 'chat-appearance-own-avatar-menu',
                ),
                tooltip: '$title选项',
                onSelected: (value) {
                  if (value == 'pick') onPick?.call();
                  if (value == 'clear') onClear?.call();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pick',
                    enabled: onPick != null,
                    child: const Text('更换头像'),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    enabled: onClear != null && imagePath != null,
                    child: const Text('恢复默认头像'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
