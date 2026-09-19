const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const packageJson = require('../../package.json');

test('Windows package embeds the branded Diary ICO in its executable and shortcuts', () => {
  const iconPath = path.join(__dirname, '..', '..', 'resources', 'diary.ico');

  assert.equal(packageJson.build.win.icon, 'resources/diary.ico');
  assert.equal(fs.existsSync(iconPath), true);
  assert.ok(fs.statSync(iconPath).size > 1024);
});
