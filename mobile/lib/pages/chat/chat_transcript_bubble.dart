import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/transcription_controller.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/diary_chat_appearance.dart';

class ChatTranscriptBubble extends StatelessWidget {
  const ChatTranscriptBubble({
    required this.entry,
    required this.index,
    required this.controller,
    required this.appearance,
    super.key,
  });

  final DiaryEntry entry;
  final int index;
  final TranscriptionController? controller;
  final DiaryChatAppearance appearance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller]),
    builder: (context, _) {
      final path = entry.audioPaths[index];
      final state = controller?.stateFor(entry.id, path);
      final text = state?.stage == AudioTranscriptionStage.completed
          ? state?.text ?? entry.transcriptForAudioPath(path)
          : entry.transcriptForAudioPath(path) ?? state?.text;
      final status = switch (state?.stage) {
        AudioTranscriptionStage.queued => '等待转写',
        AudioTranscriptionStage.transcribing => '正在离线转写…',
        AudioTranscriptionStage.failed => state?.error ?? '转写未完成',
        _ => null,
      };
      if (text == null && status == null) return const SizedBox.shrink();
      final colors = DiaryThemeColors.of(context);
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Material(
          key: ValueKey('chat-transcript-${entry.id}-$index'),
          shape: appearance.bubbleShape(outgoing: true),
          color: appearance.outgoingColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (text != null)
                  SelectableText(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: appearance.outgoingTextColor,
                      height: 1.45,
                    ),
                  ),
                if (text != null && status != null) const SizedBox(height: 4),
                if (status != null)
                  Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.ink,
                    ),
                  ),
                if (state?.stage == AudioTranscriptionStage.transcribing &&
                    state?.progress != null) ...[
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 112,
                    child: LinearProgressIndicator(
                      value: state?.progress,
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
