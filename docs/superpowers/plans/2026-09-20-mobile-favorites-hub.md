# Mobile Favorites Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing favorite marker into a compact mobile Favorites hub for finding, filtering, opening, and removing saved diary entries.

**Architecture:** Keep `DiaryEntry.isFavorite` as the only persistence model. Add a pure `FavoritesFilter` for the allowed search, category, and tag conditions; render a `FavoritesPage` from a `ValueListenable<List<DiaryEntry>>`; and expose it through the existing mobile profile tools. The mobile shell owns the listenable, so a controller refresh updates an already-open Favorites page without a second diary-data store.

**Tech Stack:** Flutter/Dart, existing `DiaryEntry` model, `ValueNotifier`, Material widgets, Flutter widget tests.

**Spec:** `docs/superpowers/specs/2026-09-20-mobile-favorites-hub-design.md`

## Global Constraints

- Scope is the phone application; desktop favorite toggle and timeline filter remain unchanged.
- Keep `DiaryEntry.isFavorite`; do not add favorite time, ordering, folders, collections, labels, or duplicate records.
- Order visible entries by `effectiveOccurredAt` descending.
- Reuse text, category, and tag semantics; exclude trashed, deleted, and conflict records.
- Keep zero-favorites and zero-filter-results states distinct and compact.
- Do not add dependencies, change Isar schema, JSON payloads, repositories, or sync.
- Before device installation, inspect the debug APK and install only package `com.ling.diary.dev`.

## Review Focus

- The profile count must reflect current mobile-shell entries; Task 3's route test checks the count and callback.
- A non-favorite, trashed, deleted, or conflict entry must never appear through any query/filter combination; Task 1 covers every exclusion.
- Category plus multiple tags must be an intersection; Task 1 covers a partial-tag near miss.
- A query/filter with no result must differ from no saved records; Task 2 covers both states and clearing.
- A failed favorite mutation must leave its card visible and explain the failure; Task 2 injects a failing callback.

---

### Task 1: Add a pure Favorites filter

**Files:**
- Create: `mobile/lib/application/favorites_filter.dart`
- Test: `mobile/test/favorites_filter_test.dart`

**Interfaces:**
- Consumes: `DiaryEntry.matches(String)` and entry state fields from `mobile/lib/domain/diary_entry.dart`.
- Produces: `FavoritesFilter` with `query`, `category`, `tags`, `hasActiveConditions`, `matches(DiaryEntry)`, `copyWith(...)`, and `clearConditions()`.

- [ ] **Step 1: Write the failing filter tests**

```dart
test('keeps only visible favorites matching query, category, and every tag', () {
  final filter = FavoritesFilter(
    query: '山路', category: '旅行', tags: const {'照片', '秋天'},
  );

  expect(filter.matches(entry(
    id: 'kept', title: '山路', category: '旅行',
    tags: const ['照片', '秋天'], favorite: true,
  )), isTrue);
  expect(filter.matches(entry(
    id: 'tag-near-miss', title: '山路', category: '旅行',
    tags: const ['照片'], favorite: true,
  )), isFalse);
  expect(filter.matches(entry(id: 'ordinary', favorite: false)), isFalse);
  expect(filter.matches(entry(id: 'trash', favorite: true, inTrash: true)), isFalse);
  expect(filter.matches(entry(id: 'deleted', favorite: true, deleted: true)), isFalse);
  expect(filter.matches(entry(id: 'conflict', favorite: true, conflict: true)), isFalse);
});

test('clearing conditions preserves the search query', () {
  final cleared = FavoritesFilter(
    query: '旧句子', category: '工作', tags: const {'项目'},
  ).clearConditions();

  expect(cleared.query, '旧句子');
  expect(cleared.category, '全部');
  expect(cleared.tags, isEmpty);
  expect(cleared.hasActiveConditions, isFalse);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/favorites_filter_test.dart`

Expected: compilation fails because `FavoritesFilter` does not exist.

- [ ] **Step 3: Implement the immutable filter**

