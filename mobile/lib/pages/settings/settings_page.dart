import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.controller,
    this.onOpenCategories,
    this.onOpenBackup,
    this.onOpenAbout,
    super.key,
  });

  final SettingsController controller;
  final VoidCallback? onOpenCategories;
  final VoidCallback? onOpenBackup;
  final VoidCallback? onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colors = DiaryThemeColors.of(context);
        final settings = controller.settings;
        return Scaffold(
          backgroundColor: colors.paper,
          appBar: AppBar(
            backgroundColor: colors.paper,
            surfaceTintColor: Colors.transparent,
            title: const Text('偏好设置'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
            children: [
              Text(
                'MAKE IT YOURS',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
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
                  _SettingsTile(
                    title: const Text('主题模式'),
                    subtitle: Text(settings.themeMode.label),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _showThemeChoice(context, settings.themeMode),
                  ),
                  _SettingsTile(
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
                  _SettingsTile(
                    title: const Text('默认编辑方式'),
                    subtitle: Text(settings.defaultEditorType.label),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () =>
                        _showEditorChoice(context, settings.defaultEditorType),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: '操作习惯',
                children: [
                  const _SettingsTile(
                    title: Text('速记按钮位置'),
                    subtitle: Text('选择更顺手的一侧，切换后立即生效'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: SegmentedButton<QuickCaptureSide>(
                      segments: const [
                        ButtonSegment(
                          value: QuickCaptureSide.left,
                          label: Text('左侧'),
                        ),
                        ButtonSegment(
                          value: QuickCaptureSide.right,
                          label: Text('右侧'),
                        ),
                      ],
                      selected: {settings.quickCaptureSide},
                      onSelectionChanged: (value) => unawaited(
                        controller.setQuickCaptureSide(value.single),
                      ),
                    ),
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
                  _SettingsTile(
                    title: const Text('本地优先'),
                    subtitle: const Text('日记默认只保存在你的设备上'),
                    trailing: Icon(Icons.lock_outline, color: colors.sage),
                  ),
                  _SettingsTile(
                    title: const Text('清理临时缓存'),
                    subtitle: const Text('不会删除你的日记和附件'),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('临时缓存已整理'))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SyncSettings(controller: controller),
              if (onOpenCategories != null ||
                  onOpenBackup != null ||
                  onOpenAbout != null) ...[
                const SizedBox(height: 12),
                _Section(
                  title: '应用工具',
                  children: [
                    if (onOpenCategories != null)
                      _SettingsTile(
                        leading: const Icon(Icons.sell_outlined),
                        title: const Text('分类与标签'),
                        subtitle: const Text('整理你常写下的主题'),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.mutedInk,
                        ),
                        onTap: onOpenCategories,
                      ),
                    if (onOpenBackup != null)
                      _SettingsTile(
                        leading: const Icon(Icons.import_export_outlined),
                        title: const Text('备份与恢复'),
                        subtitle: const Text('用 JSON 保存或迁移你的日记'),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.mutedInk,
                        ),
                        onTap: onOpenBackup,
                      ),
                    if (onOpenAbout != null)
                      _SettingsTile(
                        leading: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('关于此刻'),
                        subtitle: const Text('版本、设计理念与隐私说明'),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.mutedInk,
                        ),
                        onTap: onOpenAbout,
                      ),
                  ],
                ),
              ],
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
      builder: (context) {
        final colors = DiaryThemeColors.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('主题模式')),
              for (final mode in DiaryThemeMode.values)
                _SettingsTile(
                  leading: Icon(
                    mode == current ? Icons.check : Icons.circle_outlined,
                    color: mode == current
                        ? colors.terracotta
                        : colors.mutedInk,
                  ),
                  title: Text(mode.label),
                  onTap: () => Navigator.pop(context, mode),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (value != null) unawaited(controller.setThemeMode(value));
  }

  Future<void> _showEditorChoice(
    BuildContext context,
    DiaryEditorType current,
  ) async {
    final value = await showModalBottomSheet<DiaryEditorType>(
      context: context,
      builder: (context) {
        final colors = DiaryThemeColors.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('默认编辑方式')),
              for (final type in DiaryEditorType.values)
                _SettingsTile(
                  leading: Icon(
                    type == current ? Icons.check : Icons.circle_outlined,
                    color: type == current
                        ? colors.terracotta
                        : colors.mutedInk,
                  ),
                  title: Text(type.label),
                  onTap: () => Navigator.pop(context, type),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (value != null) unawaited(controller.setDefaultEditorType(value));
  }
}

class _SyncSettings extends StatefulWidget {
  const _SyncSettings({required this.controller});
  final SettingsController controller;

  @override
  State<_SyncSettings> createState() => _SyncSettingsState();
}

class _SyncSettingsState extends State<_SyncSettings> {
  late final TextEditingController _endpoint;
  late final TextEditingController _token;

  @override
  void initState() {
    super.initState();
    _endpoint = TextEditingController(
      text: widget.controller.settings.syncEndpoint,
    );
    _token = TextEditingController(text: widget.controller.settings.syncToken);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return _Section(
      title: '双端同步',
      children: [
        Text(
          '连接你自己的同步服务器；留空即可保持纯本地模式。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _endpoint,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '服务器地址',
            hintText: 'http://127.0.0.1:8787',
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _token,
          obscureText: true,
          decoration: const InputDecoration(labelText: '访问令牌（可选）'),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () async {
              await widget.controller.setSyncEndpoint(_endpoint.text);
              await widget.controller.setSyncToken(_token.text);
              if (context.mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('同步设置已保存')));
            },
            icon: Icon(Icons.save_outlined, color: colors.terracotta),
            label: const Text('保存连接'),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
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
              ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
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
    return _SettingsTile(
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: colors.paper,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          tileColor: Colors.transparent,
          splashColor: colors.terracotta.withValues(alpha: .12),
          hoverColor: colors.terracotta.withValues(alpha: .06),
          focusColor: colors.terracotta.withValues(alpha: .08),
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
