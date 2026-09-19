import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/connection_settings_transfer.dart';

void main() {
  const fixture =
      'DIARY-CONNECTION:v1:eyJ2ZXJzaW9uIjoxLCJzeW5jRW5kcG9pbnQiOiJodHRwOi8vc3luYy5leGFtcGxlLmNvbSIsInN5bmNUb2tlbiI6InRva2VuLTEyMyIsInVwZGF0ZUVuZHBvaW50IjoiaHR0cHM6Ly91cGRhdGVzLmV4YW1wbGUuY29tIn0';

  test('uses the desktop-compatible v1 connection package', () {
    final settings = ConnectionSettingsTransfer.decode(fixture);

    expect(settings.syncEndpoint, 'http://sync.example.com');
    expect(settings.syncToken, 'token-123');
    expect(settings.updateEndpoint, 'https://updates.example.com');
    expect(settings.encode(), fixture);
  });

  test('rejects packages with an unsupported version', () {
    expect(
      () => ConnectionSettingsTransfer.decode(
        'DIARY-CONNECTION:v1:eyJ2ZXJzaW9uIjoyfQ',
      ),
      throwsFormatException,
    );
  });

  test('imports the readable JSON recovery format', () {
    final settings = ConnectionSettingsTransfer.decode(
      '{"version":1,"syncEndpoint":"http://sync.example.com/","syncToken":"token-123","updateEndpoint":"https://updates.example.com/"}',
    );

    expect(settings.syncEndpoint, 'http://sync.example.com');
    expect(settings.syncToken, 'token-123');
    expect(settings.updateEndpoint, 'https://updates.example.com');
  });
}
