import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/home_timeline_filter.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry entry(
  String id, {
  DateTime? occurredAt,
  String title = '日记',
  String category = '生活',
  List<String> tags = const [],
  bool isFavorite = false,
  double mood = .5,
  List<String> imagePaths = const [],
  List<String> audioPaths = const [],
  List<String> videoPaths = const [],
  bool isInTrash = false,
  bool isDeleted = false,
  bool isConflict = false,
}) {
  final createdAt = occurredAt ?? DateTime(2020, 1, 1, 9);
  return DiaryEntry(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    occurredAt: occurredAt,
    title: title,
    content: title,
    contentText: title,
    category: category,
    tags: tags,
    isFavorite: isFavorite,
    mood: mood,
    imagePaths: imagePaths,
    audioPaths: audioPaths,
    videoPaths: videoPaths,
    isInTrash: isInTrash,
    isDeleted: isDeleted,
    isConflict: isConflict,
  );
}

void main() {
  final now = DateTime(2026, 9, 20, 12);

  test('combines keyword category tags favorite date mood and media', () {
    final filter = HomeTimelineFilter(
      query: '散步',
      category: '生活',
      tags: const {'周末', '户外'},
      favoriteOnly: true,
      dateFilter: const HomeDateFilter.preset(HomeDatePreset.thisMonth),
      moodFilter: HomeMoodFilter.bright,
      mediaFilter: HomeMediaFilter.image,
    );

    expect(
      filter.matches(
        entry(
          'match',
          title: '傍晚散步',
          category: '生活',
          tags: const ['周末', '户外'],
          isFavorite: true,
          occurredAt: DateTime(2026, 9, 3),
          mood: .8,
          imagePaths: const ['walk.jpg'],
        ),
        now: now,
      ),
      isTrue,
    );
    expect(
      filter.matches(
        entry(
          'wrong-mood',
          title: '傍晚散步',
          category: '生活',
          tags: const ['周末', '户外'],
          isFavorite: true,
          occurredAt: DateTime(2026, 9, 3),
          mood: .5,
          imagePaths: const ['walk.jpg'],
        ),
        now: now,
      ),
      isFalse,
    );
  });

  test(
    'normalizes custom date ranges and clears conditions without clearing search',
    () {
      final filter = HomeTimelineFilter(
        query: '旧照片',
        category: '旅行',
        tags: const {'海边'},
        favoriteOnly: true,
        dateFilter: HomeDateFilter.custom(
          DateTime(2026, 9, 10),
          DateTime(2026, 9, 1),
        ),
        moodFilter: HomeMoodFilter.low,
        mediaFilter: HomeMediaFilter.anyMedia,
      );
      final dateOnly = HomeTimelineFilter(dateFilter: filter.dateFilter);
      final cleared = filter.clearConditions();

      expect(
        dateOnly.matches(
          entry('first', occurredAt: DateTime(2026, 9, 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        dateOnly.matches(
          entry('last', occurredAt: DateTime(2026, 9, 10, 23)),
          now: now,
        ),
        isTrue,
      );
      expect(
        dateOnly.matches(
          entry('outside', occurredAt: DateTime(2026, 9, 11)),
          now: now,
        ),
        isFalse,
      );
      expect(cleared.query, '旧照片');
      expect(cleared.hasActiveConditions, isFalse);
      expect(cleared.hidesReflections, isTrue);
    },
  );

  test(
    'matches local date presets including seven-day and yearly boundaries',
    () {
      final today = HomeTimelineFilter(
        dateFilter: const HomeDateFilter.preset(HomeDatePreset.today),
      );
      final lastSevenDays = HomeTimelineFilter(
        dateFilter: const HomeDateFilter.preset(HomeDatePreset.lastSevenDays),
      );
      final thisYear = HomeTimelineFilter(
        dateFilter: const HomeDateFilter.preset(HomeDatePreset.thisYear),
      );

      expect(
        today.matches(
          entry('today', occurredAt: DateTime(2026, 9, 20, 23)),
          now: now,
        ),
        isTrue,
      );
      expect(
        today.matches(
          entry('yesterday', occurredAt: DateTime(2026, 9, 19, 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        lastSevenDays.matches(
          entry('first-day', occurredAt: DateTime(2026, 9, 14)),
          now: now,
        ),
        isTrue,
      );
      expect(
        lastSevenDays.matches(
          entry('too-old', occurredAt: DateTime(2026, 9, 13, 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        thisYear.matches(
          entry('jan', occurredAt: DateTime(2026, 1, 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        thisYear.matches(
          entry('last-year', occurredAt: DateTime(2025, 12, 31, 23)),
          now: now,
        ),
        isFalse,
      );
    },
  );

  test('uses local calendar days for date-range boundaries', () {
    final lastSevenDays = HomeTimelineFilter(
      dateFilter: const HomeDateFilter.preset(HomeDatePreset.lastSevenDays),
    );
    final custom = HomeTimelineFilter(
      dateFilter: HomeDateFilter.custom(
        DateTime(2026, 3, 8),
        DateTime(2026, 3, 8),
      ),
    );
    final daylightSavingDay = DateTime(2026, 3, 8);
    final followingCalendarDay = DateTime(2026, 3, 9);

    expect(
      lastSevenDays.matches(
        entry('following-day', occurredAt: followingCalendarDay),
        now: daylightSavingDay,
      ),
      isFalse,
    );
    expect(
      custom.matches(
        entry('custom-following-day', occurredAt: followingCalendarDay),
        now: daylightSavingDay,
      ),
      isFalse,
    );
  });

  test('owns an immutable copy of selected tags', () {
    final sourceTags = <String>{'周末'};
    final filter = HomeTimelineFilter(tags: sourceTags);

    sourceTags.add('户外');

    expect(filter.tags, {'周末'});
    expect(() => filter.tags.add('旅行'), throwsUnsupportedError);
  });

  test('uses inclusive mood bands and the requested media kind', () {
    final low = HomeTimelineFilter(moodFilter: HomeMoodFilter.low);
    final calm = HomeTimelineFilter(moodFilter: HomeMoodFilter.calm);
    final bright = HomeTimelineFilter(moodFilter: HomeMoodFilter.bright);

    expect(low.matches(entry('low', mood: .339), now: now), isTrue);
    expect(low.matches(entry('not-low', mood: .34), now: now), isFalse);
    expect(calm.matches(entry('calm', mood: .34), now: now), isTrue);
    expect(calm.matches(entry('not-calm', mood: .67), now: now), isFalse);
    expect(bright.matches(entry('bright', mood: .67), now: now), isTrue);

    expect(
      HomeTimelineFilter(
        mediaFilter: HomeMediaFilter.anyMedia,
      ).matches(entry('any', audioPaths: const ['voice.m4a']), now: now),
      isTrue,
    );
    expect(
      HomeTimelineFilter(
        mediaFilter: HomeMediaFilter.image,
      ).matches(entry('image', imagePaths: const ['photo.jpg']), now: now),
      isTrue,
    );
    expect(
      HomeTimelineFilter(
        mediaFilter: HomeMediaFilter.audio,
      ).matches(entry('audio', audioPaths: const ['voice.m4a']), now: now),
      isTrue,
    );
    expect(
      HomeTimelineFilter(
        mediaFilter: HomeMediaFilter.video,
      ).matches(entry('video', videoPaths: const ['clip.mp4']), now: now),
      isTrue,
    );
    expect(
      HomeTimelineFilter(
        mediaFilter: HomeMediaFilter.anyMedia,
      ).matches(entry('none'), now: now),
      isFalse,
    );
  });

  test(
    'rejects trash tombstones and conflicts before evaluating conditions',
    () {
      final filter = HomeTimelineFilter();

      expect(
        filter.matches(entry('trash', isInTrash: true), now: now),
        isFalse,
      );
      expect(
        filter.matches(entry('deleted', isDeleted: true), now: now),
        isFalse,
      );
      expect(
        filter.matches(entry('conflict', isConflict: true), now: now),
        isFalse,
      );
    },
  );

  test(
    'counts advanced filters and hides reflections for active conditions',
    () {
      final filter = HomeTimelineFilter(
        dateFilter: HomeDateFilter.preset(HomeDatePreset.thisMonth),
        moodFilter: HomeMoodFilter.calm,
        mediaFilter: HomeMediaFilter.anyMedia,
      );

      expect(filter.advancedFilterCount, 3);
      expect(filter.hasActiveConditions, isTrue);
      expect(filter.hidesReflections, isTrue);
    },
  );
}
