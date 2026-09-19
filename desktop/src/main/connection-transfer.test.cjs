const test = require('node:test');
const assert = require('node:assert/strict');

const {
  decodeConnectionSettings,
  encodeConnectionSettings,
} = require('./connection-transfer.cjs');

const FIXTURE = 'DIARY-CONNECTION:v1:eyJ2ZXJzaW9uIjoxLCJzeW5jRW5kcG9pbnQiOiJodHRwOi8vc3luYy5leGFtcGxlLmNvbSIsInN5bmNUb2tlbiI6InRva2VuLTEyMyIsInVwZGF0ZUVuZHBvaW50IjoiaHR0cHM6Ly91cGRhdGVzLmV4YW1wbGUuY29tIn0';

test('encodes and decodes the portable v1 connection package', () => {
  assert.equal(
    encodeConnectionSettings({
      syncEndpoint: 'http://sync.example.com/',
      syncToken: 'token-123',
      updateEndpoint: 'https://updates.example.com/',
    }),
    FIXTURE,
  );

  assert.deepEqual(decodeConnectionSettings(FIXTURE), {
    syncEndpoint: 'http://sync.example.com',
    syncToken: 'token-123',
    updateEndpoint: 'https://updates.example.com',
  });
});

test('rejects an invalid connection package without returning a partial configuration', () => {
  assert.throws(
    () => decodeConnectionSettings('DIARY-CONNECTION:v1:eyJ2ZXJzaW9uIjoyfQ'),
    /版本|version/i,
  );
});

test('imports the readable JSON recovery format', () => {
  assert.deepEqual(
    decodeConnectionSettings('{"version":1,"syncEndpoint":"http://sync.example.com/","syncToken":"token-123","updateEndpoint":"https://updates.example.com/"}'),
    {
      syncEndpoint: 'http://sync.example.com',
      syncToken: 'token-123',
      updateEndpoint: 'https://updates.example.com',
    },
  );
});
