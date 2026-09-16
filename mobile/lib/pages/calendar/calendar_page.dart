import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/page_intro.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    required this.entries,
    required this.onOpenEntry,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpenEntry;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  List<DiaryEntry> get _selectedEntries => widget.entries
      .where((entry) => _sameDay(entry.effectiveOccurredAt, _selectedDate))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
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
                const _CalendarEmptyState()
              else
                ...selectedEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CalendarEntryTile(
                      entry: entry,
                      onTap: () => widget.onOpenEntry(entry),
                    ),
                  ),
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

class _CalendarEntryTile extends StatelessWidget {
  const _CalendarEntryTile({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: Color(entry.colorValue),
          child: Icon(Icons.edit_note, color: colors.ink),
        ),
        title: Text(entry.title.isEmpty ? '无题' : entry.title),
        subtitle: Text(
          '${diaryTimeLabel(entry.createdAt)} · ${entry.contentText}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right, color: colors.mutedInk),
      ),
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState();

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
