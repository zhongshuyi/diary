const path = require('node:path');

function getDesktopIconPath(sourceDirectory) {
  return path.join(sourceDirectory, 'renderer', 'brand', 'diary_logo.png');
}

module.exports = { getDesktopIconPath };
