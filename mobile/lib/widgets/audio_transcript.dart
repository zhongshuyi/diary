import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../application/transcription_controller.dart';

/// The transcript is a separate searchable attachment, not diary body text.
class AudioTranscript extends StatelessWidget {
  const AudioTranscript({
    required this.entryId,
    required this.audioPath,
    required this.controller,
    this.text,
    this.onOpenSettings,
    this.foreground,
    this.mutedColor,
    super.key,
  });

  final String entryId;
  final String audioPath;
  final TranscriptionController controller;
  final String? text;
  final VoidCallback? onOpenSettings;
  final Color? foreground;
  final Color? mutedColor;

  void _perform(VoidCallback action) {
    FocusManager.instance.primaryFocus?.unfocus();
    action();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final colors = DiaryThemeColors.of(context);
      final ink = foreground ?? colors.ink;
      final secondaryInk = mutedColor ?? foreground ?? colors.mutedInk;
      final buttonStyle = TextButton.styleFrom(
        foregroundColor: ink,
        disabledForegroundColor: secondaryInk.withValues(alpha: .6),
      );
      final state = controller.stateFor(entryId, audioPath);
      final transcript = state?.stage == AudioTranscriptionStage.completed
          ? state?.text
          : text?.trim().isNotEmpty == true
          ? text!
          : state?.text;
      final active = state?.active == true;
      final ready =
          controller.initialized &&
          controller.hasModel &&
          controller.supported &&
          !controller.busy;
      final status = switch (state?.stage) {
        AudioTranscriptionStage.queued => '等待转写',
        AudioTranscriptionStage.transcribing => '正在离线转写…',
        AudioTranscriptionStage.failed => state?.error ?? '转写未完成，可以重试。',
        AudioTranscriptionStage.cancelled => '已取消转写',
        _ => null,
      };
      return Padding(
        key: ValueKey('audio-transcript-$entryId-$audioPath'),
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transcript?.trim().isNotEmpty == true) ...[
              Text(
                '录音文字',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: secondaryInk),
              ),
              const SizedBox(height: 4),
              SelectableText(
                transcript!,
                key: ValueKey('audio-transcript-text-$entryId-$audioPath'),
                style: TextStyle(color: ink, height: 1.55),
              ),
              const SizedBox(height: 6),
            ],
            if (status != null) ...[
              Text(
                status,
                key: ValueKey('audio-transcript-status-$entryId-$audioPath'),
                style: TextStyle(color: secondaryInk, height: 1.5),
              ),
              const SizedBox(height: 4),
            ],
            if (state?.stage == AudioTranscriptionStage.transcribing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state?.progress,
                  minHeight: 3,
                  color: foreground ?? colors.terracotta,
                  backgroundColor:
                      foreground?.withValues(alpha: .25) ?? colors.line,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (active)
              TextButton.icon(
                key: ValueKey('audio-transcript-cancel-$entryId-$audioPath'),
                style: buttonStyle,
                onPressed: () => _perform(
                  () => unawaited(controller.cancel(entryId, audioPath)),
                ),
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('取消转写'),
              )
            else if (!controller.hasModel && onOpenSettings != null)
              TextButton.icon(
                key: ValueKey('audio-transcript-setup-$entryId-$audioPath'),
                style: buttonStyle,
                onPressed: () => _perform(onOpenSettings!),
                icon: const Icon(Icons.download_outlined, size: 17),
                label: const Text('设置离线转写'),
              )
            else
              Tooltip(
                message: ready ? '录音在本机识别，不上传给服务商' : '先在设置中下载离线语音模型',
                child: TextButton.icon(
                  key: ValueKey('audio-transcript-retry-$entryId-$audioPath'),
                  style: buttonStyle,
                  onPressed: ready
                      ? () => _perform(
                          () => unawaited(controller.retry(entryId, audioPath)),
                        )
                      : null,
                  icon: const Icon(Icons.transcribe_outlined, size: 17),
                  label: Text(
                    transcript?.trim().isNotEmpty == true
                        ? '重新转写'
                        : state?.stage == AudioTranscriptionStage.failed
                        ? '重试转写'
                        : '转为文字',
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
