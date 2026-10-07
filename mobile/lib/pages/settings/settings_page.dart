import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/daily_reminder_scheduler.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/amap_location_bridge.dart';
import 'package:diary/domain/connection_settings_transfer.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/widgets/diary_chat_background.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';
import 'package:diary/widgets/app_lock_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.controller,
    this.onOpenCategories,
    this.onOpenBackup,
    this.onOpenAbout,
    this.onOpenLocalAssistant,
    this.onOpenTranscription,
    this.onOpenChatAppearance,
    this.onImportPhotos,
    this.pickChatBackgroundPhoto,
    this.showDataControls = true,
    super.key,
  });

  final SettingsController controller;
  final VoidCallback? onOpenCategories;
  final VoidCallback? onOpenBackup;
  final VoidCallback? onOpenAbout;
  final VoidCallback? onOpenLocalAssistant;
  final VoidCallback? onOpenTranscription;
  final VoidCallback? onOpenChatAppearance;
  final Future<List<String>> Function(List<String> paths)? onImportPhotos;
  final Future<List<String>> Function()? pickChatBackgroundPhoto;
  final bool showDataControls;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colors = DiaryThemeColors.of(context);
        final settings = controller.settings;
        Widget tile({
          Key? key,
          IconData? icon,
          required String title,
          String? status,
          required VoidCallback onTap,
        }) => _SettingsTile(
          key: key,
          flat: true,
          leading: icon == null ? null : Icon(icon, color: colors.terracotta),
          title: Text(title),
          subtitle: status == null ? null : Text(status),
          trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
          onTap: onTap,
        );
        final groups = <_SettingsGroup>[
          _SettingsGroup(
            id: 'recording',
            title: '记录与陪伴',
            label: '记录',
            icon: Icons.edit_note_rounded,
            items: [
              if (onOpenLocalAssistant != null)
                _SearchableSetting(
                  keywords:
                      '日记陪伴 AI LLM 人工智能 助手 回复 安慰 鼓励 情绪 语气 人设 模型 API 密钥 本地 在线 MiniMax DeepSeek OpenAI 兼容 自定义 服务商',
                  child: tile(
                    key: const Key('settings-local-assistant'),
                    icon: Icons.auto_awesome_outlined,
                    title: '日记陪伴',
                    status: '模型、回复语气与人设',
                    onTap: onOpenLocalAssistant!,
                  ),
                ),
              if (onOpenTranscription != null)
                _SearchableSetting(
                  keywords: '录音转文字 语音 识别 转写 声音 离线 自动 转录 重试 搜索 模型 下载',
                  child: tile(
                    key: const Key('settings-transcription'),
                    icon: Icons.transcribe_outlined,
                    title: '录音转文字',
                    status: '离线识别与自动转写',
                    onTap: onOpenTranscription!,
                  ),
                ),
              if (onOpenChatAppearance != null)
                _SearchableSetting(
                  keywords:
                      '对话外观 聊天 样式 布局 气泡 头像 陪伴 ${settings.chatStyle.label}',
                  child: tile(
                    key: const Key('settings-chat-appearance'),
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '对话外观',
                    status: settings.chatStyle.label,
                    onTap: onOpenChatAppearance!,
                  ),
                ),
              _SearchableSetting(
                keywords:
                    '默认编辑方式 编辑器 输入 写日记 富文本 Markdown ${settings.defaultEditorType.label}',
                child: tile(
                  key: const Key('settings-default-editor'),
                  title: '默认编辑方式',
                  status: settings.defaultEditorType.label,
                  onTap: () =>
                      _showEditorChoice(context, settings.defaultEditorType),
                ),
              ),
              _SearchableSetting(
                keywords: '默认首页 首页 启动 对话 时间线 ${settings.defaultHomeMode.label}',
                child: tile(
                  key: const Key('settings-default-home'),
                  title: '默认首页',
                  status: settings.defaultHomeMode.label,
                  onTap: () => _showDefaultHomeModeChoice(
                    context,
                    settings.defaultHomeMode,
                  ),
                ),
              ),
              _SearchableSetting(
                keywords: '显示字数 字数 长度 统计 详情',
                child: _SwitchTile(
                  key: const Key('settings-word-count'),
                  flat: true,
                  title: '显示字数',
                  value: settings.showWordCount,
                  onChanged: (value) =>
                      unawaited(controller.setShowWordCount(value)),
                ),
              ),
              if (onOpenChatAppearance == null)
                _SearchableSetting(
                  keywords: '对话显示头像 聊天 头像 陪伴',
                  child: _SwitchTile(
                    key: const Key('settings-show-chat-avatar'),
                    flat: true,
                    title: '对话显示头像',
                    value: settings.showChatAvatar,
                    onChanged: (value) =>
                        unawaited(controller.setShowChatAvatar(value)),
                  ),
                ),
            ],
          ),
          _SettingsGroup(
            id: 'appearance',
            title: '外观与阅读',
            label: '外观',
            icon: Icons.palette_outlined,
            items: [
              _SearchableSetting(
                keywords:
                    '主题模式 明亮 黑暗 深色 浅色 夜间 跟随系统 ${settings.themeMode.label}',
                child: tile(
                  key: const Key('settings-theme-mode'),
                  title: '主题模式',
                  status: settings.themeMode.label,
                  onTap: () => _showThemeChoice(context, settings.themeMode),
                ),
              ),
              _SearchableSetting(
                keywords: '主题配色 预设 颜色 风格 ${settings.themePreset.label}',
                child: tile(
                  key: const Key('settings-theme-preset'),
                  title: '主题配色',
                  status: settings.themePreset.label,
                  onTap: () =>
                      _showThemePresetChoice(context, settings.themePreset),
                ),
              ),
              _SearchableSetting(
                keywords: '自定义主题色 自定义主色 主色 颜色 配色',
                child: _SettingsTile(
                  key: const Key('settings-custom-theme-color'),
                  flat: true,
                  leading: _ThemeColorDot(
                    color: Color(
                      settings.customThemeColor ?? colors.terracotta.toARGB32(),
                    ),
                  ),
                  title: const Text('自定义主题色'),
                  subtitle: Text(
                    settings.customThemeColor == null
                        ? '使用预设主色'
                        : _themeColorHex(settings.customThemeColor!),
                  ),
                  trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
                  onTap: () => _showCustomThemeColorPicker(
                    context,
                    currentColor: settings.customThemeColor,
                    fallbackColor: colors.terracotta,
                  ),
                ),
              ),
              _SearchableSetting(
                keywords:
                    '阅读字号 字体 大小 缩放 文字 ${(settings.fontScale * 100).round()}%',
                child: tile(
                  key: const Key('settings-font-scale'),
                  icon: Icons.text_fields_rounded,
                  title: '阅读字号',
                  status: '${(settings.fontScale * 100).round()}%',
                  onTap: () =>
                      _showFontScalePicker(context, settings.fontScale),
                ),
              ),
              _SearchableSetting(
                keywords:
                    '聊天背景 对话 壁纸 图片 裁剪 背景 ${settings.chatBackground.hasImage ? '已设置图片' : '默认'}',
                child: tile(
                  key: const Key('settings-chat-background'),
                  icon: Icons.wallpaper_outlined,
                  title: '聊天背景',
                  status: settings.chatBackground.hasImage ? '已设置图片' : '使用主题底色',
                  onTap: () => _showChatBackgroundEditor(
                    context,
                    settings.chatBackground,
                  ),
                ),
              ),
            ],
          ),
          _SettingsGroup(
            id: 'security',
            title: '提醒与安全',
            label: '安全',
            icon: Icons.shield_outlined,
            items: [
              _SearchableSetting(
                keywords: '每日提醒 每天 通知 记录提醒 ${settings.dailyReminderTime.label}',
                child: _SwitchTile(
                  key: const Key('settings-daily-reminder'),
                  flat: true,
                  title: '每日提醒',
                  subtitle: settings.dailyReminder
                      ? '每天 ${settings.dailyReminderTime.label}'
                      : '已关闭',
                  value: settings.dailyReminder,
                  onChanged: (value) =>
                      unawaited(_setDailyReminder(context, value)),
                ),
              ),
              if (settings.dailyReminder)
                _SearchableSetting(
                  keywords:
                      '提醒时间 每日提醒 定时 每日 每天 通知 ${settings.dailyReminderTime.label}',
                  child: tile(
                    key: const Key('settings-daily-reminder-time'),
                    icon: Icons.schedule_rounded,
                    title: '提醒时间',
                    status: '每天 ${settings.dailyReminderTime.label}',
                    onTap: () => _showDailyReminderTimePicker(
                      context,
                      settings.dailyReminderTime,
                    ),
                  ),
                ),
              _SearchableSetting(
                keywords: '应用锁 锁 密码 PIN 指纹 面容 生物识别 安全 隐私 保护',
                child: AppLockSettings(controller: controller),
              ),
            ],
          ),
          if (showDataControls ||
              onOpenBackup != null ||
              onOpenCategories != null)
            _SettingsGroup(
              id: 'data',
              title: '数据与服务',
              label: '数据',
              icon: Icons.storage_outlined,
              items: [
                if (showDataControls)
                  _SearchableSetting(
                    keywords:
                        '同步 云端 服务器 连接 数据 服务 token ${settings.syncEndpoint.isEmpty ? '本地模式 尚未连接' : '已配置'}',
                    child: tile(
                      key: const Key('settings-sync'),
                      icon: Icons.cloud_sync_outlined,
                      title: '同步',
                      status: settings.syncEndpoint.isEmpty
                          ? '本地模式 · 尚未连接服务器'
                          : '已配置同步连接',
                      onTap: () => _openConnectionSettings(context),
                    ),
                  ),
                if (onOpenBackup != null)
                  _SearchableSetting(
                    keywords: '备份与恢复 备份 恢复 导入 导出 迁移 JSON 数据',
                    child: tile(
                      key: const Key('settings-backup'),
                      icon: Icons.import_export_outlined,
                      title: '备份与恢复',
                      onTap: onOpenBackup!,
                    ),
                  ),
                if (onOpenCategories != null)
                  _SearchableSetting(
                    keywords: '分类与标签 分类 标签 整理 主题 管理',
                    child: tile(
                      key: const Key('settings-categories'),
                      icon: Icons.sell_outlined,
                      title: '分类与标签',
                      onTap: onOpenCategories!,
                    ),
                  ),
              ],
            ),
          _SettingsGroup(
            id: 'location',
            title: '地图与位置',
            label: '地图',
            icon: Icons.location_on_outlined,
            items: [
              _SearchableSetting(
                keywords:
                    '高德 Android Key 高德密钥 地图 地点 位置 定位 ${settings.amapAndroidKey.isEmpty ? '未配置' : '已配置'}',
                child: tile(
                  key: const Key('settings-amap-key'),
                  icon: Icons.location_on_outlined,
                  title: '高德 Android Key',
                  status: settings.amapAndroidKey.isEmpty
                      ? '尚未配置'
                      : '已配置 · 仅保存在此设备',
                  onTap: () =>
                      _showAmapKeyEditor(context, settings.amapAndroidKey),
                ),
              ),
              _SearchableSetting(
                keywords: '高德地图隐私授权 地图 位置 同意 隐私 授权 撤回',
                child: tile(
                  key: const Key('settings-amap-privacy'),
                  icon: Icons.privacy_tip_outlined,
                  title: '高德地图隐私授权',
                  status: '管理或撤回授权',
                  onTap: () => _revokeAmapConsent(context),
                ),
              ),
            ],
          ),
          if (onOpenAbout != null)
            _SettingsGroup(
              id: 'about',
              title: '关于',
              label: '关于',
              icon: Icons.info_outline_rounded,
              items: [
                _SearchableSetting(
                  keywords: '关于此刻 版本 更新 隐私说明 许可证 开源 帮助',
                  child: tile(
                    key: const Key('settings-about'),
                    icon: Icons.info_outline_rounded,
                    title: '关于此刻',
                    status: '版本、更新与隐私说明',
                    onTap: onOpenAbout!,
                  ),
                ),
              ],
            ),
        ];
        return Scaffold(
          backgroundColor: colors.paper,
          appBar: AppBar(
            backgroundColor: colors.paper,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: const Text('设置'),
          ),
          body: _SettingsWorkspace(
            groups: groups,
            keyboardVisible: MediaQuery.viewInsetsOf(context).bottom > 0,
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

  Future<void> _setDailyReminder(BuildContext context, bool value) async {
    final result = await controller.setDailyReminder(value);
    if (!context.mounted || result.isSuccess) return;
    _showDailyReminderFeedback(context, result);
  }

  Future<void> _showDailyReminderTimePicker(
    BuildContext context,
    DiaryReminderTime current,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: '选择每日提醒时间',
    );
    if (time == null) return;
    final result = await controller.setDailyReminderTime(
      DiaryReminderTime(hour: time.hour, minute: time.minute),
    );
    if (!context.mounted || result.isSuccess) return;
    _showDailyReminderFeedback(context, result);
  }

  void _showDailyReminderFeedback(
    BuildContext context,
    DailyReminderScheduleResult result,
  ) {
    final message = switch (result) {
      DailyReminderScheduleResult.permissionDenied => '没有获得系统通知权限，提醒未开启',
      DailyReminderScheduleResult.unsupported => '当前设备不支持系统提醒',
      DailyReminderScheduleResult.failed => '暂时无法安排提醒，请稍后重试',
      _ => '',
    };
    if (message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _openConnectionSettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SyncSettingsPage(controller: controller),
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

  Future<void> _showAmapKeyEditor(BuildContext context, String current) async {
    var entered = current;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('高德 Android Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Key 必须与当前安装包的包名和签名 SHA1 匹配。位置功能仅在 Android 上可用。'),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('amap-key-field'),
              initialValue: current,
              onChanged: (value) => entered = value,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Android Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, entered),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value != null) await controller.setAmapAndroidKey(value);
  }

  Future<void> _revokeAmapConsent(BuildContext context) async {
    final revoke = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('撤回高德地图授权？'),
        content: const Text('撤回后，下次查看或发送位置时会再次询问。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('撤回授权'),
          ),
        ],
      ),
    );
    if (revoke != true) return;
    await AmapLocationBridge.revokeConsent();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已撤回高德地图授权')));
    }
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

