import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/domain/connection_settings_transfer.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_chat_background.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.controller,
    this.onOpenCategories,
    this.onOpenBackup,
    this.onOpenAbout,
    this.onImportPhotos,
    this.pickChatBackgroundPhoto,
    super.key,
  });

  final SettingsController controller;
  final VoidCallback? onOpenCategories;
  final VoidCallback? onOpenBackup;
  final VoidCallback? onOpenAbout;
  final Future<List<String>> Function(List<String> paths)? onImportPhotos;
  final Future<List<String>> Function()? pickChatBackgroundPhoto;

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
            centerTitle: true,
            title: const Text('设置'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
            children: [
              Text(
                '在这里调整阅读、记录和同步习惯。所有偏好都会保存在这台设备上。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
              ),
              const SizedBox(height: 18),
              _Section(
                title: '外观',
                children: [
                  _SettingsTile(
                    title: const Text('主题模式'),
                    subtitle: Text(settings.themeMode.label),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _showThemeChoice(context, settings.themeMode),
                  ),
                  _SettingsTile(
                    title: const Text('主题配色'),
                    subtitle: Text(
                      '${settings.themePreset.label} · ${settings.themePreset.description}',
                    ),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () =>
                        _showThemePresetChoice(context, settings.themePreset),
                  ),
                  _SettingsTile(
                    leading: _ThemeColorDot(
                      color: Color(
                        settings.customThemeColor ??
                            colors.terracotta.toARGB32(),
                      ),
                    ),
                    title: const Text('自定义主题色'),
                    subtitle: Text(
                      settings.customThemeColor == null
                          ? '使用当前预设的主色'
                          : '${_themeColorHex(settings.customThemeColor!)} · 已覆盖主色',
                    ),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _showCustomThemeColorPicker(
                      context,
                      currentColor: settings.customThemeColor,
                      fallbackColor: colors.terracotta,
                    ),
                  ),
                  _SettingsTile(
                    leading: Icon(
                      Icons.text_fields_rounded,
                      color: colors.terracotta,
                    ),
                    title: const Text('阅读字号'),
                    subtitle: Text('${(settings.fontScale * 100).round()}%'),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () =>
                        _showFontScalePicker(context, settings.fontScale),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: '记录与对话',
                children: [
                  _SettingsTile(
                    key: const Key('settings-chat-background'),
                    leading: Icon(
                      Icons.wallpaper_outlined,
                      color: colors.terracotta,
                    ),
                    title: const Text('聊天背景'),
                    subtitle: Text(
                      settings.chatBackground.hasImage
                          ? '已设置图片 · 可继续裁剪和调整'
                          : '使用默认暖纸底色',
                    ),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _showChatBackgroundEditor(
                      context,
                      settings.chatBackground,
                    ),
                  ),
                  _SettingsTile(
                    title: const Text('对话顶部名称'),
                    subtitle: Text(settings.chatTitle),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () =>
                        _showChatTitleEditor(context, settings.chatTitle),
                  ),
                  _SettingsTile(
                    title: const Text('默认首页'),
                    subtitle: Text(settings.defaultHomeMode.label),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _showDefaultHomeModeChoice(
                      context,
                      settings.defaultHomeMode,
                    ),
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
                  _SettingsTile(
                    key: const Key('settings-quick-capture-side'),
                    title: const Text('速记按钮位置'),
                    subtitle: Text(
                      settings.quickCaptureSide == QuickCaptureSide.right
                          ? '右侧 · 适合右手操作'
                          : '左侧',
                    ),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _showQuickCaptureSideChoice(
                      context,
                      settings.quickCaptureSide,
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
                    key: const Key('settings-sync'),
                    leading: Icon(
                      Icons.cloud_sync_outlined,
                      color: colors.sage,
                    ),
                    title: const Text('同步与更新'),
                    subtitle: Text(
                      settings.syncEndpoint.isEmpty
                          ? '本地模式 · 尚未连接服务器'
                          : '已配置同步连接',
                    ),
                    trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                    onTap: () => _openConnectionSettings(context),
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
              if (onOpenCategories != null ||
                  onOpenBackup != null ||
                  onOpenAbout != null) ...[
                const SizedBox(height: 12),
                _Section(
                  title: '管理与关于',
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

  Future<void> _showThemePresetChoice(
    BuildContext context,
    DiaryThemePreset current,
  ) async {
    final value = await showModalBottomSheet<DiaryThemePreset>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('主题配色', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '每套配色都有明亮与黑暗模式，会同时应用到时间线、对话和编辑页面。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    key: const Key('theme-preset-grid'),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 172,
                    children: [
                      for (final preset in DiaryThemePreset.values)
                        _ThemePresetTile(
                          preset: preset,
                          selected: preset == current,
                          onTap: () => Navigator.pop(context, preset),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (value != null) unawaited(controller.setThemePreset(value));
  }

  Future<void> _showCustomThemeColorPicker(
    BuildContext context, {
    required int? currentColor,
    required Color fallbackColor,
  }) async {
    final result = await showModalBottomSheet<_CustomThemeColorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ThemeColorPicker(
        initialColor: Color(currentColor ?? fallbackColor.toARGB32()),
        hasCustomColor: currentColor != null,
      ),
    );
    if (result == null) return;
    if (result.clear) {
      await controller.clearCustomThemeColor();
      return;
    }
    if (result.colorValue != null) {
      await controller.setCustomThemeColor(result.colorValue!);
    }
  }

  Future<void> _showFontScalePicker(
    BuildContext context,
    double current,
  ) async {
    final value = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FontScalePicker(initialValue: current),
    );
    if (value != null) await controller.setFontScale(value);
  }

  Future<void> _showDefaultHomeModeChoice(
    BuildContext context,
    DiaryHomeMode current,
  ) async {
    final value = await showModalBottomSheet<DiaryHomeMode>(
      context: context,
      builder: (context) => _ChoiceSheet<DiaryHomeMode>(
        title: '默认首页',
        choices: DiaryHomeMode.values,
        selected: current,
        labelFor: (value) => value.label,
        descriptionFor: (value) => switch (value) {
          DiaryHomeMode.timeline => '打开后先浏览按时间整理的日记',
          DiaryHomeMode.chat => '打开后先进入像聊天一样的记录页',
        },
      ),
    );
    if (value != null) await controller.setDefaultHomeMode(value);
  }

  Future<void> _showQuickCaptureSideChoice(
    BuildContext context,
    QuickCaptureSide current,
  ) async {
    final value = await showModalBottomSheet<QuickCaptureSide>(
      context: context,
      builder: (context) => _ChoiceSheet<QuickCaptureSide>(
        title: '速记按钮位置',
        choices: QuickCaptureSide.values,
        selected: current,
        labelFor: (value) => value == QuickCaptureSide.right ? '右侧' : '左侧',
        descriptionFor: (value) =>
            value == QuickCaptureSide.right ? '更贴合大多数右手操作习惯' : '将按钮固定在左侧',
      ),
    );
    if (value != null) await controller.setQuickCaptureSide(value);
  }

  Future<void> _openConnectionSettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ConnectionSettingsPage(controller: controller),
      ),
    );
  }

  Future<void> _showChatBackgroundEditor(
    BuildContext context,
    DiaryChatBackground initial,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ChatBackgroundEditor(
          initial: initial,
          onPickPhoto:
              pickChatBackgroundPhoto ?? () => _pickBackgroundPhoto(context),
          onImportPhotos: onImportPhotos,
          onApply: controller.setChatBackground,
        ),
      ),
    );
  }

  Future<List<String>> _pickBackgroundPhoto(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return pickDiaryPhotos(context, maxAssets: 1);
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    return image == null ? const [] : [image.path];
  }

  Future<void> _showChatTitleEditor(
    BuildContext context,
    String current,
  ) async {
    final textController = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('对话顶部名称'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLength: 16,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
          decoration: const InputDecoration(hintText: '例如：我的日记'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (value != null) await controller.setChatTitle(value);
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

class _ConnectionSettingsPage extends StatelessWidget {
  const _ConnectionSettingsPage({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('同步与更新'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            '连接信息集中在这里，日常使用时无需反复看到复杂表单。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
          ),
          const SizedBox(height: 18),
          _Section(
            title: '连接设置',
            children: [_SyncSettings(controller: controller)],
          ),
        ],
      ),
    );
  }
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.choices,
    required this.selected,
    required this.labelFor,
    required this.descriptionFor,
  });

  final String title;
  final List<T> choices;
  final T selected;
  final String Function(T value) labelFor;
  final String Function(T value) descriptionFor;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final value in choices)
              _SettingsTile(
                leading: Icon(
                  value == selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: value == selected
                      ? colors.terracotta
                      : colors.mutedInk,
                ),
                title: Text(labelFor(value)),
                subtitle: Text(descriptionFor(value)),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
  }
}

class _FontScalePicker extends StatefulWidget {
  const _FontScalePicker({required this.initialValue});

  final double initialValue;

  @override
  State<_FontScalePicker> createState() => _FontScalePickerState();
}

class _FontScalePickerState extends State<_FontScalePicker> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('阅读字号', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text('影响整个应用的文字大小。', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${(_value * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: colors.terracotta),
              ),
            ),
            Slider(
              key: const Key('settings-font-scale-slider'),
              value: _value,
              min: .85,
              max: 1.3,
              divisions: 9,
              label: '${(_value * 100).round()}%',
              onChanged: (value) => setState(() => _value = value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _value),
                child: const Text('应用字号'),
              ),
            ),
          ],
        ),
      ),
    );
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
  late final TextEditingController _updateEndpoint;

  @override
  void initState() {
    super.initState();
    _endpoint = TextEditingController(
      text: widget.controller.settings.syncEndpoint,
    );
    _token = TextEditingController(text: widget.controller.settings.syncToken);
    _updateEndpoint = TextEditingController(
      text: widget.controller.settings.updateEndpoint,
    );
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _token.dispose();
    _updateEndpoint.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyConnectionSettings() async {
    try {
      final value = ConnectionSettingsTransfer(
        syncEndpoint: _endpoint.text.trim().replaceFirst(RegExp(r'/+$'), ''),
        syncToken: _token.text.trim(),
        updateEndpoint: _updateEndpoint.text.trim().replaceFirst(
          RegExp(r'/+$'),
          '',
        ),
      ).encode();
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) _showMessage('连接配置已复制，内容包含访问令牌');
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message.toString());
    }
  }

  Future<void> _pasteConnectionSettings() async {
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      final source = clipboard?.text;
      if (source == null || source.trim().isEmpty) {
        throw const FormatException('剪贴板中没有连接配置');
      }
      final settings = ConnectionSettingsTransfer.decode(source);
      _endpoint.text = settings.syncEndpoint;
      _token.text = settings.syncToken;
      _updateEndpoint.text = settings.updateEndpoint;
      if (mounted) _showMessage('连接配置已导入，请保存连接');
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '连接你自己的同步服务器；留空即可保持纯本地模式。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _endpoint,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '服务器地址',
            hintText: 'http://127.0.0.1:8787',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _token,
          obscureText: true,
          decoration: const InputDecoration(labelText: '访问令牌（可选）'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _updateEndpoint,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '更新地址（公开）',
            hintText: 'https://updates.example.com',
            helperText: '仅用于检查更新和打开下载链接，不会发送访问令牌。',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '跨设备连接配置包含访问令牌，仅在自己的受信设备间传递。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _copyConnectionSettings,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('复制连接配置'),
            ),
            OutlinedButton.icon(
              onPressed: _pasteConnectionSettings,
              icon: const Icon(Icons.content_paste_outlined),
              label: const Text('粘贴并导入'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await widget.controller.saveConnectionSettings(
                syncEndpoint: _endpoint.text,
                syncToken: _token.text,
                updateEndpoint: _updateEndpoint.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('同步设置已保存')));
              }
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
    super.key,
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

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final DiaryThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.label}主题配色',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.terracotta : colors.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('settings-theme-preset-${preset.wireValue}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemePresetSwatch(
                  light: DiaryThemeColors.lightFor(preset),
                  dark: DiaryThemeColors.darkFor(preset),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.label,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (preset == DiaryThemePreset.warmPaper)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.terracottaSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '默认',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.ink, letterSpacing: 0),
                        ),
                      )
                    else
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: selected ? colors.terracotta : colors.mutedInk,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  preset.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedInk,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePresetSwatch extends StatelessWidget {
  const _ThemePresetSwatch({required this.light, required this.dark});

  final DiaryThemeColors light;
  final DiaryThemeColors dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 58,
        width: double.infinity,
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(child: ColoredBox(color: light.paper)),
                Expanded(child: ColoredBox(color: dark.paper)),
              ],
            ),
            Positioned(
              left: 11,
              top: 11,
              child: _SwatchSurface(
                background: light.surface,
                accent: light.terracotta,
                line: light.line,
              ),
            ),
            Positioned(
              right: 11,
              top: 11,
              child: _SwatchSurface(
                background: dark.surface,
                accent: dark.terracotta,
                line: dark.line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchSurface extends StatelessWidget {
  const _SwatchSurface({
    required this.background,
    required this.accent,
    required this.line,
  });

  final Color background;
  final Color accent;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 36,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: line),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ThemeColorDot extends StatelessWidget {
  const _ThemeColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 3),
        boxShadow: [
          BoxShadow(color: colors.ink.withValues(alpha: .12), blurRadius: 6),
        ],
      ),
    );
  }
}