```dart
class FavoritesFilter {
  FavoritesFilter({
    this.query = '',
    this.category = '全部',
    Set<String> tags = const <String>{},
  }) : tags = Set.unmodifiable(tags);

  final String query;
  final String category;
  final Set<String> tags;

  bool get hasActiveConditions => category != '全部' || tags.isNotEmpty;

  bool matches(DiaryEntry entry) {
    if (!entry.isFavorite || entry.isInTrash || entry.isDeleted || entry.isConflict) {
      return false;
    }
    return entry.matches(query) &&
        (category == '全部' || entry.category == category) &&
        tags.every(entry.tags.contains);
  }

  FavoritesFilter copyWith({String? query, String? category, Set<String>? tags}) =>
      FavoritesFilter(
        query: query ?? this.query,
        category: category ?? this.category,
        tags: tags ?? this.tags,
      );

  FavoritesFilter clearConditions() => FavoritesFilter(query: query);
}
```

- [ ] **Step 4: Run the focused tests to verify they pass**

Run: `flutter test test/favorites_filter_test.dart`

Expected: all exclusion, search, category, and tag-intersection cases pass.

- [ ] **Step 5: Commit the filtering deliverable**

```powershell
git add -- mobile/lib/application/favorites_filter.dart mobile/test/favorites_filter_test.dart
git commit -m "feat: add favorites filtering"
```

### Task 2: Build the Favorites page and direct bookmark removal

**Files:**
- Create: `mobile/lib/pages/favorites/favorites_page.dart`
- Modify: `mobile/lib/widgets/entry_card.dart`
- Test: `mobile/test/favorites_page_test.dart`

**Interfaces:**
- Consumes: `FavoritesFilter`, `ValueListenable<List<DiaryEntry>>`, `DiaryEntryCard`, `DiaryPageIntro`, and `DiaryThemeColors`.
- Produces: `FavoritesPage({required ValueListenable<List<DiaryEntry>> entriesListenable, required Future<void> Function(DiaryEntry) onOpenEntry, required Future<void> Function(DiaryEntry) onToggleFavorite})`.

- [ ] **Step 1: Write the failing Favorites-page widget tests**

```dart
testWidgets('lists favorites newest first, opens one, and removes it after persistence', (tester) async {
  final entries = ValueNotifier<List<DiaryEntry>>([
    entry(id: 'older', title: '旧收藏', date: DateTime(2026, 9, 1), favorite: true),
    entry(id: 'newer', title: '新收藏', date: DateTime(2026, 9, 2), favorite: true),
    entry(id: 'ordinary', title: '未收藏', date: DateTime(2026, 9, 3)),
  ]);
  DiaryEntry? opened;
  await tester.pumpWidget(testApp(FavoritesPage(
    entriesListenable: entries,
    onOpenEntry: (entry) async => opened = entry,
    onToggleFavorite: (entry) async {
      entries.value = entries.value.map((item) =>
        item.id == entry.id ? item.copyWith(isFavorite: false) : item,
      ).toList();
    },
  )));

  expect(entryTitles(tester), ['新收藏', '旧收藏']);
  await tester.tap(find.text('新收藏'));
  expect(opened?.id, 'newer');
  await tester.tap(find.byTooltip('取消收藏').first);
  await tester.pumpAndSettle();
  expect(find.text('新收藏'), findsNothing);
});

testWidgets('distinguishes filter-empty from no favorites and keeps cards after a failed update', (tester) async {
  final entries = ValueNotifier<List<DiaryEntry>>([
    entry(id: 'walk', title: '散步', category: '生活', tags: const ['身体'], favorite: true),
    entry(id: 'work', title: '计划', category: '工作', tags: const ['项目'], favorite: true),
  ]);
  await tester.pumpWidget(testApp(FavoritesPage(
    entriesListenable: entries,
    onOpenEntry: (_) async {},
    onToggleFavorite: (_) async {},
  )));

  await tester.tap(find.byKey(const Key('favorites-filter-button')));
  await tester.tap(find.widgetWithText(ChoiceChip, '工作'));
  await tester.tap(find.widgetWithText(FilterChip, '#身体'));
  await tester.tap(find.byKey(const Key('favorites-filter-apply')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('favorites-filtered-empty')), findsOneWidget);

  await tester.tap(find.byKey(const Key('favorites-filter-button')));
  await tester.tap(find.byKey(const Key('favorites-filter-clear')));
  await tester.tap(find.byKey(const Key('favorites-filter-apply')));
  await tester.pumpAndSettle();
  expect(find.text('散步'), findsOneWidget);
  entries.value = const [];
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('favorites-empty')), findsOneWidget);

  final failedEntries = ValueNotifier<List<DiaryEntry>>([
    entry(id: 'failure', title: '仍然可见', favorite: true),
  ]);
  await tester.pumpWidget(testApp(FavoritesPage(
    entriesListenable: failedEntries,
    onOpenEntry: (_) async {},
    onToggleFavorite: (_) async => throw StateError('write failed'),
  )));
  await tester.tap(find.byTooltip('取消收藏'));
  await tester.pumpAndSettle();
  expect(find.text('仍然可见'), findsOneWidget);
  expect(find.text('暂时无法更新收藏，请稍后重试'), findsOneWidget);
});
```

