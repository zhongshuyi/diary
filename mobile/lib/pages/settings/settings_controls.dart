import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class SettingsFeatureSwitch extends StatelessWidget {
  const SettingsFeatureSwitch({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SettingsCard(
    child: SwitchListTile.adaptive(
      key: switchKey,
      secondary: Icon(icon, color: DiaryThemeColors.of(context).terracotta),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(description),
      value: value,
      onChanged: onChanged,
    ),
  );
}

class SettingsHelp extends StatelessWidget {
  const SettingsHelp({required this.topics, super.key});

  final List<({String title, String text})> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DiaryThemeColors.of(context);
    return SettingsCard(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.info_outline_rounded),
        title: const Text('使用说明'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final topic in topics) ...[
            Text(topic.title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              topic.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedInk,
                height: 1.5,
              ),
            ),
            if (topic != topics.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
