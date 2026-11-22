import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/transcription_controller.dart';

import 'settings_controls.dart';

class TranscriptionSettingsPage extends StatefulWidget {
  const TranscriptionSettingsPage({required this.controller, super.key});
  final TranscriptionController controller;

  @override
  State<TranscriptionSettingsPage> createState() =>
      _TranscriptionSettingsPageState();
}

class _TranscriptionSettingsPageState extends State<TranscriptionSettingsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  void didUpdateWidget(covariant TranscriptionSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      unawaited(widget.controller.initialize());
    }
  }

  Future<void> _removeModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除语音模型？'),
        content: const Text('会关闭转写并释放模型占用的空间。录音和已保存的文字会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除模型'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.controller.removeModel();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: DiaryThemeColors.of(context).paper,
      appBar: AppBar(title: const Text('录音转文字'), centerTitle: true),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final canChange =
              controller.initialized &&
              controller.supported &&
              !controller.busy;
          return ListView(
            key: const Key('transcription-settings-list'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              SettingsFeatureSwitch(
                switchKey: const Key('transcription-enabled'),
                icon: Icons.transcribe_outlined,
                title: '启用录音转写',
                description: !controller.initialized
                    ? '正在读取本机设置…'
                    : !controller.supported
                    ? '当前设备暂不支持离线转写。'
                    : !controller.hasModel
                    ? '下载语音模型后即可在本机转写。'
                    : controller.enabled
                    ? '在聊天里长按语音，选择「转为文字」。'
                    : '已暂停，录音及已有文字会保留。',
                value: controller.enabled,
                onChanged: canChange
                    ? (value) => unawaited(controller.setEnabled(value))
                    : null,
              ),
              if (controller.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  controller.error!,
                  key: const Key('transcription-settings-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              _SpeechModelCard(controller: controller, onRemove: _removeModel),
              const SizedBox(height: 12),
              SettingsCard(
                child: SwitchListTile.adaptive(
                  key: const Key('transcription-auto-enabled'),
                  title: const Text('录音保存后自动转写'),
                  subtitle: Text(
                    controller.enabled && controller.hasModel
                        ? '仅对之后保存的新录音生效。'
                        : '启用转写并准备好语音模型后可设置。',
                  ),
                  value: controller.autoTranscribe,
                  onChanged: controller.ready
                      ? (value) =>
                            unawaited(controller.setAutoTranscribe(value))
                      : null,
                ),
              ),
              if (controller.transcribing || controller.queuedCount > 0) ...[
                const SizedBox(height: 12),
                SettingsCard(
                  child: ListTile(
                    title: Text(
                      controller.transcribing ? '正在转写' : '等待转写',
                      key: const Key('transcription-queue-status'),
                    ),
                    subtitle: Text('等待 ${controller.queuedCount} 条'),
                    trailing: IconButton(
                      key: const Key('transcription-stop-queue'),
                      tooltip: '停止全部转写',
                      onPressed: () => unawaited(controller.stop()),
                      icon: const Icon(Icons.stop_circle_outlined),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const SettingsHelp(
                topics: [
                  (
                    title: '手动转写',
                    text: '关闭自动转写后，仍可长按聊天中的语音手动转写。每段录音最多 3 分钟、50 MB。',
                  ),
                  (title: '隐私与保存', text: '识别在本机完成。原录音会保留，转写文字可搜索，也可随日记备份和同步。'),
                  (
                    title: '设备与格式',
                    text:
                        'Android 8.1 及以上的 ARM64 手机支持 AAC/m4a 和 WAV。Windows x64 支持 WAV。噪声、多人说话和方言可能影响识别。',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpeechModelCard extends StatelessWidget {
  const _SpeechModelCard({required this.controller, required this.onRemove});

  final TranscriptionController controller;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DiaryThemeColors.of(context);
    return SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('离线语音模型', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              !controller.initialized
                  ? '正在检查本机模型…'
                  : !controller.supported
                  ? '录音仍可正常保存和播放。'
                  : controller.hasModel
                  ? 'SenseVoice 已下载 · 约 240 MB'
                  : 'SenseVoice · 约 240 MB，点击下载才会联网。',
              key: const Key('transcription-model-status'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedInk,
              ),
            ),
            if (!controller.initialized || controller.downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                key: const Key('transcription-download-progress'),
                value: controller.downloading
                    ? controller.downloadProgress
                    : null,
              ),
            ],
            if (controller.downloading) ...[
              const SizedBox(height: 8),
              Text(
                controller.downloadProgress == null
                    ? '正在准备下载…'
                    : '正在下载 ${(controller.downloadProgress! * 100).floor()}%',
                key: const Key('transcription-download-status'),
              ),
              TextButton.icon(
                key: const Key('transcription-cancel-download'),
                onPressed: () => unawaited(controller.cancelDownload()),
                icon: const Icon(Icons.close_rounded),
                label: const Text('取消下载'),
              ),
            ] else if (controller.initialized) ...[
              const SizedBox(height: 12),
              if (controller.hasModel)
                OutlinedButton.icon(
                  key: const Key('transcription-remove-model'),
                  onPressed: controller.busy || !controller.supported
                      ? null
                      : onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('移除语音模型'),
                )
              else
                FilledButton.icon(
                  key: const Key('transcription-download-model'),
                  onPressed: controller.busy || !controller.supported
                      ? null
                      : () => unawaited(controller.downloadModel()),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('下载离线模型'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
