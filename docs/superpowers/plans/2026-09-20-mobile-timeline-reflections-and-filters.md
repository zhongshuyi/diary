# Mobile Timeline Reflections and Filters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Add compact, private On This Day and random reread entries to the mobile timeline, plus composable date, mood, and media filters.

**Architecture:** Pure Dart application-layer objects calculate reflection candidates and evaluate a complete timeline filter from already loaded DiaryEntry values. Mobile-only widgets render the compact reflection rows and the expanded filter sheet; HomePage owns only ephemeral UI state and entry-opening callbacks. No data, repository, or sync interface changes.

**Tech Stack:** Flutter/Dart 3.11, Material 3, calendar_date_picker2, flutter_test.

**Spec:** docs/superpowers/specs/2026-09-20-mobile-timeline-reflection-and-filters-design.md

## Global Constraints

- Change only the Flutter mobile timeline experience; leave desktop HomePage layout and navigation unchanged.
- Do not add packages, DiaryEntry fields, Isar migrations, persisted settings, network calls, notifications, telemetry, or sync-protocol changes.
- Use effectiveOccurredAt and device-local calendar days for all date behavior.
- Exclude isInTrash, isDeleted, and isConflict entries from reflections and normal timeline filtering.
- Keep each reflection row 56–64dp tall and the two-row reflection area no taller than 136dp.
- Hide reflections while a keyword or any filter condition is active; never render a reflection empty-state placeholder.
- All new copy is Chinese, all actions have semantics, and status is not conveyed only by color.

## Review Focus

- Local midnight, timezone conversion, and missing occurredAt must select the correct local day; Task 1 tests effectiveOccurredAt and local dates.
- Trash, tombstone, and conflict entries must never resurface; Tasks 1 and 2 test each exclusion.
- Reversed custom date inputs must become one inclusive deterministic range; Task 2 tests range normalization.
- Tag, mood, media, date, and keyword filters must compose with AND semantics and clearing filters must preserve search text; Task 2 tests this.
- At 360px width and 130% text, reflection rows and the scrollable filter sheet must not overflow; Task 3 tests it.

---

## File Structure

| File | Responsibility |
| --- | --- |
| mobile/lib/application/timeline_reflection.dart | Candidate selection, daily-stable random selection, summary fallback. |
| mobile/lib/application/home_timeline_filter.dart | Immutable filter state, local-date ranges, mood/media predicates, reset and activity state. |
| mobile/lib/pages/home/timeline_reflection_section.dart | Compact mobile rows and the multi-entry On This Day chooser. |
| mobile/lib/pages/home/home_filter_sheet.dart | Scrollable mobile filter controls and date range picker. |
| mobile/lib/pages/home/home_page.dart | Wire reflection/filter state into the existing mobile timeline only. |
| mobile/test/timeline_reflection_test.dart | Unit coverage for dates, exclusions, ordering, rotation, and summaries. |
| mobile/test/home_timeline_filter_test.dart | Unit coverage for filter predicates, boundaries, AND composition, and reset. |
| mobile/test/timeline_reflection_widget_test.dart | Mobile widget coverage for compact UI, navigation, filter controls, hidden states, semantics, and large text. |

### Task 1: Implement private reflection calculations

**Files:**
- Create: mobile/lib/application/timeline_reflection.dart
- Create: mobile/test/timeline_reflection_test.dart

**Interfaces:**
- Consumes: DiaryEntry fields effectiveOccurredAt, id, title, contentText, isInTrash, isDeleted, and isConflict.
- Produces: TimelineReflection, calculateTimelineReflection, and reflectionSummary. Task 3 consumes these exact names.

- [ ] **Step 1: Write the failing reflection tests**

Create a local entry helper in timeline_reflection_test.dart, then add these tests:

