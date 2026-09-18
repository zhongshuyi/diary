const test = require('node:test');
const assert = require('node:assert/strict');

let connectionSettings;
try {
  connectionSettings = require('./connection-settings.cjs');
} catch {
  connectionSettings = null;
}

test('migrates the legacy server URL into protected sync settings', () => {
  assert.ok(connectionSettings, 'connection settings should be available');
  assert.deepEqual(
    connectionSettings.normalizeConnectionSettings({
      serverUrl: 'https://sync.example.com/',
    }),
    {
      syncEndpoint: 'https://sync.example.com',
      syncToken: '',
      updateEndpoint: '',
    },
  );
});

test('keeps the bearer token out of the public update configuration', () => {
  assert.ok(connectionSettings, 'connection settings should be available');
  assert.deepEqual(
    connectionSettings.createSyncRequest({
      baseUrl: 'https://sync.example.com/',
      token: 'private-sync-token',
      body: { cursor: '0' },
    }),
    {
      url: 'https://sync.example.com/api/v2/sync',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer private-sync-token',
      },
      body: JSON.stringify({ cursor: '0' }),
    },
  );
  assert.deepEqual(
    connectionSettings.createUpdateCheck({
      updateEndpoint: 'https://updates.example.com/',
    }),
    { baseUrl: 'https://updates.example.com' },
  );
});
