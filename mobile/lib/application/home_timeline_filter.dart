import 'package:diary/domain/diary_entry.dart';

enum HomeDatePreset { all, today, lastSevenDays, thisMonth, thisYear, custom }

enum HomeMoodFilter { all, low, calm, bright }

enum HomeMediaFilter { all, anyMedia, image, audio, video }

class HomeDateFilter {
  const HomeDateFilter.all()
    : preset = HomeDatePreset.all,
      start = null,
      end = null;

  const HomeDateFilter.preset(this.preset)
    : assert(preset != HomeDatePreset.custom),
      start = null,
      end = null;

  HomeDateFilter.custom(DateTime first, DateTime second)
    : preset = HomeDatePreset.custom,
      start = _earlierLocalDay(first, second),
      end = _laterLocalDay(first, second);

  final HomeDatePreset preset;
  final DateTime? start;
  final DateTime? end;

  bool get isActive => preset != HomeDatePreset.all;

  bool matches(DateTime occurredAt, {required DateTime now}) {
    final day = _startOfLocalDay(occurredAt);
    final today = _startOfLocalDay(now);
    return switch (preset) {
      HomeDatePreset.all => true,
      HomeDatePreset.today => day == today,
      HomeDatePreset.lastSevenDays =>
        !day.isBefore(_localCalendarDayOffset(today, -6)) &&
            day.isBefore(_localCalendarDayOffset(today, 1)),
      HomeDatePreset.thisMonth =>
        day.year == today.year && day.month == today.month,
      HomeDatePreset.thisYear => day.year == today.year,
      HomeDatePreset.custom =>
        start != null &&
            end != null &&
            !day.isBefore(start!) &&
            day.isBefore(_localCalendarDayOffset(end!, 1)),
    };
  }
}

class HomeTimelineFilter {
  HomeTimelineFilter({
    this.query = '',
    this.category = '全部',
    Set<String> tags = const <String>{},
    this.favoriteOnly = false,
    this.dateFilter = const HomeDateFilter.all(),
    this.moodFilter = HomeMoodFilter.all,
    this.mediaFilter = HomeMediaFilter.all,
  }) : tags = Set.unmodifiable(tags);

  final String query;
  final String category;
  final Set<String> tags;
  final bool favoriteOnly;
  final HomeDateFilter dateFilter;
  final HomeMoodFilter moodFilter;
  final HomeMediaFilter mediaFilter;

  bool get hasActiveConditions =>
      category != '全部' ||
      tags.isNotEmpty ||
      favoriteOnly ||
      dateFilter.isActive ||
      moodFilter != HomeMoodFilter.all ||
      mediaFilter != HomeMediaFilter.all;

  int get advancedFilterCount => [
    dateFilter.isActive,
    moodFilter != HomeMoodFilter.all,
    mediaFilter != HomeMediaFilter.all,
  ].where((value) => value).length;

  bool get hidesReflections => query.trim().isNotEmpty || hasActiveConditions;

  bool matches(DiaryEntry entry, {required DateTime now}) {
    if (entry.isInTrash || entry.isDeleted || entry.isConflict) return false;
    if (!entry.matches(query)) return false;
    if (category != '全部' && entry.category != category) return false;
    if (!tags.every(entry.tags.contains)) return false;
    if (favoriteOnly && !entry.isFavorite) return false;
    if (!dateFilter.matches(entry.effectiveOccurredAt, now: now)) return false;
    if (!_matchesMood(entry.mood)) return false;
    return _matchesMedia(entry);
  }

  HomeTimelineFilter copyWith({
    String? query,
    String? category,
    Set<String>? tags,
    bool? favoriteOnly,
    HomeDateFilter? dateFilter,
    HomeMoodFilter? moodFilter,
    HomeMediaFilter? mediaFilter,
  }) {
    return HomeTimelineFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      dateFilter: dateFilter ?? this.dateFilter,
      moodFilter: moodFilter ?? this.moodFilter,
      mediaFilter: mediaFilter ?? this.mediaFilter,
    );
  }

  HomeTimelineFilter clearConditions() => HomeTimelineFilter(query: query);

  bool _matchesMood(double mood) {
    return switch (moodFilter) {
      HomeMoodFilter.all => true,
      HomeMoodFilter.low => mood >= 0 && mood < .34,
      HomeMoodFilter.calm => mood >= .34 && mood < .67,
      HomeMoodFilter.bright => mood >= .67 && mood <= 1,
    };
  }

  bool _matchesMedia(DiaryEntry entry) {
    return switch (mediaFilter) {
      HomeMediaFilter.all => true,
      HomeMediaFilter.anyMedia => entry.hasMedia && !entry.isStandaloneLocation,
      HomeMediaFilter.image =>
        entry.imagePaths.isNotEmpty && !entry.isStandaloneLocation,
      HomeMediaFilter.audio => entry.audioPaths.isNotEmpty,
      HomeMediaFilter.video => entry.videoPaths.isNotEmpty,
    };
  }
}

DateTime _startOfLocalDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _localCalendarDayOffset(DateTime localDay, int days) {
  return DateTime(localDay.year, localDay.month, localDay.day + days);
}

DateTime _earlierLocalDay(DateTime first, DateTime second) {
  final firstDay = _startOfLocalDay(first);
  final secondDay = _startOfLocalDay(second);
  return firstDay.isAfter(secondDay) ? secondDay : firstDay;
}

DateTime _laterLocalDay(DateTime first, DateTime second) {
  final firstDay = _startOfLocalDay(first);
  final secondDay = _startOfLocalDay(second);
  return firstDay.isAfter(secondDay) ? firstDay : secondDay;
}
