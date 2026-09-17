const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const { getDesktopIconPath } = require('./app-icon.cjs');

test('resolves the shared desktop logo asset', () => {
  const sourceDirectory = path.resolve(__dirname, '..');
  const iconPath = getDesktopIconPath(sourceDirectory);

  assert.equal(
    iconPath,
    path.join(sourceDirectory, 'renderer', 'brand', 'diary_logo.png'),
  );
  assert.equal(fs.existsSync(iconPath), true);
});
