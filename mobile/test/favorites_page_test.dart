import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/favorites/favorites_page.dart';
import 'package:diary/widgets/entry_card.dart';

DiaryEntry _entry({
  required String id,
  required String title,
  DateTime? date,
  String category = '生活',
  List<String> tags = const [],
  bool favorite = false,
}) {
  final occurredAt = date ?? DateTime(2026, 9, 20, 9);
  return DiaryEntry(
    id: id,
    createdAt: occurredAt,
    updatedAt: occurredAt,
    title: title,
    content: '正文：$title',
    contentText: '正文：$title',
    category: category,
    tags: tags,
    isFavorite: favorite,
  );
}

Widget _testApp(Widget child) => MaterialApp(home: Scaffold(body: child));

List<String> _entryTitles(WidgetTester tester) {
  return tester
      .widgetList<DiaryEntryCard>(find.byType(DiaryEntryCard))
      .map((card) => card.entry.title)
      .toList(growable: false);
}

void main() {
  testWidgets(
    'lists favorites newest first, opens one, and removes it after persistence',
    (tester) async {
      final entries = ValueNotifier<List<DiaryEntry>>([
        _entry(
          id: 'older',
          title: '旧收藏',
          date: DateTime(2026, 9, 1),
          favorite: true,
        ),
        _entry(
          id: 'newer',
          title: '新收藏',
          date: DateTime(2026, 9, 2),
          favorite: true,
        ),
        _entry(id: 'ordinary', title: '未收藏', date: DateTime(2026, 9, 3)),
      ]);
      DiaryEntry? opened;
      await tester.pumpWidget(
        _testApp(
          FavoritesPage(
            entriesListenable: entries,
            onOpenEntry: (entry) async => opened = entry,
            onToggleFavorite: (entry) async {
              entries.value = entries.value
                  .map(
                    (item) => item.id == entry.id
                        ? item.copyWith(isFavorite: false)
                        : item,
                  )
                  .toList(growable: false);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_entryTitles(tester), ['新收藏', '旧收藏']);
      await tester.tap(find.text('新收藏'));
      expect(opened?.id, 'newer');
      await tester.tap(find.byTooltip('取消收藏').first);
      await tester.pumpAndSettle();
      expect(find.text('新收藏'), findsNothing);
    },
  );

  testWidgets(
    'filters, clears no results, distinguishes no favorites, and keeps a card after a failed update',
    (tester) async {
      final entries = ValueNotifier<List<DiaryEntry>>([
        _entry(
          id: 'walk',
          title: '散步',
          category: '生活',
          tags: const ['身体'],
          favorite: true,
        ),
        _entry(
          id: 'work',
          title: '计划',
          category: '工作',
          tags: const ['项目'],
          favorite: true,
        ),
      ]);
      await tester.pumpWidget(
        _testApp(
          FavoritesPage(
            entriesListenable: entries,
            onOpenEntry: (_) async {},
            onToggleFavorite: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('favorites-search-field')),
        '散步',
      );
      await tester.pumpAndSettle();
      expect(_entryTitles(tester), ['散步']);
      await tester.enterText(
        find.byKey(const Key('favorites-search-field')),
        '',
      );

      await tester.tap(find.byKey(const Key('favorites-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '工作'));
      await tester.tap(find.widgetWithText(FilterChip, '#身体'));
      await tester.tap(find.byKey(const Key('favorites-filter-apply')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-filtered-empty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('favorites-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('favorites-filter-clear')));
      await tester.tap(find.byKey(const Key('favorites-filter-apply')));
      await tester.pumpAndSettle();
      expect(_entryTitles(tester), containsAll(['计划', '散步']));

      entries.value = const [];
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);

      final failedEntries = ValueNotifier<List<DiaryEntry>>([
        _entry(id: 'failure', title: '仍然可见', favorite: true),
      ]);
      await tester.pumpWidget(
        _testApp(
          FavoritesPage(
            entriesListenable: failedEntries,
            onOpenEntry: (_) async {},
            onToggleFavorite: (_) async => throw StateError('write failed'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('取消收藏'));
      await tester.pumpAndSettle();
      expect(find.text('仍然可见'), findsOneWidget);
      expect(find.text('暂时无法更新收藏，请稍后重试'), findsOneWidget);
    },
  );
}
