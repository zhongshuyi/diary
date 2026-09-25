import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class TrashFeedbackToast extends StatelessWidget {
  const TrashFeedbackToast({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 700;
    final bottom =
        media.viewInsets.bottom +
        media.padding.bottom +
        (isMobile ? 62.0 : 28.0);
    final label = count == 1 ? '已移入回收站' : '已移入回收站 · $count 篇';

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Material(
              key: const Key('trash-feedback-toast'),
              color: colors.surface,
              elevation: 4,
              shadowColor: colors.ink.withValues(alpha: .12),
              shape: StadiumBorder(side: BorderSide(color: colors.line)),
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: colors.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
