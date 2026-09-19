const test = require('node:test');
const assert = require('node:assert/strict');

const { shouldRefreshMainAfterSave } = require('./quick-capture-events.cjs');

test('notifies the main window only when a quick-capture window saves a record', () => {
  assert.equal(shouldRefreshMainAfterSave({ senderId: 22, quickCaptureWindowId: 22 }), true);
  assert.equal(shouldRefreshMainAfterSave({ senderId: 11, quickCaptureWindowId: 22 }), false);
  assert.equal(shouldRefreshMainAfterSave({ senderId: 11, quickCaptureWindowId: null }), false);
});
