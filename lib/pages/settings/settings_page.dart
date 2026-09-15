import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;
        return Scaffold(
          backgroundColor: DiaryPalette.paper,
          appBar: AppBar(
            backgroundColor: DiaryPalette.paper,
            surfaceTintColor: Colors.transparent,
            title: const Text('偏好设置'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
            children: [
              Text(
                'MAKE IT YOURS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DiaryPalette.terracotta,
                ),
              ),
              const SizedBox(height: 9),
              Text('偏好设置', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                '这些设置会保存在设备上，下次打开仍然保持你的习惯。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _Section(
                title: '外观与阅读',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('主题模式'),
                    subtitle: Text(settings.themeMode.label),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: DiaryPalette.mutedInk,
                    ),
                    onTap: () => _showThemeChoice(context, settings.themeMode),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('阅读字号'),
                    subtitle: Text(
                      '${(settings.fontScale * 100).round()}% · 影响整个应用的文字大小',
                    ),
                  ),
                  Slider(
                    value: settings.fontScale,
                    min: .85,
                    max: 1.3,
                    divisions: 9,
                    label: '${(settings.fontScale * 100).round()}%',
                    onChanged: (value) =>
                        unawaited(controller.setFontScale(value)),
                  ),
                  _SwitchTile(
                    title: '显示字数',
                    subtitle: '在详情页显示这篇日记的长度',
                    value: settings.showWordCount,
                    onChanged: (value) =>
                        unawaited(controller.setShowWordCount(value)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('默认编辑方式'),
                    subtitle: Text(settings.defaultEditorType.label),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: DiaryPalette.mutedInk,
                    ),
                    onTap: () =>
                        _showEditorChoice(context, settings.defaultEditorType),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: '安全与提醒',
                children: [
                  _SwitchTile(
                    title: '生物识别锁',
                    subtitle: '打开应用或回到前台时使用系统生物识别/设备解锁',
                    value: settings.biometricLock,
                    onChanged: (value) =>
                        unawaited(controller.setBiometricLock(value)),
                  ),
                  _SwitchTile(
                    title: '每日提醒',
                    subtitle: '保留你的开关偏好，通知权限将在提醒功能接入后生效',
                    value: settings.dailyReminder,
                    onChanged: (value) =>
                        unawaited(controller.setDailyReminder(value)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: '数据',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('本地优先'),
                    subtitle: const Text('日记默认只保存在你的设备上'),
                    trailing: const Icon(
                      Icons.lock_outline,
                      color: DiaryPalette.sage,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('清理临时缓存'),
                    subtitle: const Text('不会删除你的日记和附件'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: DiaryPalette.mutedInk,
                    ),
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('临时缓存已整理'))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showThemeChoice(
    BuildContext context,
    DiaryThemeMode current,
  ) async {
    final value = await showModalBottomSheet<DiaryThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('主题模式')),
            for (final mode in DiaryThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == current ? Icons.check : Icons.circle_outlined,
                  color: mode == current
                      ? DiaryPalette.terracotta
                      : DiaryPalette.mutedInk,
                ),
                title: Text(mode.label),
                onTap: () => Navigator.pop(context, mode),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (value != null) unawaited(controller.setThemeMode(value));
  }

  Future<void> _showEditorChoice(
    BuildContext context,
    DiaryEditorType current,
  ) async {
    final value = await showModalBottomSheet<DiaryEditorType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('默认编辑方式')),
            for (final type in DiaryEditorType.values)
              ListTile(
                leading: Icon(
                  type == current ? Icons.check : Icons.circle_outlined,
                  color: type == current
                      ? DiaryPalette.terracotta
                      : DiaryPalette.mutedInk,
                ),
                title: Text(type.label),
                onTap: () => Navigator.pop(context, type),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (value != null) unawaited(controller.setDefaultEditorType(value));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 17, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: DiaryPalette.terracotta),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