~~~dart
test('sorts prior same-day entries and excludes ineligible records', () {
  final reflection = calculateTimelineReflection(
    entries: [
      entry('older', occurredAt: DateTime(2023, 9, 20)),
      entry('recent', occurredAt: DateTime(2025, 9, 20)),
      entry('today', occurredAt: DateTime(2026, 9, 20, 8)),
      entry('trash', occurredAt: DateTime(2024, 9, 20), isInTrash: true),
      entry('conflict', occurredAt: DateTime(2024, 9, 20), isConflict: true),
      entry('tombstone', occurredAt: DateTime(2024, 9, 20), isDeleted: true),
    ],
    now: DateTime(2026, 9, 20, 12),
  );

  expect(reflection.onThisDayEntries.map((entry) => entry.id), ['recent', 'older']);
  expect(reflection.randomCandidates.map((entry) => entry.id), containsAll(['older', 'recent']));
  expect(reflection.randomCandidates.map((entry) => entry.id), isNot(contains('today')));
});

test('keeps the daily random entry stable and rotates a multi-entry set', () {
  final reflection = calculateTimelineReflection(
    entries: [entry('a'), entry('b'), entry('c')],
    now: DateTime(2026, 9, 20),
  );

  expect(reflection.randomEntryAt(0)?.id, reflection.randomEntryAt(0)?.id);
  expect(reflection.randomEntryAt(1)?.id, isNot(reflection.randomEntryAt(0)?.id));
});

test('uses effectiveOccurredAt and a content fallback for an untitled record', () {
  final value = entry(
    'legacy',
    createdAt: DateTime(2024, 9, 20),
    occurredAt: null,
    title: '   ',
    contentText: '  旧日记正文  ',
  );
  final reflection = calculateTimelineReflection(
    entries: [value],
    now: DateTime(2026, 9, 20),
  );

  expect(reflection.onThisDayEntries.single.id, 'legacy');
  expect(reflectionSummary(value), '旧日记正文');
});
~~~

Add a same-timestamp pair and expect its ID tie-breaker order, plus a one-candidate random assertion.

- [ ] **Step 2: Run the tests to verify they fail**

Run: flutter test test/timeline_reflection_test.dart

Expected: FAIL because TimelineReflection, calculateTimelineReflection, and reflectionSummary do not exist.

- [ ] **Step 3: Add the calculator**

Create this public surface in timeline_reflection.dart:

~~~dart
class TimelineReflection {
  const TimelineReflection({
    required this.today,
    required this.onThisDayEntries,
    required this.randomCandidates,
  });

  final DateTime today;
  final List<DiaryEntry> onThisDayEntries;
  final List<DiaryEntry> randomCandidates;

  DiaryEntry? get featuredOnThisDay =>
      onThisDayEntries.isEmpty ? null : onThisDayEntries.first;

  DiaryEntry? randomEntryAt(int rotationOffset) {
    if (randomCandidates.isEmpty) return null;
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final index = (seed + rotationOffset) % randomCandidates.length;
    return randomCandidates[index < 0 ? index + randomCandidates.length : index];
  }
}

TimelineReflection calculateTimelineReflection({
  required Iterable<DiaryEntry> entries,
  required DateTime now,
});

String reflectionSummary(DiaryEntry entry);
~~~

Normalize now to DateTime(local.year, local.month, local.day). Inside the calculator, first remove trash, tombstone, and conflict records. Select On This Day by matching local month/day and a year lower than today; sort by effectiveOccurredAt descending and then id ascending. Select random candidates whose local occurrence is before today; sort by id ascending before applying the daily seed. reflectionSummary uses trimmed title, then whitespace-collapsed contentText, then the literal 未命名日记.

- [ ] **Step 4: Run the reflection test file**

Run: flutter test test/timeline_reflection_test.dart

Expected: PASS.

- [ ] **Step 5: Commit the isolated calculation**

~~~bash
git add mobile/lib/application/timeline_reflection.dart mobile/test/timeline_reflection_test.dart
git commit -m "feat: add timeline reflection calculations"
~~~

### Task 2: Implement immutable, composable timeline filtering

**Files:**
- Create: mobile/lib/application/home_timeline_filter.dart
- Create: mobile/test/home_timeline_filter_test.dart

**Interfaces:**
- Consumes: DiaryEntry and a local now value supplied by HomePage.
- Produces: HomeTimelineFilter, HomeDateFilter, HomeDatePreset, HomeMoodFilter, and HomeMediaFilter. Task 3 calls matches, hasActiveConditions, advancedFilterCount, hidesReflections, copyWith, and clearConditions.

