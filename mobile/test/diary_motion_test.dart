import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/diary_motion.dart';

void main() {
  testWidgets('keyboard inset frames do not rebuild motion consumers', (
    tester,
  ) async {
    final mediaQuery = ValueNotifier(
      const MediaQueryData(
        padding: EdgeInsets.only(bottom: 24),
        viewPadding: EdgeInsets.only(bottom: 24),
      ),
    );
    addTearDown(mediaQuery.dispose);
    var durationBuilds = 0;
    var curveBuilds = 0;
    final consumers = Column(
      children: [
        Builder(
          builder: (context) {
            durationBuilds++;
            expect(
              DiaryMotion.duration(context, DiaryMotion.standard),
              DiaryMotion.standard,
            );
            return const SizedBox();
          },
        ),
        Builder(
          builder: (context) {
            curveBuilds++;
            expect(
              DiaryMotion.curve(context, Curves.easeOutCubic),
              Curves.easeOutCubic,
            );
            return const SizedBox();
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ValueListenableBuilder<MediaQueryData>(
        valueListenable: mediaQuery,
        child: consumers,
        builder: (context, data, child) =>
            MediaQuery(data: data, child: child!),
      ),
    );

    for (final bottom in <double>[
      60,
      120,
      180,
      260,
      300,
      260,
      180,
      120,
      60,
      0,
    ]) {
      mediaQuery.value = mediaQuery.value.copyWith(
        viewInsets: EdgeInsets.only(bottom: bottom),
        padding: EdgeInsets.only(bottom: bottom == 0 ? 24 : 0),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(durationBuilds, 1);
    expect(curveBuilds, 1);
  });

  testWidgets('motion consumers respond to reduced motion changes', (
    tester,
  ) async {
    final mediaQuery = ValueNotifier(const MediaQueryData());
    addTearDown(mediaQuery.dispose);
    var builds = 0;
    Duration? duration;
    Curve? curve;
    final consumer = Builder(
      builder: (context) {
        builds++;
        duration = DiaryMotion.duration(context, DiaryMotion.standard);
        curve = DiaryMotion.curve(context, Curves.easeOutCubic);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      ValueListenableBuilder<MediaQueryData>(
        valueListenable: mediaQuery,
        child: consumer,
        builder: (context, data, child) =>
            MediaQuery(data: data, child: child!),
      ),
    );

    expect(duration, DiaryMotion.standard);
    expect(curve, Curves.easeOutCubic);

    mediaQuery.value = mediaQuery.value.copyWith(disableAnimations: true);
    await tester.pump();
    expect(builds, 2);
    expect(duration, Duration.zero);
    expect(curve, Curves.linear);

    mediaQuery.value = mediaQuery.value.copyWith(disableAnimations: false);
    await tester.pump();
    expect(builds, 3);
    expect(duration, DiaryMotion.standard);
    expect(curve, Curves.easeOutCubic);
  });

  testWidgets('motion helpers allow contexts without MediaQuery', (
    tester,
  ) async {
    Duration? duration;
    Curve? curve;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          expect(MediaQuery.maybeOf(context), isNull);
          duration = DiaryMotion.duration(context, DiaryMotion.emphasized);
          curve = DiaryMotion.curve(context, Curves.easeInOutCubic);
          return View(view: tester.view, child: const SizedBox());
        },
      ),
      wrapWithView: false,
    );

    expect(duration, DiaryMotion.emphasized);
    expect(curve, Curves.easeInOutCubic);
    expect(tester.takeException(), isNull);
  });
}