class _ThemeColorPicker extends StatefulWidget {
  const _ThemeColorPicker({
    required this.initialColor,
    required this.hasCustomColor,
  });

  final Color initialColor;
  final bool hasCustomColor;

  @override
  State<_ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<_ThemeColorPicker> {
  late HSLColor _selected;

  @override
  void initState() {
    super.initState();
    _selected = HSLColor.fromColor(widget.initialColor);
  }

  Color get _color => _selected.toColor();

  void _update(HSLColor value) => setState(() => _selected = value);

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final previewBrightness = ThemeData.estimateBrightnessForColor(_color);
    final previewForeground = previewBrightness == Brightness.dark
        ? Colors.white
        : colors.ink;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('自定义主题色', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '保存后会覆盖当前主题的主强调色，浅色和深色都会自动适配。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette_outlined, color: previewForeground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '你的主题色',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: previewForeground,
                      ),
                    ),
                  ),
                  Text(
                    _themeColorHex(_color.toARGB32()),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: previewForeground,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('色相', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 7),
            _HueSlider(
              value: _selected.hue,
              onChanged: (value) => _update(_selected.withHue(value)),
            ),
            const SizedBox(height: 13),
            Text('饱和度', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              key: const Key('custom-theme-saturation-slider'),
              value: _selected.saturation,
              activeColor: _color,
              inactiveColor: colors.line,
              onChanged: (value) => _update(_selected.withSaturation(value)),
            ),
            const SizedBox(height: 8),
            Text('明度', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              key: const Key('custom-theme-lightness-slider'),
              value: _selected.lightness,
              min: .15,
              max: .85,
              activeColor: _color,
              inactiveColor: colors.line,
              onChanged: (value) => _update(_selected.withLightness(value)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.hasCustomColor)
                  TextButton(
                    key: const Key('custom-theme-reset-button'),
                    onPressed: () => Navigator.pop(
                      context,
                      const _CustomThemeColorResult(clear: true),
                    ),
                    child: const Text('恢复预设'),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('custom-theme-save-button'),
                  onPressed: () => Navigator.pop(
                    context,
                    _CustomThemeColorResult(colorValue: _color.toARGB32()),
                  ),
                  child: const Text('应用颜色'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBackgroundEditor extends StatefulWidget {
  const _ChatBackgroundEditor({
    required this.initial,
    required this.onPickPhoto,
    required this.onApply,
    this.onImportPhotos,
  });

  final DiaryChatBackground initial;
  final Future<List<String>> Function() onPickPhoto;
  final Future<List<String>> Function(List<String> paths)? onImportPhotos;
  final Future<void> Function(DiaryChatBackground value) onApply;

  @override
  State<_ChatBackgroundEditor> createState() => _ChatBackgroundEditorState();
}

class _ChatBackgroundEditorState extends State<_ChatBackgroundEditor> {
  late DiaryChatBackground _background;
  bool _isPicking = false;
  String? _error;
  DiaryChatBackground? _cropStart;
  Offset? _cropStartFocalPoint;

  @override
  void initState() {
    super.initState();
    _background = widget.initial.normalized();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final selected = await widget.onPickPhoto();
      if (selected.isEmpty) return;
      final imported = widget.onImportPhotos == null
          ? selected
          : await widget.onImportPhotos!(selected);
      if (imported.isEmpty) return;
      if (!mounted) return;
      setState(
        () => _background = DiaryChatBackground(
          imagePath: imported.first,
          scale: 1,
          alignmentX: 0,
          alignmentY: 0,
          opacity: .22,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = '暂时无法读取这张图片，请换一张再试。');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _update(DiaryChatBackground next) {
    setState(() => _background = next.normalized());
  }

  void _startCrop(ScaleStartDetails details) {
    _cropStart = _background;
    _cropStartFocalPoint = details.localFocalPoint;
  }

  void _updateCrop(ScaleUpdateDetails details, BoxConstraints constraints) {
    final start = _cropStart;
    final focalPoint = _cropStartFocalPoint;
    if (start == null || focalPoint == null) return;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width <= 0 || height <= 0) return;
    final horizontalDelta =
        (details.localFocalPoint.dx - focalPoint.dx) / width;
    final verticalDelta = (details.localFocalPoint.dy - focalPoint.dy) / height;
    _update(
      start.copyWith(
        scale: start.scale * details.scale,
        alignmentX: start.alignmentX - horizontalDelta * 2,
        alignmentY: start.alignmentY - verticalDelta * 2,
      ),
    );
  }

  void _resetCrop() {
    _update(_background.copyWith(scale: 1, alignmentX: 0, alignmentY: 0));
  }

  Future<void> _apply() async {
    await widget.onApply(_background);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('聊天背景'),
        actions: [
          TextButton(
            key: const Key('chat-background-apply'),
            onPressed: _apply,
            child: Text(
              _background.hasImage ? '应用' : '恢复默认',
              style: TextStyle(color: colors.terracotta),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: _ChatBackgroundPreview(
                background: _background,
                onScaleStart: _background.hasImage ? _startCrop : null,
                onScaleUpdate: _background.hasImage ? _updateCrop : null,
                onDoubleTap: _background.hasImage ? _resetCrop : null,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.line)),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _background.hasImage ? '调整背景' : '选择一张背景图',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _background.hasImage
                          ? '直接拖动预览调整位置，双指缩放；双击可恢复居中。'
                          : '图片会只出现在聊天消息区域，顶部和输入框保持清晰。',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('chat-background-select'),
                        onPressed: _isPicking ? null : _pickPhoto,
                        icon: _isPicking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _background.hasImage
                                    ? Icons.photo_library_outlined
                                    : Icons.add_photo_alternate_outlined,
                              ),
                        label: Text(_background.hasImage ? '更换图片' : '从相册选择图片'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.terracotta,
                        ),
                      ),
                    ],
                    if (_background.hasImage) ...[
                      const SizedBox(height: 16),
                      _BackgroundSlider(
                        key: const Key('chat-background-opacity-slider'),
                        label: '图片存在感',
                        value: _background.opacity,
                        min: .08,
                        max: .5,
                        divisions: 14,
                        onChanged: (value) =>
                            _update(_background.copyWith(opacity: value)),
                      ),
                      ExpansionTile(
                        key: const Key('chat-background-fine-tune'),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: const Text('精细调整'),
                        subtitle: Text(
                          '缩放 ${(_background.scale * 100).round()}% · 可用滑杆微调取景',
                        ),
                        children: [
                          _BackgroundSlider(
                            key: const Key('chat-background-scale-slider'),
                            label: '缩放',
                            value: _background.scale,
                            min: 1,
                            max: 2.5,
                            divisions: 15,
                            onChanged: (value) =>
                                _update(_background.copyWith(scale: value)),
                          ),
                          _BackgroundSlider(
                            key: const Key('chat-background-horizontal-slider'),
                            label: '左右位置',
                            value: _background.alignmentX,
                            min: -1,
                            max: 1,
                            divisions: 20,
                            onChanged: (value) => _update(
                              _background.copyWith(alignmentX: value),
                            ),
                          ),
                          _BackgroundSlider(
                            key: const Key('chat-background-vertical-slider'),
                            label: '上下位置',
                            value: _background.alignmentY,
                            min: -1,
                            max: 1,
                            divisions: 20,
                            onChanged: (value) => _update(
                              _background.copyWith(alignmentY: value),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        key: const Key('chat-background-remove'),
                        onPressed: () => _update(const DiaryChatBackground()),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('移除背景图片'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBackgroundPreview extends StatelessWidget {
  const _ChatBackgroundPreview({
    required this.background,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onDoubleTap,
  });

  final DiaryChatBackground background;
  final ValueChanged<ScaleStartDetails>? onScaleStart;
  final void Function(ScaleUpdateDetails details, BoxConstraints constraints)?
  onScaleUpdate;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(color: colors.ink.withValues(alpha: .08), blurRadius: 14),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            Container(
              height: 50,
              color: colors.surface,
              alignment: Alignment.center,
              child: Text(
                '我的日记',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  key: const Key('chat-background-crop-canvas'),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: onScaleStart,
                  onScaleUpdate: onScaleUpdate == null
                      ? null
                      : (details) => onScaleUpdate!(details, constraints),
                  onDoubleTap: onDoubleTap,
                  child: DiaryChatBackgroundLayer(
                    background: background,
                    fallbackColor: colors.paper,
                    imageKey: background.hasImage
                        ? ValueKey(
                            'chat-background-preview-${background.imagePath}',
                          )
                        : null,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            children: [
                              Text(
                                '09/19 20:18',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colors.mutedInk),
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _PreviewMessageBubble(
                                  color: colors.surface.withValues(alpha: .94),
                                  textColor: colors.ink,
                                  text: '今天的云很好看。',
                                ),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _PreviewMessageBubble(
                                  color: colors.terracotta,
                                  textColor: Colors.white,
                                  text: '把这一刻记下来',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (background.hasImage)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.ink.withValues(alpha: .58),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    '拖动调整 · 双指缩放',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 54,
              color: colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    color: colors.mutedInk,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.line),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.add_circle_outline,
                    color: colors.mutedInk,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMessageBubble extends StatelessWidget {
  const _PreviewMessageBubble({
    required this.color,
    required this.textColor,
    required this.text,
  });

  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BackgroundSlider extends StatelessWidget {
  const _BackgroundSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: colors.terracotta,
          inactiveColor: colors.line,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final hues = List.generate(
      7,
      (index) => HSLColor.fromAHSL(1, index * 60, 1, .5).toColor(),
    );
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: hues),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          trackHeight: 32,
          thumbColor: Colors.white,
          overlayColor: Colors.white.withValues(alpha: .18),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        ),
        child: Slider(
          key: const Key('custom-theme-hue-slider'),
          value: value,
          max: 360,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CustomThemeColorResult {
  const _CustomThemeColorResult({this.colorValue, this.clear = false});

  final int? colorValue;
  final bool clear;
}

String _themeColorHex(int colorValue) {
  final rgb = colorValue & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
