const test = require('node:test');
const assert = require('node:assert/strict');

const { restoreQuickCaptureBounds } = require('./window-bounds.cjs');

const displays = [
  { bounds: { x: 0, y: 0, width: 1920, height: 1080 } },
  { bounds: { x: 1920, y: 0, width: 2560, height: 1440 } },
];

test('keeps saved quick-capture bounds when a monitor still contains them', () => {
  const saved = { x: 2100, y: 180, width: 560, height: 520 };
  assert.deepEqual(restoreQuickCaptureBounds(saved, displays), saved);
});

test('centers quick capture on the primary display when saved bounds are off-screen', () => {
  assert.deepEqual(restoreQuickCaptureBounds({ x: -3000, y: -1800, width: 560, height: 520 }, displays), { x: 580, y: 200, width: 760, height: 680 });
});

test('enforces the quick-capture compact layout minimum size', () => {
  assert.deepEqual(
    restoreQuickCaptureBounds({ x: 40, y: 40, width: 120, height: 150 }, displays),
    { x: 40, y: 40, width: 560, height: 500 },
  );
});
