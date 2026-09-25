import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class DiaryPageIntro extends StatelessWidget {
  const DiaryPageIntro({
    required this.eyebrow,
    required this.title,
    this.description,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
        ),
        const SizedBox(height: 9),
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
    );
  }
}
