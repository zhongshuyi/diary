import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../application/transcription_controller.dart';

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
        content: const Text('会关闭自动转写并释放模型占用的存储空间。录音和已保存的文字会保留。'),
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
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: const Text('录音转文字'), centerTitle: true),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final canChange =
              controller.initialized &&
              controller.supported &&
              !controller.busy;
          return ListView(
            key: const Key('transcription-settings-list'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text('录音，也能搜得到', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '在手机本地把录音转成文字，单独保存在录音下方并用于搜索，不会插入日记正文。',
                style: TextStyle(color: colors.mutedInk, height: 1.6),
              ),
              const SizedBox(height: 20),
              _TranscriptionCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '离线语音模型',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SenseVoice · 约 240 MB',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        !controller.initialized
                            ? '正在检查本机模型…'
                            : controller.hasModel
                            ? '模型已准备好，可以离线转写。'
                            : '先下载语音模型。只在你点击下载时联网。',
                        key: const Key('transcription-model-status'),
                        style: TextStyle(color: colors.mutedInk, height: 1.5),
                      ),
                      if (controller.initialized && !controller.supported) ...[
                        const SizedBox(height: 10),
                        Text(
                          '目前需要 Android 8.1 或更高版本的 64 位 ARM 手机，或 64 位 Windows（x64）。当前设备暂不支持这项本地转写功能，录音仍可正常保存和播放。',
                          style: TextStyle(color: colors.mutedInk, height: 1.5),
                        ),
                      ],
                      if (!controller.initialized ||
                          controller.downloading) ...[
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 6),
                        TextButton.icon(
                          key: const Key('transcription-cancel-download'),
                          onPressed: () =>
                              unawaited(controller.cancelDownload()),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('取消下载'),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!controller.hasModel)
                              FilledButton.icon(
                                key: const Key('transcription-download-model'),
                                onPressed: canChange
                                    ? () =>
                                          unawaited(controller.downloadModel())
                                    : null,
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('下载离线模型'),
                              ),
                            if (controller.hasModel)
                              OutlinedButton.icon(
                                key: const Key('transcription-remove-model'),
                                onPressed: canChange
                                    ? () => unawaited(_removeModel())
                                    : null,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('移除语音模型'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _TranscriptionCard(
                child: SwitchListTile.adaptive(
                  key: const Key('transcription-auto-enabled'),
                  title: const Text('录音保存后自动转写'),
                  subtitle: Text(
                    controller.hasModel
                        ? '保存新录音后排队处理，可在录音下方取消或手动重试。'
                        : '下载模型后才能开启。',
                  ),
                  value: controller.autoTranscribe && controller.hasModel,
                  onChanged: canChange && controller.hasModel
                      ? (value) =>
                            unawaited(controller.setAutoTranscribe(value))
                      : null,
                ),
              ),
              if (controller.transcribing || controller.queuedCount > 0) ...[
                const SizedBox(height: 14),
                Text(
                  controller.transcribing
                      ? '正在处理一条录音${controller.queuedCount > 0 ? '，另有 ${controller.queuedCount} 条等待' : ''}。'
                      : '有 ${controller.queuedCount} 条录音等待转写。',
                  key: const Key('transcription-queue-status'),
                  style: TextStyle(color: colors.mutedInk, height: 1.5),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('transcription-stop-queue'),
                    onPressed: () => unawaited(controller.stop()),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('停止本次转写'),
                  ),
                ),
              ],
              if (controller.error != null) ...[
                const SizedBox(height: 14),
                Text(
                  controller.error!,
                  key: const Key('transcription-settings-error'),
                  style: TextStyle(color: colors.ink, height: 1.5),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                '录音在本机识别，不上传给模型服务。识别文字可能有错字，嘈杂环境、多人说话和方言会影响效果；原录音始终保留。',
                style: TextStyle(color: colors.mutedInk, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                '当前每条录音支持最多 3 分钟、50 MB。较长录音请分段保存。转写会占用 CPU，首次加载可能稍慢；关闭自动转写后仍可手动转写历史录音。',
                style: TextStyle(color: colors.mutedInk, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                '支持 Android 8.1 或更高版本的 64 位 ARM 手机、Windows x64。Android 支持应用录音的 AAC/m4a 与 WAV；Windows 当前仅支持 WAV。',
                style: TextStyle(color: colors.mutedInk, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                '下载的模型与自动转写设置仅保存在本机。录音文字作为录音的附属信息保存，便于以后搜索。',
                style: TextStyle(color: colors.mutedInk, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TranscriptionCard extends StatelessWidget {
  const _TranscriptionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
