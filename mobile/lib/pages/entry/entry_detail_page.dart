import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
import 'package:diary/widgets/diary_video_player.dart';
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
                _DetailHeader(
                  entry: _entry,
                  showWordCount: widget.showWordCount,
                ),
                if (_entry.contentText.isNotEmpty ||
                    _entry.content.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _DetailSectionTitle(
                    icon: Icons.subject_rounded,
                    title: '文字',
                  ),
                  const SizedBox(height: 10),
                  _Content(entry: _entry),
                ],
                if (_entry.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _DetailSectionTitle(
                    icon: Icons.photo_library_outlined,
                    title: '照片',
                    count: _entry.imagePaths.length,
                  ),
                  const SizedBox(height: 10),
                  DiaryImageGallery(
                    entryId: _entry.id,
                    imagePaths: _entry.imagePaths,
                    showHeader: false,
                    maxGridHeight: 340,
                  ),
                ],
                if (_entry.audioPaths.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _DetailSectionTitle(
                    icon: Icons.graphic_eq_rounded,
                    title: '声音',
                    count: _entry.audioPaths.length,
                  ),
                  const SizedBox(height: 10),
                  for (
                    var index = 0;
                    index < _entry.audioPaths.length;
                    index++
                  ) ...[
                    DiaryAudioPlayer(
                      path: _entry.audioPaths[index],
                      label: _entry.audioPaths.length == 1
                          ? '语音片段'
                          : '语音片段 ${index + 1}',
                    ),
                    if (index < _entry.audioPaths.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
                if (_entry.videoPaths.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _DetailSectionTitle(
                    icon: Icons.play_circle_outline_rounded,
                    title: '视频',
                    count: _entry.videoPaths.length,
                  ),
                  const SizedBox(height: 10),
                  for (
                    var index = 0;
                    index < _entry.videoPaths.length;
                    index++
                  ) ...[
                    DiaryVideoPreview(
                      key: Key('entry-detail-video-${_entry.id}-$index'),
                      path: _entry.videoPaths[index],
                      label: '视频片段 ${index + 1}',
                    ),
                    if (index < _entry.videoPaths.length - 1)
                      const SizedBox(height: 10),
                  ],
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
}

class _Content extends StatelessWidget {
  const _Content({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    if (entry.editorType == DiaryEditorType.markdown) {
      return _ContentSurface(
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
    return _ContentSurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.entry, required this.showWordCount});

  final DiaryEntry entry;
  final bool showWordCount;

  bool get _isMoodOnly =>
      entry.moodLabel != null &&
      entry.contentText.trim().isEmpty &&
      entry.content.trim().isEmpty &&
      !entry.hasMedia;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final occurredAt = entry.effectiveOccurredAt;
    final mood = _EntryMood.resolve(
      entry.moodLabel ?? diaryMoodLabel(entry.mood),
    );
    return Container(
      key: const Key('entry-detail-header'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colors.terracotta,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${occurredAt.year}年 · ${diaryDateLabel(occurredAt)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.terracotta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                diaryTimeLabel(occurredAt),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.mutedInk),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isMoodOnly)
            _MoodOnlyHeader(mood: mood)
          else ...[
            Text(
              entry.isStandaloneLocation
                  ? entry.locationDisplayName
                  : entry.title.trim().isEmpty
                  ? '无题片段'
                  : entry.title.trim(),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: colors.ink,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 14),
            _MoodLine(mood: mood, explicit: entry.moodLabel != null),
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _MetaChip(
                  label: entry.category,
                  icon: Icons.folder_open_outlined,
                ),
                if (entry.moodLabel == null)
                  _MetaChip(label: mood.label, icon: mood.icon),
                ...entry.weather.map(
                  (weather) =>
                      _MetaChip(label: weather, icon: Icons.wb_sunny_outlined),
                ),
                if (entry.positions.isNotEmpty)
                  _MetaChip(
                    label: entry.locationDisplayName,
                    icon: Icons.location_on_outlined,
                  ),
                ...entry.tags.map(
                  (tag) => _MetaChip(label: '#$tag', icon: Icons.sell_outlined),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 15, color: colors.mutedInk),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '更新于 ${diaryTimeLabel(entry.updatedAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colors.mutedInk),
                    ),
                  ),
                  if (showWordCount)
                    Text(
                      '${entry.wordCount} 字',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colors.mutedInk),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodOnlyHeader extends StatelessWidget {
  const _MoodOnlyHeader({required this.mood});

  final _EntryMood mood;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Center(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: mood.backgroundColor(colors),
              shape: BoxShape.circle,
            ),
            child: Icon(mood.icon, size: 30, color: colors.terracotta),
          ),
          const SizedBox(height: 10),
          Text(
            '此刻的心情',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colors.mutedInk),
          ),
          const SizedBox(height: 2),
          Text(mood.label, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _MoodLine extends StatelessWidget {
  const _MoodLine({required this.mood, required this.explicit});

  final _EntryMood mood;
  final bool explicit;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: mood.backgroundColor(colors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mood.icon, size: 18, color: colors.terracotta),
          const SizedBox(width: 7),
          Text(
            explicit ? '此刻心情 · ${mood.label}' : mood.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryMood {
  const _EntryMood({
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color Function(DiaryThemeColors colors) tint;

  Color backgroundColor(DiaryThemeColors colors) => tint(colors);

  static _EntryMood resolve(String label) {
    return switch (label) {
      '阴天' => _EntryMood(
        label: label,
        icon: Icons.cloud_outlined,
        tint: (colors) => colors.lavender,
      ),
      '低落' => _EntryMood(
        label: label,
        icon: Icons.sentiment_dissatisfied_outlined,
        tint: (colors) => colors.lavender,
      ),
      '平静' => _EntryMood(
        label: label,
        icon: Icons.sentiment_satisfied_alt_outlined,
        tint: (colors) => colors.sage,
      ),
      '明亮' => _EntryMood(
        label: label,
        icon: Icons.wb_sunny_outlined,
        tint: (colors) => colors.butter,
      ),
      _ => _EntryMood(
        label: label,
        icon: Icons.sentiment_neutral_outlined,
        tint: (colors) => colors.terracottaSoft,
      ),
    };
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({
    required this.icon,
    required this.title,
    this.count,
  });

  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 19, color: colors.terracotta),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (count != null) ...[
          const SizedBox(width: 7),
          Text(
            '$count ${title == '照片' ? '张' : '段'}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colors.mutedInk),
          ),
        ],
      ],
    );
  }
}

class _ContentSurface extends StatelessWidget {
  const _ContentSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: child,
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