- [ ] **Step 2: Run the page test to verify it fails**

Run: `flutter test test/favorites_page_test.dart`

Expected: compilation fails because `FavoritesPage` does not exist.

- [ ] **Step 3: Implement the page, filter sheet, and usable bookmark button**

```dart
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    required this.entriesListenable,
    required this.onOpenEntry,
    required this.onToggleFavorite,
    super.key,
  });

  final ValueListenable<List<DiaryEntry>> entriesListenable;
  final Future<void> Function(DiaryEntry entry) onOpenEntry;
  final Future<void> Function(DiaryEntry entry) onToggleFavorite;
}

List<DiaryEntry> _visibleEntries(List<DiaryEntry> entries) {
  return entries.where(_filter.matches).toList(growable: false)
    ..sort((a, b) => b.effectiveOccurredAt.compareTo(a.effectiveOccurredAt));
}

Future<void> _removeFavorite(DiaryEntry entry) async {
  try {
    await widget.onToggleFavorite(entry);
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('暂时无法更新收藏，请稍后重试')),
    );
  }
}
```

Use `ValueListenableBuilder<List<DiaryEntry>>`, a compact `DiaryPageIntro`
with title `收藏夹`, and the saved-entry count. Add a `TextField` key
`favorites-search-field` and filter button key `favorites-filter-button`.
The private bottom sheet uses category `ChoiceChip`s and multi-select tag
`FilterChip`s, returns a `FavoritesFilter`, and has clear key
`favorites-filter-clear`, and apply key `favorites-filter-apply`. Use `favorites-empty` when there are no saved
entries; use `favorites-filtered-empty` when saved entries exist but the query
or filters match none.

In `DiaryEntryCard`, retain the existing `AnimatedSwitcher`, but wrap its
bookmark icon in an `IconButton` whenever `onFavorite` is non-null. The
button has `tooltip: entry.isFavorite ? '取消收藏' : '收藏'`, calls
`onFavorite`, and falls back to the non-interactive icon without a callback.

- [ ] **Step 4: Run the focused tests to verify they pass**

Run: `flutter test test/favorites_page_test.dart test/motion_feedback_test.dart`

Expected: page tests pass for order, filters, opening, failed mutation, and
both empty states; the motion test still finds the animated icon.

- [ ] **Step 5: Commit the page deliverable**

```powershell
git add -- mobile/lib/pages/favorites/favorites_page.dart mobile/lib/widgets/entry_card.dart mobile/test/favorites_page_test.dart
git commit -m "feat: add mobile favorites hub"
```

### Task 3: Wire Favorites into the mobile profile tools

**Files:**
- Modify: `mobile/lib/pages/profile/profile_page.dart`
- Modify: `mobile/lib/app/mobile_diary_shell.dart`
- Test: `mobile/test/mobile_favorites_navigation_test.dart`

**Interfaces:**
- Consumes: `FavoritesPage`, `DiaryShellActions.openEntry`, `DiaryShellActions.toggleFavorite`, and `MobileDiaryShell.entries`.
- Produces: a mobile Profile "收藏夹" entry with a current count and a route that provides a live entries listenable to `FavoritesPage`.

- [ ] **Step 1: Write the failing navigation widget test**

```dart
testWidgets('profile opens Favorites with the live favorite count', (tester) async {
  final entries = ValueNotifier<List<DiaryEntry>>([
    entry(id: 'saved', title: '保留的一页', favorite: true),
    entry(id: 'ordinary', title: '普通记录'),
  ]);
  await tester.pumpWidget(buildMobileShell(entries));

  await tester.tap(find.text('我的'));
  await tester.pumpAndSettle();
  expect(find.text('收藏夹'), findsOneWidget);
  expect(find.text('1 篇已收藏'), findsOneWidget);

  await tester.tap(find.text('收藏夹'));
  await tester.pumpAndSettle();
  expect(find.text('保留的一页'), findsOneWidget);

  entries.value = [entry(id: 'saved', title: '保留的一页')];
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
});
```

