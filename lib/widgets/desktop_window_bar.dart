import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diary/app/app_theme.dart';

/// Flutter-rendered title bar used by the Windows app. The native runner only
/// supplies the window frame and commands; all visual states stay in Flutter.
class DesktopWindowBar extends StatelessWidget {
  const DesktopWindowBar({
    required this.title,
    required this.isDark,
    required this.onToggleTheme,
    this.onBack,
    this.onNewEntry,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback? onBack;
  final VoidCallback? onNewEntry;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SizedBox(
      key: const Key('desktop-window-bar'),
      height: 62,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _DesktopWindowCommands.beginDrag(),
        onDoubleTap: _DesktopWindowCommands.toggleMaximize,
        child: ColoredBox(
          color: colors.surface,
          child: Row(
            children: [
              const SizedBox(width: 14),
              if (onBack != null)
                IconButton(
                  tooltip: '返回',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.hero,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, size: 17, color: colors.onHero),
              ),
              const SizedBox(width: 10),
              Text('此刻', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                '/ $title',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
              ),
              const Spacer(),
              ...actions,
              if (onNewEntry != null) ...[
                FilledButton.icon(
                  onPressed: onNewEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建日记'),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
                onPressed: onToggleTheme,
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
              _WindowButton(
                tooltip: '最小化',
                icon: Icons.remove,
                onPressed: _DesktopWindowCommands.minimize,
              ),
              _WindowButton(
                tooltip: '最大化或还原',
                icon: Icons.crop_square,
                onPressed: _DesktopWindowCommands.toggleMaximize,
              ),
              _WindowButton(
                tooltip: '关闭',
                icon: Icons.close,
                close: true,
                onPressed: _DesktopWindowCommands.close,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.close = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool close;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: close ? colors.terracotta : colors.ink,
      hoverColor: close ? colors.terracottaSoft : colors.line,
      icon: Icon(icon, size: 17),
    );
  }
}

class _DesktopWindowCommands {
  static const _channel = MethodChannel('diary/window');

  static void minimize() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(_channel.invokeMethod<void>('minimizeWindow'));
    }
  }

  static void toggleMaximize() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(_channel.invokeMethod<void>('toggleMaximizeWindow'));
    }
  }

  static void beginDrag() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(_channel.invokeMethod<void>('startWindowDrag'));
    }
  }

  static void close() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(_channel.invokeMethod<void>('closeWindow'));
    }
  }
}