- [ ] **Step 1: Write the failing filter tests**

Use the same kind of entry helper and add a full AND-combination test:

~~~dart
test('combines keyword, category, tags, favorite, date, mood, and media', () {
  final filter = HomeTimelineFilter(
    query: '散步',
    category: '生活',
    tags: const {'周末', '户外'},
    favoriteOnly: true,
    dateFilter: const HomeDateFilter.preset(HomeDatePreset.thisMonth),
    moodFilter: HomeMoodFilter.bright,
    mediaFilter: HomeMediaFilter.image,
  );
  final now = DateTime(2026, 9, 20, 12);

  expect(filter.matches(entry(
    'match',
    title: '散步',
    category: '生活',
    tags: const ['周末', '户外'],
    isFavorite: true,
    occurredAt: DateTime(2026, 9, 3),
    mood: .8,
    imagePaths: const ['walk.jpg'],
  ), now: now), isTrue);

  expect(filter.matches(entry(
    'wrong-mood',
    title: '散步',
    category: '生活',
    tags: const ['周末', '户外'],
    isFavorite: true,
    occurredAt: DateTime(2026, 9, 3),
    mood: .5,
    imagePaths: const ['walk.jpg'],
  ), now: now), isFalse);
});

test('normalizes custom ranges and clears conditions without clearing search', () {
  final filter = HomeTimelineFilter(
    query: '旧照片',
    category: '旅行',
    tags: const {'海边'},
    favoriteOnly: true,
    dateFilter: HomeDateFilter.custom(DateTime(2026, 9, 10), DateTime(2026, 9, 1)),
    moodFilter: HomeMoodFilter.low,
    mediaFilter: HomeMediaFilter.anyMedia,
  );

  expect(filter.clearConditions().query, '旧照片');
  expect(filter.clearConditions().hasActiveConditions, isFalse);
  expect(filter.clearConditions().hidesReflections, isTrue);
});
~~~

Also assert today, last seven local calendar days, this year, inclusive custom endpoints, .34/.67 mood boundaries, any/image/audio/video media, rejection of no-media, and rejection of trash/conflict records.

- [ ] **Step 2: Run the filter tests to verify they fail**

Run: flutter test test/home_timeline_filter_test.dart

Expected: FAIL because the filter types do not exist.

- [ ] **Step 3: Add value objects and pure predicates**

Define these exact enums:

~~~dart
enum HomeDatePreset { all, today, lastSevenDays, thisMonth, thisYear, custom }
enum HomeMoodFilter { all, low, calm, bright }
enum HomeMediaFilter { all, anyMedia, image, audio, video }
~~~

Define HomeDateFilter with const HomeDateFilter.all(), const HomeDateFilter.preset(HomeDatePreset), and HomeDateFilter.custom(DateTime first, DateTime second). The custom constructor must store the earlier local start day and later local end day, regardless of input order. Its matches method receives occurredAt and now. It uses an inclusive end day by comparing the occurrence with the day after the stored end.

Define HomeTimelineFilter as immutable:

~~~dart
class HomeTimelineFilter {
  const HomeTimelineFilter({
    this.query = '',
    this.category = '全部',
    this.tags = const {},
    this.favoriteOnly = false,
    this.dateFilter = const HomeDateFilter.all(),
    this.moodFilter = HomeMoodFilter.all,
    this.mediaFilter = HomeMediaFilter.all,
  });

  final String query;
  final String category;
  final Set<String> tags;
  final bool favoriteOnly;
  final HomeDateFilter dateFilter;
  final HomeMoodFilter moodFilter;
  final HomeMediaFilter mediaFilter;

  bool matches(DiaryEntry entry, {required DateTime now});
  bool get hasActiveConditions;
  int get advancedFilterCount;
  bool get hidesReflections;
  HomeTimelineFilter copyWith({
    String? query,
    String? category,
    Set<String>? tags,
    bool? favoriteOnly,
    HomeDateFilter? dateFilter,
    HomeMoodFilter? moodFilter,
    HomeMediaFilter? mediaFilter,
  });
  HomeTimelineFilter clearConditions();
}
~~~

