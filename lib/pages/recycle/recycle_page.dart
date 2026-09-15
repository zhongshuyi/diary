import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';

class RecyclePage extends StatelessWidget {
  const RecyclePage({
    required this.entries,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onRestore;
  final ValueChanged<DiaryEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiaryPalette.paper,
      appBar: AppBar(
        backgroundColor: DiaryPalette.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('回收站'),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DiaryPalette.terracotta,
                  ),
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
        content: const Text('删除后无法恢复，请确认你已经不需要它。'),
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: const CircleAvatar(
          backgroundColor: DiaryPalette.terracottaSoft,
          child: Icon(Icons.delete_outline, color: DiaryPalette.terracotta),
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
              color: DiaryPalette.terracotta,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 22),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.delete_sweep_outlined,
                size: 38,
                color: DiaryPalette.mutedInk,
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
