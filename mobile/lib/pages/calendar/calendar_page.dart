import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
import 'package:diary/widgets/page_intro.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    required this.entries,
    required this.onOpenEntry,
    this.onOpenEditor,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final VoidCallback? onOpenEditor;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  List<DiaryEntry> get _selectedEntries {
    final entries = widget.entries
        .where((entry) => _sameDay(entry.effectiveOccurredAt, _selectedDate))
        .toList();
    entries.sort(
      (left, right) =>
          right.effectiveOccurredAt.compareTo(left.effectiveOccurredAt),
    );
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final compactCalendarControls = MediaQuery.sizeOf(context).width < 480;
    final selectedEntries = _selectedEntries;
    final markedDays = widget.entries
        .where(
          (entry) =>
              entry.effectiveOccurredAt.year == _selectedDate.year &&
              entry.effectiveOccurredAt.month == _selectedDate.month,
        )
        .map((entry) => entry.effectiveOccurredAt.day)
        .toSet();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DiaryPageIntro(
                eyebrow: 'YOUR RHYTHM',
                title: '我的日历',
                description: '有些日子值得被圈起来，回看也是一种温柔。',
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            diaryMonthLabel(_selectedDate),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _pickDate,
                            tooltip: '跳转到某一天',
                            icon: Icon(
                              Icons.event_available_outlined,
                              color: colors.terracotta,
                            ),
                          ),
                        ],
                      ),
                      CalendarDatePicker2(
                        value: [_selectedDate],
                        config: CalendarDatePicker2Config(
                          calendarType: CalendarDatePicker2Type.single,
                          selectedDayHighlightColor: colors.hero,
                          todayTextStyle: TextStyle(
                            color: colors.terracotta,
                            fontWeight: FontWeight.w700,
                          ),
                          selectedDayTextStyle: TextStyle(
                            color: colors.onHero,
                            fontWeight: FontWeight.w700,
                          ),
                          weekdayLabels: const [
                            '一',
                            '二',
                            '三',
                            '四',
                            '五',
                            '六',
                            '日',
                          ],
                          controlsTextStyle: TextStyle(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          disableMonthPicker: compactCalendarControls,
                          dayBuilder:
                              ({
                                required date,
                                textStyle,
                                decoration,
                                isSelected,
                                isDisabled,
                                isToday,
                              }) {
                                final hasEntry = widget.entries.any(
                                  (entry) =>
                                      _sameDay(entry.effectiveOccurredAt, date),
                                );
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: decoration,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${date.day}',
                                        style: textStyle,
                                      ),
                                    ),
                                    if (hasEntry)
                                      Positioned(
                                        bottom: 3,
                                        child: Container(
                                          key: Key('calendar-mark-${date.day}'),
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: isSelected == true
                                                ? colors.butter
                                                : colors.sage,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                        ),
                        onValueChanged: (values) {
                          if (values.isNotEmpty) {
                            setState(() => _selectedDate = values.first);
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.sage,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${markedDays.length} 天有记录',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedDate.month}月${_selectedDate.day}日的片段',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    '${selectedEntries.length} 个瞬间',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              if (selectedEntries.isEmpty)
                _CalendarEmptyState(onOpenEditor: widget.onOpenEditor)
              else
                _CalendarDayMoments(
                  entries: selectedEntries,
                  onOpenEntry: widget.onOpenEntry,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    var picked = _selectedDate;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final colors = DiaryThemeColors.of(context);
        return AlertDialog(
          title: const Text('跳转到某一天'),
          content: SizedBox(
            width: 340,
            child: CalendarDatePicker2(
              value: [picked],
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.single,
                selectedDayHighlightColor: colors.hero,
                disableMonthPicker: true,
              ),
              onValueChanged: (values) {
                if (values.isNotEmpty) picked = values.first;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _selectedDate = picked);
                Navigator.pop(context);
              },
              child: const Text('查看'),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarDayMoments extends StatelessWidget {
  const _CalendarDayMoments({required this.entries, required this.onOpenEntry});

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      key: const Key('calendar-day-moments'),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0)
              Divider(indent: 18, endIndent: 18, color: colors.line),
            _CalendarEntryTile(
              entry: entries[index],
              onTap: () => onOpenEntry(entries[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarEntryTile extends StatelessWidget {
  const _CalendarEntryTile({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final title = entry.title.trim();
    final content = entry.contentText.trim();
    final primaryText = title.isNotEmpty
        ? title
        : content.isNotEmpty
        ? content
        : entry.imagePaths.isNotEmpty
        ? '照片片段'
        : '无题';
    final secondaryText = title.isNotEmpty ? content : '';
    final details = [
      entry.category,
      if (entry.tags.isNotEmpty) '#${entry.tags.first}',
      if (entry.imagePaths.isNotEmpty) '${entry.imagePaths.length} 张照片',
      if (entry.audioPaths.isNotEmpty || entry.videoPaths.isNotEmpty) '含附件',
    ].where((detail) => detail.isNotEmpty).join(' · ');
    return InkWell(
      key: Key('calendar-entry-row-${entry.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  diaryTimeLabel(entry.effectiveOccurredAt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.terracotta),
                ),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(
                color: Color(entry.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            if (entry.imagePaths.isNotEmpty) ...[
              const SizedBox(width: 10),
              _CalendarImageCollage(entry: entry),
            ] else ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colors.mutedInk),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarImageCollage extends StatelessWidget {
  const _CalendarImageCollage({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final count = entry.imagePaths.length;
    return SizedBox(
      width: count == 1 ? 58 : 76,
      height: 58,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: DiaryImageThumbnail(
                  entryId: entry.id,
                  imagePaths: entry.imagePaths,
                  index: 0,
                  borderRadius: 9,
                  expand: true,
                ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: DiaryImageThumbnail(
                    entryId: entry.id,
                    imagePaths: entry.imagePaths,
                    index: 1,
                    borderRadius: 9,
                    expand: true,
                  ),
                ),
              ],
            ],
          ),
          if (count > 2)
            Positioned(
              right: 3,
              bottom: 3,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.hero.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      '+${count - 2}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colors.onHero),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState({this.onOpenEditor});

  final VoidCallback? onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 34, color: colors.terracotta),
              const SizedBox(height: 10),
              Text('这一天还没有故事', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(
                '也许正适合现在写下第一句。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onOpenEditor != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpenEditor,
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: const Text('写下第一句'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
