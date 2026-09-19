const { buildPortableSyncEntry, parsePortableAssetPath } = require('./sync-assets.cjs');

const ASSET_FIELDS = ['imagePaths', 'audioPaths', 'videoPaths'];

function transferableAssets(assets) {
  return (Array.isArray(assets) ? assets : []).filter((asset) => asset?.state === 'ready' && typeof asset.localPath === 'string' && asset.localPath && typeof asset.sha256 === 'string');
}

async function prepareSyncBody(body, { listAssets, uploadAsset } = {}) {
  if (typeof listAssets !== 'function' || typeof uploadAsset !== 'function') throw new TypeError('Asset sync handlers are required');
  const changes = await Promise.all((Array.isArray(body?.changes) ? body.changes : []).map(async (change) => {
    if (!change?.entry || typeof change.entry !== 'object') return change;
    const assets = transferableAssets(await listAssets(change.entry.id));
    for (const asset of assets) await uploadAsset(asset);
    return { ...change, entry: buildPortableSyncEntry(change.entry, assets) };
  }));
  return { ...(body || {}), changes };
}

async function hydratePortableEntry(entry, downloadAsset, downloads) {
  if (!entry || typeof entry !== 'object') return entry;
  const resolve = async (value) => {
    const asset = parsePortableAssetPath(value);
    if (!asset) return value;
    const key = `${asset.sha256}${asset.extension}`;
    if (!downloads.has(key)) downloads.set(key, Promise.resolve(downloadAsset(asset)));
    return downloads.get(key);
  };
  const hydrated = { ...entry };
  for (const field of ASSET_FIELDS) {
    hydrated[field] = await Promise.all((Array.isArray(entry[field]) ? entry[field] : []).map(resolve));
  }
  return hydrated;
}

async function hydrateSyncData(data, { downloadAsset } = {}) {
  if (typeof downloadAsset !== 'function') throw new TypeError('Asset download handler is required');
  const downloads = new Map();
  const hydrateChange = async (change) => ({ ...change, entry: await hydratePortableEntry(change?.entry, downloadAsset, downloads) });
  const hydrateConflict = async (conflict) => ({
    ...conflict,
    entry: await hydratePortableEntry(conflict?.entry, downloadAsset, downloads),
    serverEntry: await hydratePortableEntry(conflict?.serverEntry, downloadAsset, downloads),
  });
  return {
    ...(data || {}),
    changes: await Promise.all((Array.isArray(data?.changes) ? data.changes : []).map(hydrateChange)),
    conflicts: await Promise.all((Array.isArray(data?.conflicts) ? data.conflicts : []).map(hydrateConflict)),
  };
}

module.exports = { hydrateSyncData, prepareSyncBody };
