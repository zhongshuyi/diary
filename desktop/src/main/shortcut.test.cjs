const test = require('node:test');
const assert = require('node:assert/strict');

const {
  DEFAULT_QUICK_CAPTURE_ACCELERATOR,
  normalizeAccelerator,
  formatAccelerator,
} = require('./shortcut.cjs');

test('normalizes the desktop quick-capture shortcut across operating systems', () => {
  assert.equal(normalizeAccelerator('Ctrl + Shift + Space'), DEFAULT_QUICK_CAPTURE_ACCELERATOR);
  assert.equal(normalizeAccelerator('CommandOrControl+Shift+Space'), DEFAULT_QUICK_CAPTURE_ACCELERATOR);
});

test('rejects incomplete or unsupported quick-capture shortcuts', () => {
  assert.throws(() => normalizeAccelerator(''), /accelerator/i);
  assert.throws(() => normalizeAccelerator('Ctrl+Shift'), /accelerator/i);
  assert.throws(() => normalizeAccelerator('Alt+Space'), /accelerator/i);
});

test('formats an accelerator for the settings and tray UI', () => {
  assert.equal(formatAccelerator(DEFAULT_QUICK_CAPTURE_ACCELERATOR, 'win32'), 'Ctrl + Shift + Space');
  assert.equal(formatAccelerator(DEFAULT_QUICK_CAPTURE_ACCELERATOR, 'darwin'), '⌘ + Shift + Space');
});