matches returns false for trash, deleted, and conflict entries before all other checks. It uses entry.matches(query), category equality unless category is 全部, existing all-selected-tags semantics, favorite state, local date filter, and then mood/media conditions. Implement mood as low [0, .34), calm [.34, .67), bright [.67, 1]. Implement anyMedia from imagePaths, audioPaths, and videoPaths; individual media filters inspect exactly one path list. clearConditions returns a new filter with the existing query and all other fields at their defaults. hidesReflections is true when query is nonempty or hasActiveConditions is true.

- [ ] **Step 4: Run the filter tests**

Run: flutter test test/home_timeline_filter_test.dart

Expected: PASS.

- [ ] **Step 5: Commit the filter rules**

~~~bash
git add mobile/lib/application/home_timeline_filter.dart mobile/test/home_timeline_filter_test.dart
git commit -m "feat: add composable timeline filters"
~~~

### Task 3: Render compact mobile reflections and advanced filters

**Files:**
- Create: mobile/lib/pages/home/timeline_reflection_section.dart
- Create: mobile/lib/pages/home/home_filter_sheet.dart
- Modify: mobile/lib/pages/home/home_page.dart
- Create: mobile/test/timeline_reflection_widget_test.dart

**Interfaces:**
- Consumes: TimelineReflection, reflectionSummary, HomeTimelineFilter, existing HomePage callbacks, and DiaryThemeColors.
- Produces: TimelineReflectionSection, HomeFilterSheet, and a HomePage that obtains visible entries through HomeTimelineFilter.matches.

- [ ] **Step 1: Write failing widget tests**

Create a focused mobile test harness that pumps HomePage with desktopLayout false. Add this behavior test:

~~~dart
testWidgets('shows compact reflections and opens their original entries', (tester) async {
  final today = DateTime.now();
  DiaryEntry? opened;
  await tester.pumpWidget(homeWithEntries([
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
  ], onOpenEntry: (entry) => opened = entry));

  expect(find.byKey(const Key('timeline-reflection-section')), findsOneWidget);
  expect(find.byKey(const Key('timeline-on-this-day')), findsOneWidget);
  expect(find.byKey(const Key('timeline-random-reread')), findsOneWidget);
  expect(tester.getSize(find.byKey(const Key('timeline-on-this-day'))).height,
      inInclusiveRange(56, 64));

  await tester.tap(find.byKey(const Key('timeline-on-this-day')));
  expect(opened?.id, 'last-year');
});
~~~

Add tests that the multi-entry count action lists every candidate, the random refresh action changes the displayed candidate when more than one exists, search hides the section, the Today filter displays only today, the clear action preserves entered text, and a 360px / 1.3 text scale layout has no exception or overflow.

- [ ] **Step 2: Run the widget test to verify it fails**

Run: flutter test test/timeline_reflection_widget_test.dart

Expected: FAIL because the reflection section and advanced filter controls do not exist.

- [ ] **Step 3: Add the focused widgets**

Create TimelineReflectionSection with this exact public API:

~~~dart
class TimelineReflectionSection extends StatelessWidget {
  const TimelineReflectionSection({
    required this.reflection,
    required this.randomRotation,
    required this.onOpenEntry,
    required this.onRotateRandom,
    super.key,
  });

  final TimelineReflection reflection;
  final int randomRotation;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final VoidCallback onRotateRandom;
}
~~~

Render only available rows. Give the container the key timeline-reflection-section; use timeline-on-this-day and timeline-random-reread for main rows, timeline-on-this-day-all for the count action, and timeline-random-reread-refresh for the random action. Main rows are 56–64dp InkWell/Semantics buttons with Chinese labels. The count action opens a scrollable bottom sheet of same-day entries and forwards the selected record to onOpenEntry. The random action has the tooltip 换一条.

