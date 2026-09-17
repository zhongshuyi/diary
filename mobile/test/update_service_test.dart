import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diary/application/update_service.dart';

void main() {
  test('checks the platform endpoint and detects a newer release', () async {
    Uri? requestedUri;
    final service = AppUpdateService(
      baseUrl: 'https://sync.example.com/',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'data': {
              'platform': 'mobile',
              'version': '1.1.0',
              'downloadUrl': 'https://download.example.com/diary-mobile',
              'notes': '修复同步问题',
            },
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await service.check(
      platform: 'mobile',
      currentVersion: '1.0.0',
    );

    expect(
      requestedUri.toString(),
      'https://sync.example.com/api/v1/update?platform=mobile',
    );
    expect(result.hasUpdate, isTrue);
    expect(result.latestVersion, '1.1.0');
    expect(result.notes, '修复同步问题');
  });

  test('compares numeric version segments instead of lexical strings', () {
    expect(compareAppVersions('1.10.0', '1.2.0'), greaterThan(0));
    expect(compareAppVersions('1.2.0', '1.2.0'), 0);
    expect(compareAppVersions('1.2.0', '1.10.0'), lessThan(0));
  });

  test('turns a network failure into a user-facing update error', () async {
    final service = AppUpdateService(
      client: MockClient((_) async => throw StateError('offline')),
    );

    await expectLater(
      service.check(platform: 'mobile', currentVersion: '1.0.0'),
      throwsA(isA<UpdateCheckException>()),
    );
  });
}
