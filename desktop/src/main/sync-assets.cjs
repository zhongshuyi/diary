const path = require('node:path');

const ASSET_URL = /^asset:\/\/([a-f0-9]{64})(\.[a-z0-9]{1,16})?$/i;

function parsePortableAssetPath(value) {
  const match = ASSET_URL.exec(String(value || ''));
  if (!match) return null;
  return { sha256: match[1].toLowerCase(), extension: (match[2] || '').toLowerCase() };
}

function portableAssetPath(asset) {
  const extension = path.extname(String(asset?.localPath || asset?.originalName || '')).toLowerCase();
  return `asset://${asset.sha256}${/^\.[a-z0-9]{1,16}$/.test(extension) ? extension : ''}`;
}

function comparablePath(value) {
  return path.resolve(String(value || '')).toLowerCase();
}

function buildPortableSyncEntry(entry, assets = []) {
  const byPath = new Map(assets.filter((asset) => asset?.localPath && asset?.sha256).map((asset) => [comparablePath(asset.localPath), asset]));
  const attachmentIds = [...new Set([...(Array.isArray(entry?.attachmentIds) ? entry.attachmentIds : []), ...assets.map((asset) => asset?.id).filter(Boolean)])];
  const replace = (value) => {
    const asset = byPath.get(comparablePath(value));
    return asset ? portableAssetPath(asset) : value;
  };
  return {
    ...entry,
    attachmentIds,
    imagePaths: (entry?.imagePaths || []).map(replace),
    audioPaths: (entry?.audioPaths || []).map(replace),
    videoPaths: (entry?.videoPaths || []).map(replace),
  };
}

function hydratePortableEntry(entry, resolveAsset) {
  const replace = (value) => {
    const asset = parsePortableAssetPath(value);
    return asset ? resolveAsset(asset) : value;
  };
  return {
    ...entry,
    imagePaths: (entry?.imagePaths || []).map(replace),
    audioPaths: (entry?.audioPaths || []).map(replace),
    videoPaths: (entry?.videoPaths || []).map(replace),
  };
}

module.exports = { buildPortableSyncEntry, hydratePortableEntry, parsePortableAssetPath, portableAssetPath };