Create HomeFilterSheet as an isScrollControlled DraggableScrollableSheet with a ListView. It accepts initialFilter, availableCategories, availableTags, and now, then pops a complete HomeTimelineFilter. Preserve category, tag, and favorite controls. Use showDateRangePicker for the custom date and convert its return to HomeDateFilter.custom. Add keys:
- home-filter-date-today
- home-filter-date-last-seven-days
- home-filter-date-this-month
- home-filter-date-this-year
- home-filter-date-custom
- home-filter-mood-low
- home-filter-mood-calm
- home-filter-mood-bright
- home-filter-media-any
- home-filter-media-image
- home-filter-media-audio
- home-filter-media-video
- home-filter-clear

- [ ] **Step 4: Integrate without changing desktop behavior**

Replace HomePage fields _query, _category, _selectedTags, and _onlyFavorites with HomeTimelineFilter _filter and int _randomRotation = 0. Keep the existing text controller but update _filter.query through copyWith. Derive visible entries and reflection exactly as follows:

~~~dart
final now = DateTime.now();
final visibleEntries = widget.entries
    .where((entry) => _filter.matches(entry, now: now))
    .toList(growable: false);
final reflection = calculateTimelineReflection(entries: widget.entries, now: now);

if (!widget.desktopLayout && !_filter.hidesReflections) ...[
  const SizedBox(height: 12),
  TimelineReflectionSection(
    reflection: reflection,
    randomRotation: _randomRotation,
    onOpenEntry: widget.onOpenEntry,
    onRotateRandom: () => setState(() => _randomRotation += 1),
  ),
],
~~~

Put that section after the mobile search field and before category chips. Use HomeFilterSheet from the existing 筛选 action. Keep its existing 筛选 tooltip, color the icon for any active filter, and add a Material Badge only when advancedFilterCount is positive. Pass an onClearFilters callback to _EmptyState when hasActiveConditions is true; this action calls clearConditions and does not alter _filter.query. Do not render the new section, badge, or advanced sheet controls from the desktop layout branch.

- [ ] **Step 5: Run focused widget and regression tests**

Run: flutter test test/timeline_reflection_widget_test.dart test/home_timeline_filter_test.dart test/timeline_reflection_test.dart test/filter_media_test.dart

Expected: all new reflection/filter tests pass. The existing filter_media_test.dart case named shows a missing media state with a retry affordance is currently known to fail because 文件不可用 is not rendered. If it remains the only failure, record it as unchanged baseline behavior; do not alter unrelated media-player behavior in this feature.

- [ ] **Step 6: Commit the mobile UI integration**

~~~bash
git add mobile/lib/pages/home/home_page.dart mobile/lib/pages/home/timeline_reflection_section.dart mobile/lib/pages/home/home_filter_sheet.dart mobile/test/timeline_reflection_widget_test.dart
git commit -m "feat: add mobile timeline reflections and filters"
~~~

### Task 4: Final verification

**Files:**
- Modify only Task 1–3 files if verification finds a feature defect.
- Test: the three new test files plus existing home widget coverage.

**Interfaces:**
- Consumes: every public interface produced in Tasks 1–3.
- Produces: evidence that the mobile-only feature is clean and the known unrelated media assertion is distinguished from regressions.

- [ ] **Step 1: Analyze every new or modified feature file**

Run: dart analyze lib/application/timeline_reflection.dart lib/application/home_timeline_filter.dart lib/pages/home/timeline_reflection_section.dart lib/pages/home/home_filter_sheet.dart lib/pages/home/home_page.dart test/timeline_reflection_test.dart test/home_timeline_filter_test.dart test/timeline_reflection_widget_test.dart

Expected: no errors or warnings introduced by this feature.

- [ ] **Step 2: Run existing home regressions**

Run: flutter test test/widget_test.dart test/filter_media_test.dart

Expected: existing home search, day-card, and favorite-filter tests pass. If the missing-media case remains the sole failure, report its exact test name and assertion as baseline; any additional failure must be fixed in the task that owns it.

- [ ] **Step 3: Check the final diff and commits**

Run: git diff --check HEAD~3..HEAD

Run: git log --oneline -3

Expected: no whitespace errors and three focused commits for calculation, filter logic, and mobile UI integration.
