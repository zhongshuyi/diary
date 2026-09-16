import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../domain/conflict.dart';
import '../../domain/diary_entry.dart';

class ConflictsPage extends StatelessWidget {
  const ConflictsPage({
    required this.conflicts,
    required this.onResolve,
    super.key,
  });

  final List<Conflict> conflicts;
  final Future<void> Function(String conflictId, DiaryEntry resolution)
  onResolve;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('同步冲突'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Text(
            'KEEP BOTH SIDES',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
          ),
          const SizedBox(height: 8),
          Text('需要你决定的记录', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            '冲突不会静默覆盖，选择保留本机或服务器版本即可。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          if (conflicts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Center(
                  child: Text(
                    '暂无待处理冲突',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            )
          else
            ...conflicts.map(
              (conflict) =>
                  _ConflictCard(conflict: conflict, onResolve: onResolve),
            ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict, required this.onResolve});
  final Conflict conflict;
  final Future<void> Function(String, DiaryEntry) onResolve;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflict.entry.title.isEmpty ? '无题' : conflict.entry.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '本机：${_preview(conflict.entry.contentText)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '服务器：${_preview(conflict.serverEntry.contentText)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        onResolve(conflict.conflictId, conflict.entry),
                    child: const Text('保留本机'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        onResolve(conflict.conflictId, conflict.serverEntry),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.terracotta,
                    ),
                    child: const Text('保留服务器'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _preview(String value) => value.trim().isEmpty ? '（无文字）' : value.trim();