Implement `buildMobileShell` with `ValueListenableBuilder` so it rebuilds a
`MobileDiaryShell` from the notifier. Supply no-op `DiaryShellActions` except
`openEntry` and `toggleFavorite`, keeping persistence outside this widget test.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/mobile_favorites_navigation_test.dart`

Expected: the profile has no Favorites entry and no route exists.

- [ ] **Step 3: Add profile props, live shell notifier, and route**

```dart
// ProfilePage constructor additions
this.favoriteCount = 0,
this.onOpenFavorites,

// MobileDiaryShell state lifecycle
late final ValueNotifier<List<DiaryEntry>> _favoritesEntries;

@override
void initState() {
  super.initState();
  _favoritesEntries = ValueNotifier(List.unmodifiable(widget.entries));
  _selectedIndex = _indexForHomeMode(widget.defaultHomeMode);
  _loadQuickCapturePosition();
}

@override
void didUpdateWidget(covariant MobileDiaryShell oldWidget) {
  super.didUpdateWidget(oldWidget);
  _favoritesEntries.value = List.unmodifiable(widget.entries);
  if (oldWidget.defaultHomeMode != widget.defaultHomeMode && !_selectedByUser) {
    setState(() => _selectedIndex = _indexForHomeMode(widget.defaultHomeMode));
  }
}
```

Dispose `_favoritesEntries`. Pass `favoriteCount` as the number of favorite,
non-trashed, non-deleted, non-conflict entries and pass
`onOpenFavorites: () => unawaited(_openFavorites())` only to the mobile
`ProfilePage`. Render its optional bookmark `_ProfileTile` under "日记工具" with
`'$favoriteCount 篇已收藏'` or `还没有收藏的日记`. Do not pass it to desktop.

```dart
Future<void> _openFavorites() => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: DiaryThemeColors.of(context).paper,
      body: SafeArea(child: FavoritesPage(
        entriesListenable: _favoritesEntries,
        onOpenEntry: widget.actions.openEntry,
        onToggleFavorite: widget.actions.toggleFavorite,
      )),
    ),
  ),
);
```

- [ ] **Step 4: Run routing and regression tests to verify they pass**

Run: `flutter test test/mobile_favorites_navigation_test.dart test/widget_test.dart test/filter_media_test.dart`

Expected: the route receives current entries; existing mobile profile and
timeline-favorite tests remain green; desktop behavior is unchanged.

- [ ] **Step 5: Commit the navigation deliverable**

```powershell
git add -- mobile/lib/pages/profile/profile_page.dart mobile/lib/app/mobile_diary_shell.dart mobile/test/mobile_favorites_navigation_test.dart
git commit -m "feat: link favorites from mobile profile"
```

### Task 4: Verify and package the complete feature

**Files:**
- Test: `mobile/test/favorites_filter_test.dart`
- Test: `mobile/test/favorites_page_test.dart`
- Test: `mobile/test/mobile_favorites_navigation_test.dart`

**Interfaces:**
- Consumes: every production and test interface from Tasks 1–3.
- Produces: fresh test, analysis, build, and APK-package evidence.

- [ ] **Step 1: Check committed changes for whitespace errors**

Run: `git diff --check HEAD~3..HEAD`

Expected: no output.

- [ ] **Step 2: Run the complete test suite**

Run: `flutter test`

Expected: exit code 0 and `All tests passed!`.

- [ ] **Step 3: Run targeted static analysis**

Run: `dart analyze lib/application/favorites_filter.dart lib/pages/favorites/favorites_page.dart lib/widgets/entry_card.dart lib/pages/profile/profile_page.dart lib/app/mobile_diary_shell.dart test/favorites_filter_test.dart test/favorites_page_test.dart test/mobile_favorites_navigation_test.dart`

Expected: `No issues found!`.

- [ ] **Step 4: Build and inspect the dev APK**

Run: `flutter build apk --debug`

Expected: `Built build\\app\\outputs\\flutter-apk\\app-debug.apk`.

Run: `aapt dump badging build\\app\\outputs\\flutter-apk\\app-debug.apk | Select-String '^package:'`

Expected: package name `com.ling.diary.dev`. Do not install an APK with any
other package name.

- [ ] **Step 5: Commit final test-only corrections only when needed**

Run: `git status --short`, then stage only modified files under `mobile/lib`
and `mobile/test` and commit with message `test: cover mobile favorites hub`.

Expected: unrelated `docs/` and `server/` files remain untracked and unstaged.
