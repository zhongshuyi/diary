import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';

class RecyclePage extends StatelessWidget {
  const RecyclePage({
    required this.entries,
    required this.onRestore,
    required this.onDelete,
    required this.onEmpty,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onRestore;
  final ValueChanged<DiaryEntry> onDelete;
  final Future<void> Function() onEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('回收站'),
        actions: [
          if (entries.isNotEmpty)
            TextButton.icon(
              key: const Key('empty-recycle-bin'),
              onPressed: () => _confirmEmpty(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空'),
              style: TextButton.styleFrom(foregroundColor: colors.terracotta),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A QUIET CORNER',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
                ),
                const SizedBox(height: 9),
                Text('回收站', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  '被删除的日记会先来到这里，你可以在这里恢复或彻底删除。',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 23),
                if (entries.isEmpty)
                  const _RecycleEmptyState()
                else
                  ...entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecycleTile(
                        entry: entry,
                        onRestore: () => onRestore(entry),
                        onDelete: () => _confirmDelete(context, entry),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除这篇日记？'),
        content: Text(_deleteWarning(entry)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete(entry);
  }

  Future<void> _confirmEmpty(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站？'),
        content: Text(_emptyWarning(entries)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-empty-recycle-bin'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空回收站'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onEmpty();
  }
}

String _deleteWarning(DiaryEntry entry) {
  final attachmentCount = [
    ...entry.imagePaths,
    ...entry.audioPaths,
    ...entry.videoPaths,
  ].length;
  if (attachmentCount == 0) {
    return '删除后无法恢复，这篇日记没有附件。';
  }
  return '删除后无法恢复，其中包含 $attachmentCount 个附件。';
}

String _emptyWarning(List<DiaryEntry> entries) {
  final attachmentCount = entries.fold<int>(
    0,
    (total, entry) =>
        total +
        entry.imagePaths.length +
        entry.audioPaths.length +
        entry.videoPaths.length,
  );
  final entryCount = entries.length;
  if (attachmentCount == 0) {
    return '将永久删除 $entryCount 篇日记，删除后无法恢复。';
  }
  return '将永久删除 $entryCount 篇日记及其中 $attachmentCount 个附件，删除后无法恢复。';
}

class _RecycleTile extends StatelessWidget {
  const _RecycleTile({
    required this.entry,
    required this.onRestore,
    required this.onDelete,
  });

  final DiaryEntry entry;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: colors.terracottaSoft,
          child: Icon(Icons.delete_outline, color: colors.terracotta),
        ),
        title: Text(entry.title.isEmpty ? '无题' : entry.title),
        subtitle: Text('移入回收站 · ${diaryDateLabel(entry.updatedAt)}'),
        trailing: Wrap(
          children: [
            IconButton(
              onPressed: onRestore,
              tooltip: '恢复',
              icon: const Icon(Icons.restore_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: '永久删除',
              color: colors.terracotta,
              icon: const Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecycleEmptyState extends StatelessWidget {
  const _RecycleEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 22),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                size: 38,
                color: colors.mutedInk,
              ),
              const SizedBox(height: 12),
              Text(
                '这里还没有被丢弃的日记',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '你的每一页都还在好好保存着。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
