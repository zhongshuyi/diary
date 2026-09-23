import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/insights/insights_page.dart';

DiaryEntry _entry(String id, {double mood = .5, String? moodLabel}) {
  final now = DateTime(2026, 9, 20);
  return DiaryEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    title: id,
    content: id,
    contentText: id,
    category: '生活',
    mood: mood,
    moodLabel: moodLabel,
  );
}

void main() {
  testWidgets('insights ignore entries without an explicit mood', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsPage(
            entries: [
              _entry('unmarked'),
              _entry('selected', mood: .7, moodLabel: '平静'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('70%'), findsOneWidget);
    expect(find.text('平静'), findsOneWidget);
    expect(find.text('平常'), findsNothing);
  });

  testWidgets('insights show no mood value when nothing was selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InsightsPage(entries: [_entry('unmarked')])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('主动标记心情后，这里会出现你的情绪轨迹。'), findsOneWidget);
  });

  testWidgets('older non-neutral moods still contribute to insights', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsPage(
            entries: [_entry('unmarked'), _entry('legacy-selected', mood: .9)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('90%'), findsOneWidget);
    expect(find.text('明亮'), findsOneWidget);
  });
}
