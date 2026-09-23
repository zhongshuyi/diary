import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/widgets/day_entry_card.dart';

DiaryEntry entry(
  String id, {
  required DateTime occurredAt,
  String? title,
  String category = '生活',
  double mood = .5,
  List<String> imagePaths = const [],
  List<String> audioPaths = const [],
  List<String> videoPaths = const [],
}) {
  final value = title ?? id;
  return DiaryEntry(
    id: id,
    createdAt: occurredAt,
    updatedAt: occurredAt,
    occurredAt: occurredAt,
    title: value,
    content: value,
    contentText: value,
    category: category,
    mood: mood,
    imagePaths: imagePaths,
    audioPaths: audioPaths,
    videoPaths: videoPaths,
  );
}

Widget homeWithEntries(
  List<DiaryEntry> entries, {
  ValueChanged<DiaryEntry>? onOpenEntry,
  double textScale = 1,
  bool desktopLayout = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: HomePage(
            entries: entries,
            onOpenEditor: () {},
            onOpenEntry: onOpenEntry ?? (_) {},
            onToggleFavorite: (_) {},
            onShare: (_) {},
            onDelete: (_) {},
            onQuickCapture: (_) async {},
            desktopLayout: desktopLayout,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('builds only nearby day cards on a long mobile timeline', (
    tester,
  ) async {
    final today = DateTime.now();
    final entries = [
      for (var index = 0; index < 100; index++)
        entry(
          'day-$index',
          occurredAt: DateTime(today.year, today.month, today.day - index, 10),
        ),
    ];
    await tester.pumpWidget(homeWithEntries(entries));
    await tester.pumpAndSettle();

    expect(find.byType(DayEntryCard).evaluate().length, lessThan(20));
    expect(find.text('day-99'), findsNothing);
  });

  testWidgets('shows compact reflections and opens their original entry', (
    tester,
  ) async {
    final today = DateTime.now();
    DiaryEntry? opened;
    await tester.pumpWidget(
      homeWithEntries([
        entry(
          'last-year',
          title: '去年的秋天',
          occurredAt: DateTime(today.year - 1, today.month, today.day),
        ),
        entry(
          'history',
          title: '更早的一天',
          occurredAt: today.subtract(const Duration(days: 20)),
        ),
      ], onOpenEntry: (value) => opened = value),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('timeline-reflection-section')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('timeline-on-this-day')), findsOneWidget);
    expect(find.byKey(const Key('timeline-random-reread')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('timeline-on-this-day'))).height,
      inInclusiveRange(56, 64),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('timeline-on-this-day'))).label,
      contains('那年今日'),
    );

    await tester.tap(find.byKey(const Key('timeline-on-this-day')));
    expect(opened?.id, 'last-year');
  });

  testWidgets('opens every same-day entry from the summary row', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      homeWithEntries([
        entry(
          'last-year',
          title: '去年的秋天',
          occurredAt: DateTime(today.year - 1, today.month, today.day),
        ),
        entry(
          'two-years',
          title: '前年的秋天',
          occurredAt: DateTime(today.year - 2, today.month, today.day),
        ),
        entry(
          'history-a',
          title: '历史甲',
          occurredAt: today.subtract(const Duration(days: 20)),
        ),
        entry(
          'history-b',
          title: '历史乙',
          occurredAt: today.subtract(const Duration(days: 40)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final summary = tester
        .widget<Text>(find.byKey(const Key('timeline-random-reread-summary')))
        .data;
    await tester.tap(find.byKey(const Key('timeline-random-reread-refresh')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('timeline-random-reread-summary')))
          .data,
      isNot(summary),
    );

    await tester.tap(find.byKey(const Key('timeline-on-this-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timeline-on-this-day-sheet')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('timeline-on-this-day-sheet')),
        matching: find.text('去年的秋天'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('timeline-on-this-day-sheet')),
        matching: find.text('前年的秋天'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a prior-week summary with every qualifying entry', (
    tester,
  ) async {
    final today = DateTime.now();
    final currentWeekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final priorWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    await tester.pumpWidget(
      homeWithEntries([
        entry(
          'prior-week-first',
          title: '周报片段甲',
          occurredAt: priorWeekStart.add(const Duration(days: 1)),
          category: '生活',
        ),
        entry(
          'prior-week-second',
          title: '周报片段乙',
          occurredAt: priorWeekStart.add(const Duration(days: 4)),
          category: '阅读',
        ),
        entry('this-week', title: '不应计入', occurredAt: today),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline-weekly-summary')), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline-weekly-summary')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('timeline-weekly-summary-sheet')),
      findsOneWidget,
    );
    final sheet = find.byKey(const Key('timeline-weekly-summary-sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('上周小结')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('周报片段甲')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('周报片段乙')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('不应计入')),
      findsNothing,
    );
  });

  testWidgets('hides reflections for search and applies mobile date filters', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      homeWithEntries([
        entry('today', title: '今天的记录', occurredAt: today),
        entry(
          'old',
          title: '过去的记录',
          occurredAt: today.subtract(const Duration(days: 40)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('diary-search-field')),
      '今天的记录',
    );
    await tester.pump();
    expect(find.byKey(const Key('timeline-reflection-section')), findsNothing);

    await tester.enterText(find.byKey(const Key('diary-search-field')), '');
    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-filter-date-today')));
    await tester.scrollUntilVisible(
      find.text('应用筛选'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-entry-row-today')), findsOneWidget);
    expect(find.byKey(const Key('mobile-entry-row-old')), findsNothing);
  });

  testWidgets('clearing filters preserves typed search text', (tester) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      homeWithEntries([
        entry('today', title: '今天', occurredAt: today),
        entry(
          'old',
          title: '旧日记',
          occurredAt: today.subtract(const Duration(days: 40)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('diary-search-field')), '今天');
    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-filter-date-today')));
    await tester.scrollUntilVisible(
      find.text('应用筛选'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-filter-clear')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('home-filter-clear')));
    await tester.scrollUntilVisible(
      find.text('应用筛选'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('diary-search-field')))
          .controller
          ?.text,
      '今天',
    );
  });

  testWidgets('keeps the clear-filters action out of the desktop timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      homeWithEntries([
        entry('ordinary', occurredAt: DateTime.now()),
      ], desktopLayout: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('只看收藏'));
    await tester.pumpAndSettle();

    expect(find.text('清除筛选条件'), findsNothing);
  });

  testWidgets(
    'keeps reflections and filters usable on narrow large text screens',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final today = DateTime.now();
      await tester.pumpWidget(
        homeWithEntries([
          entry(
            'last-year',
            title: '这是一条用于检查大字号布局的去年记录',
            occurredAt: DateTime(today.year - 1, today.month, today.day),
          ),
          entry(
            'history',
            title: '这是另一条用于检查布局的较早记录',
            occurredAt: today.subtract(const Duration(days: 20)),
          ),
        ], textScale: 1.3),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('筛选'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-filter-date-today')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