class SyncSettingsPage extends StatelessWidget {
  const SyncSettingsPage({required this.controller, super.key});

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
        title: const Text('同步'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _Section(
            title: '连接设置',
            children: [_SyncSettings(controller: controller)],
          ),
          const SizedBox(height: 12),
          _Section(
            title: '存储',
            children: [
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
          '复制内容包含访问令牌，请仅发送给自己的设备。',
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
  Widget build(BuildContext context) => _SettingsSection(
    sectionId: 'connection-$title',
    title: title,
    flatRows: false,
    children: children,
  );
}

class _SearchableSetting {
  const _SearchableSetting({required this.keywords, required this.child});

  final String keywords;
  final Widget child;
}

class _SettingsGroup {
  const _SettingsGroup({
    required this.id,
    required this.title,
    required this.label,
    required this.icon,
    required this.items,
  });

  final String id;
  final String title;
  final String label;
  final IconData icon;
  final List<_SearchableSetting> items;
}

class _SettingsWorkspace extends StatefulWidget {
  const _SettingsWorkspace({
    required this.groups,
    required this.keyboardVisible,
  });

  final List<_SettingsGroup> groups;
  final bool keyboardVisible;

  @override
  State<_SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

class _SettingsWorkspaceState extends State<_SettingsWorkspace> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _groupKeys = <String, GlobalKey>{};
  String _query = '';
  String? _selectedGroup;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _matches(String text) {
    final normalized = text.toLowerCase();
    return _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(normalized.contains);
  }

  void _setQuery(String value) {
    setState(() {
      _query = value.trim();
      _selectedGroup = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _clearSearch() {
    _search.clear();
    _setQuery('');
  }

  void _jumpToGroup(_SettingsGroup group) {
    FocusManager.instance.primaryFocus?.unfocus();
    _search.clear();
    setState(() {
      _query = '';
      _selectedGroup = group.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sectionContext = _groupKeys[group.id]?.currentContext;
      if (sectionContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          sectionContext,
          alignment: 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final keyboardVisible = widget.keyboardVisible;
    final sections = <Widget>[];
    for (final group in widget.groups) {
      final wholeGroup = _query.isEmpty || _matches(group.title);
      final items = group.items
          .where((item) => wholeGroup || _matches(item.keywords))
          .toList(growable: false);
      if (items.isEmpty) continue;
      sections.add(
        _SettingsSection(
          key: _groupKeys.putIfAbsent(group.id, GlobalKey.new),
          sectionId: group.id,
          title: group.title,
          children: [
            for (final item in items)
              KeyedSubtree(
                key: ValueKey(item.keywords.split(' ').first),
                child: item.child,
              ),
          ],
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('settings-search'),
                      controller: _search,
                      onChanged: _setQuery,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: '搜索设置，例如模型、字体、同步',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.mutedInk),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('settings-search-clear'),
                                tooltip: '清除搜索',
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: colors.surface,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (!keyboardVisible) ...[
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 600 ? 6 : 3;
                          final chipWidth =
                              (constraints.maxWidth - (columns - 1) * 6) /
                              columns;
                          return Wrap(
                            spacing: 6,
                            runSpacing: 0,
                            children: [
                              for (final group in widget.groups)
                                SizedBox(
                                  width: chipWidth,
                                  child: InputChip(
                                    key: ValueKey('settings-group-${group.id}'),
                                    avatar: Icon(group.icon, size: 16),
                                    label: Text(group.label),
                                    tooltip: group.title,
                                    selected: _selectedGroup == group.id,
                                    showCheckmark: false,
                                    visualDensity: const VisualDensity(
                                      vertical: -1,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                    onPressed: () => _jumpToGroup(group),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const Key('settings-list'),
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  children: [
                    if (sections.isEmpty)
                      Padding(
                        key: const Key('settings-search-empty'),
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              color: colors.mutedInk,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            const Text('没有找到相关设置'),
                            const SizedBox(height: 10),
                            TextButton(
                              key: const Key('settings-search-clear-empty'),
                              onPressed: _clearSearch,
                              child: const Text('清除搜索'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(children: sections),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.sectionId,
    required this.title,
    required this.children,
    this.flatRows = true,
    super.key,
  });

  final String sectionId;
  final String title;
  final List<Widget> children;
  final bool flatRows;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                key: ValueKey('settings-section-$sectionId'),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.terracotta),
              ),
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (flatRows && index < children.length - 1)
                Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: colors.line.withValues(alpha: .6),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.flat = false,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool flat;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      flat: flat,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
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
    this.flat = false,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final radius = flat ? BorderRadius.zero : BorderRadius.circular(14);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: flat ? 0 : 2),
      child: Material(
        color: flat ? Colors.transparent : colors.paper,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
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
          onTap: onTap == null
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onTap!();
                },
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
