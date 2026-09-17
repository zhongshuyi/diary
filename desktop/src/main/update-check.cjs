const DEFAULT_UPDATE_SERVER_URL = 'http://127.0.0.1:8787';

function parseVersion(value) {
  const normalized = String(value || '').trim().replace(/^v/i, '');
  const match = normalized.match(/^(\d+(?:\.\d+){0,3})(?:-([0-9A-Za-z.-]+))?$/);
  if (!match) throw new Error(`Invalid app version: ${value}`);
  return {
    core: match[1].split('.').map(Number),
    prerelease: match[2] ? match[2].split('.') : [],
  };
}

function compareIdentifiers(left, right) {
  const leftNumeric = /^\d+$/.test(left);
  const rightNumeric = /^\d+$/.test(right);
  if (leftNumeric && rightNumeric) return Number(left) - Number(right);
  if (leftNumeric !== rightNumeric) return leftNumeric ? -1 : 1;
  return left < right ? -1 : left > right ? 1 : 0;
}

function compareVersions(left, right) {
  const leftVersion = parseVersion(left);
  const rightVersion = parseVersion(right);
  for (let index = 0; index < 4; index += 1) {
    const difference = (leftVersion.core[index] || 0) - (rightVersion.core[index] || 0);
    if (difference) return difference > 0 ? 1 : -1;
  }
  if (!leftVersion.prerelease.length && !rightVersion.prerelease.length) return 0;
  if (!leftVersion.prerelease.length) return 1;
  if (!rightVersion.prerelease.length) return -1;
  for (let index = 0; index < Math.max(leftVersion.prerelease.length, rightVersion.prerelease.length); index += 1) {
    if (leftVersion.prerelease[index] === undefined) return -1;
    if (rightVersion.prerelease[index] === undefined) return 1;
    const difference = compareIdentifiers(leftVersion.prerelease[index], rightVersion.prerelease[index]);
    if (difference) return difference > 0 ? 1 : -1;
  }
  return 0;
}

function isUpdateAvailable(currentVersion, latestVersion) {
  return compareVersions(latestVersion, currentVersion) > 0;
}

function updateEndpoint(baseUrl, platform) {
  const configured = String(baseUrl || DEFAULT_UPDATE_SERVER_URL).trim().replace(/\/+$/, '');
  const serverBase = configured.replace(/\/api\/v\d+\/(?:sync|update)$/, '');
  return `${serverBase}/api/v1/update?platform=${encodeURIComponent(platform)}`;
}

async function checkForUpdate({ baseUrl, platform = 'desktop', currentVersion, fetchImpl = globalThis.fetch, timeoutMs = 8000 } = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  let response;
  try {
    response = await fetchImpl(updateEndpoint(baseUrl, platform), {
      headers: { Accept: 'application/json' },
      signal: controller.signal,
    });
  } catch (error) {
    if (error?.name === 'AbortError') throw new Error('Update check timed out');
    throw error;
  } finally {
    clearTimeout(timeout);
  }
  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new Error('Update server returned invalid JSON');
  }
  if (!response.ok) {
    throw new Error(payload?.error?.message || `Update check failed (${response.status})`);
  }
  const data = payload?.data;
  if (!data || typeof data.version !== 'string' || typeof data.downloadUrl !== 'string') {
    throw new Error('Update server returned incomplete metadata');
  }
  return {
    platform: data.platform || platform,
    currentVersion,
    latestVersion: data.version,
    downloadUrl: data.downloadUrl,
    notes: typeof data.notes === 'string' ? data.notes : '',
    hasUpdate: isUpdateAvailable(currentVersion, data.version),
  };
}

function isSafeExternalUrl(value) {
  try {
    return ['http:', 'https:'].includes(new URL(String(value || '')).protocol);
  } catch {
    return false;
  }
}

module.exports = {
  compareVersions,
  isUpdateAvailable,
  checkForUpdate,
  isSafeExternalUrl,
  updateEndpoint,
};
