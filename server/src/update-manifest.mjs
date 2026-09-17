import { readFile } from 'node:fs/promises';

const URL_PROTOCOLS = new Set(['http:', 'https:']);

function updateError(code, message, statusCode) {
  const error = new Error(message);
  error.code = code;
  error.statusCode = statusCode;
  return error;
}

function normalizeUpdate(platform, value) {
  if (!value || typeof value !== 'object') {
    throw updateError('update_unavailable', `Invalid update metadata for ${platform}`, 500);
  }

  const version = String(value.version || '').trim().replace(/^v/i, '');
  const downloadUrl = String(value.downloadUrl || '').trim();
  if (!/^\d+(?:\.\d+){0,3}(?:-[0-9A-Za-z.-]+)?$/.test(version)) {
    throw updateError('update_unavailable', `Invalid update version for ${platform}`, 500);
  }
  try {
    if (!URL_PROTOCOLS.has(new URL(downloadUrl).protocol)) throw new Error('unsupported protocol');
  } catch {
    throw updateError('update_unavailable', `Invalid update download URL for ${platform}`, 500);
  }

  return {
    platform,
    version,
    downloadUrl,
    notes: String(value.notes || '').trim(),
  };
}

export async function readUpdateMetadata(manifestFile, platform) {
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestFile, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw updateError('update_not_found', 'No update metadata has been published', 404);
    }
    throw updateError('update_unavailable', 'Update metadata is unavailable', 500);
  }

  const value = manifest?.platforms?.[platform];
  if (!value) throw updateError('update_not_found', `No update metadata for ${platform}`, 404);
  return normalizeUpdate(platform, value);
}
