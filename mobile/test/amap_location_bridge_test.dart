import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/data/amap_location_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ling.diary/amap_location');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('AMap consent is saved once and can be revoked', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => AmapLocationBridge.pick(context, 'test-key'),
                child: const Text('选择位置'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('选择位置'));
    await tester.pumpAndSettle();
    expect(find.text('使用高德地图'), findsOneWidget);
    expect(calls, isEmpty);

    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect((calls.single.arguments as Map)['darkTheme'], true);
    expect(
      (calls.single.arguments as Map)['paperColor'],
      DiaryThemeColors.dark.paper.toARGB32(),
    );

    await tester.tap(find.text('选择位置'));
    await tester.pumpAndSettle();
    expect(find.text('使用高德地图'), findsNothing);
    expect(calls, hasLength(2));

    await AmapLocationBridge.revokeConsent();
    await tester.tap(find.text('选择位置'));
    await tester.pumpAndSettle();
    expect(find.text('使用高德地图'), findsOneWidget);
    expect(calls, hasLength(2));
    debugDefaultTargetPlatformOverride = null;
  });
}
