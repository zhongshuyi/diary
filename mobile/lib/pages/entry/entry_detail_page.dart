import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/local_media_preview.dart';
import 'package:diary/widgets/rich_text_viewer.dart';

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({
    required this.entry,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
    required this.onToggleFavorite,
    this.showWordCount = true,
    super.key,
  });

  final DiaryEntry entry;
  final Future<DiaryEntry?> Function(DiaryEntry entry) onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final bool showWordCount;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('日记详情'),
        actions: [
          IconButton(
            onPressed: widget.onShare,
            tooltip: '分享',
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            onPressed: _toggleFavorite,
            tooltip: '收藏',
            icon: Icon(
              _entry.isFavorite ? Icons.bookmark : Icons.bookmark_border,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _edit();
              if (value == 'delete') _delete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(value: 'delete', child: Text('移入回收站')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaryDateLabel(_entry.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
                ),
                const SizedBox(height: 14),
                Text(
                  _entry.title.isEmpty ? '无题' : _entry.title,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _MetaChip(
                      label: _entry.category,
                      icon: Icons.folder_open_outlined,
                    ),
                    _MetaChip(
                      label: diaryMoodLabel(_entry.mood),
                      icon: Icons.wb_sunny_outlined,
                    ),
                    ..._entry.tags.map(
                      (tag) =>
                          _MetaChip(label: '#$tag', icon: Icons.sell_outlined),
                    ),
                  ],
                ),
                if (widget.showWordCount) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_entry.wordCount} 字 · 更新于 ${diaryTimeLabel(_entry.updatedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 25),
                _Content(entry: _entry),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 25),
                  Text('附件', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 9),
                  ..._attachments.map(
                    (attachment) => Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: SizedBox(
                          width: 46,
                          height: 46,
                          child: LocalMediaPreview(
                            path: attachment.path,
                            kind: attachment.kind,
                          ),
                        ),
                        title: Text(attachment.fileName),
                        subtitle: Text(
                          '${diaryMediaKindLabel(attachment.kind)} · 本地附件',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('编辑这篇'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('分享'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() => _entry = _entry.copyWith(isFavorite: !_entry.isFavorite));
    widget.onToggleFavorite();
  }

  Future<void> _edit() async {
    final updated = await widget.onEdit(_entry);
    if (mounted && updated != null) setState(() => _entry = updated);
  }

  void _delete() {
    widget.onDelete();
    Navigator.pop(context);
  }

  List<_EntryAttachment> get _attachments =>
      [..._entry.imagePaths, ..._entry.audioPaths, ..._entry.videoPaths]
          .map(
            (path) =>
                _EntryAttachment(path: path, kind: diaryMediaKindForPath(path)),
          )
          .toList(growable: false);
}

class _EntryAttachment {
  const _EntryAttachment({required this.path, required this.kind});

  final String path;
  final DiaryMediaKind kind;

  String get fileName => path.split(RegExp(r'[\\/]')).last;
}

class _Content extends StatelessWidget {
  const _Content({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    if (entry.editorType == DiaryEditorType.markdown) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: MarkdownBody(
            data: entry.content.isEmpty ? entry.contentText : entry.content,
          ),
        ),
      );
    }
    if (entry.editorType == DiaryEditorType.richText) {
      return DiaryRichTextViewer(
        content: entry.content,
        fallbackText: entry.contentText,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          entry.contentText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.ink,
            height: 1.8,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Chip(
      avatar: Icon(icon, size: 15, color: colors.terracotta),
      label: Text(label),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.line),
      visualDensity: VisualDensity.compact,
    );
  }
}
