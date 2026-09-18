import assert from 'node:assert/strict';
import test from 'node:test';

import { resolveListenHost } from '../src/server.mjs';

test('uses HOST when the sync service must accept public traffic', () => {
  assert.equal(resolveListenHost({ HOST: '0.0.0.0' }), '0.0.0.0');
  assert.equal(resolveListenHost({}), '127.0.0.1');
});
