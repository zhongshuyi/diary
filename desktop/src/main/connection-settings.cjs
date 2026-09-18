const DEFAULT_SYNC_ENDPOINT = 'http://127.0.0.1:8787';

function normalizeEndpoint(value) {
  return String(value || '').trim().replace(/\/+$/, '');
}

function normalizeConnectionSettings(settings = {}) {
  return {
    syncEndpoint: normalizeEndpoint(settings.syncEndpoint || settings.serverUrl || DEFAULT_SYNC_ENDPOINT),
    syncToken: String(settings.syncToken || ''),
    updateEndpoint: normalizeEndpoint(settings.updateEndpoint),
  };
}

function createSyncRequest({ baseUrl, token, body }) {
  const configuredBaseUrl = normalizeEndpoint(baseUrl || DEFAULT_SYNC_ENDPOINT);
  const url = configuredBaseUrl.endsWith('/sync')
    ? configuredBaseUrl
    : `${configuredBaseUrl}/api/v2/sync`;
  const headers = { 'Content-Type': 'application/json' };
  if (String(token || '').trim()) headers.Authorization = `Bearer ${String(token).trim()}`;
  return { url, headers, body: JSON.stringify(body || {}) };
}

function createUpdateCheck({ updateEndpoint }) {
  return { baseUrl: normalizeEndpoint(updateEndpoint) };
}

module.exports = {
  DEFAULT_SYNC_ENDPOINT,
  normalizeConnectionSettings,
  createSyncRequest,
  createUpdateCheck,
};
