import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';

class RecordingFeedback extends StatelessWidget {
  const RecordingFeedback({
    required this.elapsed,
    required this.cancelOnRelease,
    required this.waveform,
    super.key,
  });

  final String elapsed;
  final bool cancelOnRelease;
  final ValueListenable<List<double>> waveform;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final theme = Theme.of(context);
    final ink = cancelOnRelease
        ? theme.colorScheme.onErrorContainer
        : colors.ink;
    final accent = cancelOnRelease ? ink : colors.terracotta;
    return AbsorbPointer(
      child: Material(
        color: Colors.black.withValues(alpha: .46),
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 232,
              child: AnimatedContainer(
                key: const ValueKey('live-recording-overlay'),
                duration: DiaryMotion.duration(
                  context,
                  const Duration(milliseconds: 140),
                ),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cancelOnRelease
                      ? theme.colorScheme.errorContainer
                      : colors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      elapsed,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 24,
                      child: ValueListenableBuilder<List<double>>(
                        valueListenable: waveform,
                        builder: (context, levels, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final level in levels)
                              Container(
                                width: 3,
                                height: 3 + 21 * level,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        cancelOnRelease ? '松开取消 · 滑回继续' : '松开添加 · 上滑取消',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
