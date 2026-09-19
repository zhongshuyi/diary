const test = require('node:test');
const assert = require('node:assert/strict');

test('the windowed quick-capture editor leaves closing to its title bar', async () => {
  const { shouldShowEditorClose } = await import('../renderer/lib/quick-capture-presentation.mjs');

  assert.equal(shouldShowEditorClose({ windowed: true, onClose: () => {} }), false);
});

test('the in-app editor keeps its own close control', async () => {
  const { shouldShowEditorClose } = await import('../renderer/lib/quick-capture-presentation.mjs');

  assert.equal(shouldShowEditorClose({ windowed: false, onClose: () => {} }), true);
});

test('only the windowed quick capture resets its internal scroll position after focusing', async () => {
  const { shouldResetQuickCaptureScroll } = await import('../renderer/lib/quick-capture-presentation.mjs');

  assert.equal(shouldResetQuickCaptureScroll({ windowed: true }), true);
  assert.equal(shouldResetQuickCaptureScroll({ windowed: false }), false);
});
