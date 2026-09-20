# Mobile Favorites Hub Design

## Intent

Make an existing favorite mark useful for return visits. A person should be
able to open all saved diary entries from one obvious place, narrow them with
the same language they already use for records, and open or remove a favorite
without having to reconstruct a timeline search.

The scope is the phone application. The existing desktop favorite toggle and
timeline filter remain unchanged.

## Decisions

- A favorite remains the existing `isFavorite` boolean on `DiaryEntry`.
- There is no favorite timestamp, manual ordering, folder, collection, or
  duplicate copy of a diary entry.
- Existing favorites keep their current state without migration.
- The hub orders entries by their diary occurrence date, newest first.
- Search, category, and tag filtering reuse the current entry matching rules.

## User Experience

`ProfilePage` adds a **Favorites** item under the mobile diary tools. Its
subtitle includes the current favorite count, and it opens a dedicated
`FavoritesPage`. This avoids adding a fifth primary-navigation destination
while keeping favorites one tap away from the personal tools users already
visit.

The Favorites page contains:

1. A compact page introduction and the number of saved entries.
2. A search field that checks title, content, category, and tags.
3. A filter control for category and tags. It starts unfiltered and has an
   explicit clear action whenever filters are active.
4. A chronological list of favorite entries using the app's existing diary
   card treatment. Tapping a card opens its original entry.
5. A visible bookmark action on each card that removes it from favorites and
   immediately removes it from the list.

With no favorites, the page shows a compact explanatory empty state and a
clear path back rather than a large placeholder. With active filters that
match nothing, it explains that the filters produced no results and offers to
clear them.

## Architecture and Data Flow

No schema, Isar collection, JSON payload, sync protocol, or repository
interface changes are required. `MobileDiaryShell` already receives the live
entry list and a `toggleFavorite` action. It will expose the supplied list
through a private, read-only `ValueListenable`, pass the count to
`ProfilePage`, and pass that listenable plus the action to a pushed
`FavoritesPage`.

`FavoritesPage` owns only presentational filter state. It derives visible
records from the incoming listenable by excluding trashed records, retaining
`isFavorite`, applying the existing text/category/tag predicates, and sorting
by `effectiveOccurredAt` descending. A favorite action calls the existing
shell action; when the controller refreshes the phone shell, the listenable
updates the already-open page without making a duplicate copy of diary data.

## Error Handling

Favorite persistence uses the existing controller/repository path. The page
does not optimistically invent a second copy of state: if a mutation fails,
the supplied listenable remains authoritative. Normal app-level error feedback
is preserved. Empty and filtered-empty states are distinct so users can tell
whether they have no favorites or merely need to clear filters.

## Verification

Add widget coverage for:

- the Favorites entry and count in the mobile profile tools;
- opening the hub and showing only favorite entries in diary-date order;
- search plus category/tag filtering and clearing active filters;
- opening an original entry from the hub;
- removing a favorite and showing the appropriate empty state.

Run the full Flutter test suite, targeted static analysis, and a debug Android
APK build. The APK must continue to identify as `com.ling.diary.dev` before
any development-device installation.

## Non-goals

- Favorite timestamps or sort-by-favorite-time.
- Favorite folders, named collections, labels, or manual ordering.
- Changes to the desktop navigation or the existing timeline favorite filter.
