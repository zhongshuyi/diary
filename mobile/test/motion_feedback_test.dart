import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
import 'package:diary/widgets/entry_card.dart';

DiaryEntry _entry({DateTime? date, bool isFavorite = false}) {
  final now = date ?? DateTime(2026, 9, 17);
  return DiaryEntry(
    id: 'motion-entry',
    createdAt: now,
    updatedAt: now,
    title: '一条日记',
    content: '正文',
    contentText: '正文',
    category: '生活',
    isFavorite: isFavorite,
  );
}

void main() {
  testWidgets('keeps the standard duration when motion is allowed', (
    tester,
  ) async {
    Duration? duration;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          duration = DiaryMotion.duration(
            context,
            const Duration(milliseconds: 180),
          );
          return const SizedBox();
        },
      ),
    );

    expect(duration, const Duration(milliseconds: 180));
  });

  testWidgets('collapses motion when reduced motion is enabled', (
    tester,
  ) async {
    Duration? duration;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            duration = DiaryMotion.duration(
              context,
              const Duration(milliseconds: 180),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(duration, Duration.zero);
  });

  testWidgets('animates favorite status changes in the entry card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryEntryCard(entry: _entry(), onTap: () {}, onFavorite: () {}),
      ),
    );

    expect(find.byType(AnimatedSwitcher), findsOneWidget);
  });

  testWidgets('marks dates that contain entries and offers an empty CTA', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          entries: [_entry(date: today)],
          onOpenEntry: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('calendar-mark-${today.day}')), findsOneWidget);

    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          entries: const [],
          onOpenEntry: (_) {},
          onOpenEditor: () => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('写下第一句'));
    await tester.tap(find.text('写下第一句'));

    expect(opened, isTrue);
  });

  testWidgets(
    'uses the active theme color for calendar marks and aligns rows',
    (tester) async {
      final today = DateTime.now();
      final colors = DiaryThemeColors.lightFor(DiaryThemePreset.deepSea);
      await tester.pumpWidget(
        MaterialApp(
          theme: DiaryTheme.lightFor(DiaryThemePreset.deepSea),
          home: CalendarPage(
            entries: [_entry(date: today)],
            onOpenEntry: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mark = tester.widget<Container>(
        find.byKey(Key('calendar-mark-${today.day}')),
      );
      expect((mark.decoration! as BoxDecoration).color, colors.terracotta);

      final time = tester.getRect(
        find.byKey(const Key('calendar-entry-time-motion-entry')),
      );
      final dot = tester.getRect(
        find.byKey(const Key('calendar-entry-mark-motion-entry')),
      );
      final title = tester.getRect(
        find.byKey(const Key('calendar-entry-title-motion-entry')),
      );
      expect(time.center.dy, closeTo(title.center.dy, .1));
      expect(dot.center.dy, closeTo(title.center.dy, .1));
    },
  );
}
