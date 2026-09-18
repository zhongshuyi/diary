import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer as createHttpServer } from 'node:http';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, extname, resolve } from 'node:path';
import { SyncStore } from './store.mjs';
import { AssetStore } from './asset-store.mjs';
import { normalizeV2Request } from './protocol-v2.mjs';
import { readUpdateMetadata } from './update-manifest.mjs';

const serverRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const defaultDataFile = resolve(serverRoot, 'data', 'sync-store.json');
const MAX_BODY_BYTES = 2 * 1024 * 1024;
const defaultUpdateManifestFile = resolve(serverRoot, 'data', 'update-manifest.json');
const defaultReleaseDirectory = resolve(serverRoot, 'data', 'releases');
const releaseFileNamePattern = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

function jsonResponse(res, status, body) {
  const payload = JSON.stringify(body);
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Content-Length', Buffer.byteLength(payload));
  res.end(payload);
}

function errorBody(code, message, details = []) {
  return { error: { code, message, details } };
}

function releaseContentType(fileName) {
  switch (extname(fileName).toLowerCase()) {
    case '.apk': return 'application/vnd.android.package-archive';
    case '.exe': return 'application/vnd.microsoft.portable-executable';
    default: return 'application/octet-stream';
  }
}

async function serveReleaseDownload(res, releaseDirectory, fileName) {
  if (!releaseFileNamePattern.test(fileName)) {
    jsonResponse(res, 404, errorBody('release_not_found', 'Release file not found'));
    return;
  }

  const filePath = resolve(releaseDirectory, fileName);
  try {
    const info = await stat(filePath);
    if (!info.isFile()) throw new Error('not a file');
    res.statusCode = 200;
    res.setHeader('Content-Type', releaseContentType(fileName));
    res.setHeader('Content-Length', info.size);
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    createReadStream(filePath).on('error', () => res.destroy()).pipe(res);
  } catch {
    jsonResponse(res, 404, errorBody('release_not_found', 'Release file not found'));
  }
}

async function readJson(req) {
  return new Promise((resolveBody, reject) => {
    let size = 0;
    let body = '';

    req.setEncoding('utf8');
    req.on('data', (chunk) => {
      size += Buffer.byteLength(chunk);
      if (size > MAX_BODY_BYTES) {
        const error = new Error('Request body is too large');
        error.statusCode = 413;
        reject(error);
        req.destroy();
        return;
      }
      body += chunk;
    });
    req.on('end', () => {
      if (!body.trim()) {
        resolveBody({});
        return;
      }
      try {
        resolveBody(JSON.parse(body));
      } catch {
        const error = new Error('Request body must be valid JSON');
        error.statusCode = 400;
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

function normalizeEntry(value) {
  const entry = { ...value };
  return {
    schemaVersion: entry.schemaVersion ?? 1,
    id: entry.id,
    createdAt: entry.createdAt,
    updatedAt: entry.updatedAt,
    title: entry.title ?? '',
    content: entry.content ?? '',
    contentText: entry.contentText ?? entry.content ?? '',
    editorType: entry.editorType ?? 'plain_text',
    mood: Number(entry.mood ?? 0.5),
    category: entry.category ?? '生活',
    tags: Array.isArray(entry.tags) ? entry.tags : [],
    imagePaths: Array.isArray(entry.imagePaths) ? entry.imagePaths : [],
    audioPaths: Array.isArray(entry.audioPaths) ? entry.audioPaths : [],
    videoPaths: Array.isArray(entry.videoPaths) ? entry.videoPaths : [],
    weather: Array.isArray(entry.weather) ? entry.weather : [],
    positions: Array.isArray(entry.positions) ? entry.positions : [],
    latitude: entry.latitude ?? null,
    longitude: entry.longitude ?? null,
    colorValue: Number(entry.colorValue ?? 0xffe4e0ed),
    isFavorite: entry.isFavorite === true,
    isInTrash: entry.isInTrash === true,
    ...entry,
  };
}

function validateRequest(body) {
  const details = [];
  if (body.protocolVersion !== 1) {
    details.push({ field: 'protocolVersion', message: 'Must be 1' });
  }
  if (typeof body.deviceId !== 'string' || body.deviceId.trim().length < 3) {
    details.push({ field: 'deviceId', message: 'Required' });
  }
  if (body.cursor !== undefined && !/^\d+$/.test(String(body.cursor))) {
    details.push({ field: 'cursor', message: 'Must be a numeric cursor' });
  }
  if (!Array.isArray(body.changes)) {
    details.push({ field: 'changes', message: 'Must be an array' });
  } else if (body.changes.length > 100) {
    details.push({ field: 'changes', message: 'At most 100 changes per request' });
  }

  const mutations = [];
  if (Array.isArray(body.changes)) {
    body.changes.forEach((change, index) => {
      if (!change || typeof change !== 'object') {
        details.push({ field: `changes.${index}`, message: 'Must be an object' });
        return;
      }
      if (typeof change.mutationId !== 'string' || !change.mutationId.trim()) {
        details.push({ field: `changes.${index}.mutationId`, message: 'Required' });
      }
      if (!change.entry || typeof change.entry !== 'object') {
        details.push({ field: `changes.${index}.entry`, message: 'Required' });
        return;
      }
      const entry = normalizeEntry(change.entry);
      if (typeof entry.id !== 'string' || !entry.id.trim()) {
        details.push({ field: `changes.${index}.entry.id`, message: 'Required' });
      }
      if (typeof entry.createdAt !== 'string' || Number.isNaN(Date.parse(entry.createdAt))) {
        details.push({ field: `changes.${index}.entry.createdAt`, message: 'Must be an ISO date' });
      }
      if (typeof entry.updatedAt !== 'string' || Number.isNaN(Date.parse(entry.updatedAt))) {
        details.push({ field: `changes.${index}.entry.updatedAt`, message: 'Must be an ISO date' });
      }
      if (!['plain_text', 'markdown', 'rich_text'].includes(entry.editorType)) {
        details.push({ field: `changes.${index}.entry.editorType`, message: 'Unsupported editor type' });
      }
      if (!Number.isFinite(entry.mood) || entry.mood < 0 || entry.mood > 1) {
        details.push({ field: `changes.${index}.entry.mood`, message: 'Must be between 0 and 1' });
      }
      if (typeof entry.title !== 'string' || typeof entry.content !== 'string') {
        details.push({ field: `changes.${index}.entry.content`, message: 'Text fields must be strings' });
      }
      if (typeof change.mutationId === 'string' && entry.id) {
        mutations.push({ mutationId: change.mutationId, entry });
      }
    });
  }

  return { details, mutations };
}

export function createServer({
  storeFile = process.env.SYNC_DATA_FILE || defaultDataFile,
  authToken = process.env.SYNC_AUTH_TOKEN || '',
  updateManifestFile = process.env.UPDATE_MANIFEST_FILE || defaultUpdateManifestFile,
  releaseDirectory = process.env.RELEASE_DIRECTORY || defaultReleaseDirectory,
} = {}) {
  const resolvedStoreFile = resolve(serverRoot, storeFile);
  const resolvedUpdateManifestFile = resolve(serverRoot, updateManifestFile);
  const resolvedReleaseDirectory = resolve(serverRoot, releaseDirectory);
  const store = new SyncStore(resolvedStoreFile);
  const assets = new AssetStore(resolve(dirname(resolvedStoreFile), 'assets'));
  const server = createHttpServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, PUT, POST, OPTIONS');

    if (req.method === 'OPTIONS') {
      res.statusCode = 204;
      res.end();
      return;
    }

    if (req.url === '/health' && req.method === 'GET') {
      jsonResponse(res, 200, { data: { status: 'ok', service: 'diary-sync', protocolVersion: 1 } });
      return;
    }

    try {
      const requestUrl = new URL(req.url || '/', 'http://diary.local');
      if (requestUrl.pathname.startsWith('/downloads/') && req.method === 'GET') {
        await serveReleaseDownload(res, resolvedReleaseDirectory, requestUrl.pathname.slice('/downloads/'.length));
        return;
      }
      if (requestUrl.pathname === '/api/v1/update' && req.method === 'GET') {
        const platform = requestUrl.searchParams.get('platform');
        if (!platform) {
          jsonResponse(res, 400, errorBody('platform_required', 'Platform is required'));
          return;
        }
        try {
          const data = await readUpdateMetadata(resolvedUpdateManifestFile, platform);
          jsonResponse(res, 200, { data });
        } catch (error) {
          jsonResponse(res, error.statusCode || 500, errorBody(error.code || 'update_unavailable', error.message));
        }
        return;
      }
    } catch {
      jsonResponse(res, 400, errorBody('bad_request', 'Request URL is invalid'));
      return;
    }

    if (authToken && req.headers.authorization !== `Bearer ${authToken}`) {
      jsonResponse(res, 401, errorBody('unauthorized', 'Valid bearer token required'));
      return;
    }

    try {
      const requestUrl = new URL(req.url || '/', 'http://diary.local');
      if (requestUrl.pathname === '/api/v2/sync' && req.method === 'POST') {
        const body = await readJson(req);
        const normalized = normalizeV2Request(body);
        const result = await store.apply({ ...normalized, protocolVersion: 2 });
        jsonResponse(res, 200, { data: result, meta: { protocolVersion: 2 } });
        return;
      }

      const assetMatch = requestUrl.pathname.match(/^\/api\/v2\/assets\/([a-f0-9]{64})$/i);
      if (assetMatch && ['HEAD', 'GET', 'PUT'].includes(req.method)) {
        const sha256 = assetMatch[1].toLowerCase();
        if (req.method === 'HEAD') {
          const result = await assets.head(sha256);
          res.statusCode = result.exists ? 200 : 404;
          if (result.exists) res.setHeader('Content-Length', result.byteSize);
          res.end();
          return;
        }
        if (req.method === 'GET') {
          try {
            const result = await assets.open(sha256);
            res.statusCode = 200;
            res.setHeader('Content-Type', result.mimeType);
            res.setHeader('Content-Length', result.byteSize);
            result.stream.on('error', () => res.destroy());
            result.stream.pipe(res);
          } catch (error) {
            if (error.code === 'ENOENT') jsonResponse(res, 404, errorBody('asset_not_found', 'Asset not found'));
            else throw error;
          }
          return;
        }
        const byteSize = req.headers['content-length'] == null ? undefined : Number(req.headers['content-length']);
        const result = await assets.put({
          sha256,
          kind: String(req.headers['x-asset-kind'] || 'file'),
          mimeType: String(req.headers['content-type'] || 'application/octet-stream'),
          byteSize: Number.isFinite(byteSize) ? byteSize : undefined,
          body: req,
        });
        jsonResponse(res, 201, { data: result, meta: { protocolVersion: 2 } });
        return;
      }

      if (req.url !== '/api/v1/sync' || req.method !== 'POST') {
        jsonResponse(res, 404, errorBody('not_found', 'Route not found'));
        return;
      }

      const body = await readJson(req);
      const { details, mutations } = validateRequest(body);
      if (details.length > 0) {
        jsonResponse(res, 422, errorBody('validation_error', 'Request validation failed', details));
        return;
      }
      const result = await store.apply({
        deviceId: body.deviceId.trim(),
        cursor: String(body.cursor ?? '0'),
        limit: Math.min(Math.max(Number(body.limit) || 100, 1), 200),
        mutations,
      });
      jsonResponse(res, 200, {
        data: result,
        meta: { protocolVersion: 1 },
      });
    } catch (error) {
      const statusCode = error.statusCode || 500;
      const code = statusCode === 413
        ? 'payload_too_large'
        : statusCode === 422
          ? 'validation_error'
          : statusCode === 400
            ? 'bad_request'
            : 'internal_error';
      const details = error.details || [];
      jsonResponse(res, statusCode, errorBody(code, statusCode === 500 ? 'Internal server error' : error.message, details));
    }
  });

  return { server, store, assets };
}

export function resolveListenHost(environment = process.env) {
  const configuredHost = environment.HOST?.trim();
  return configuredHost || '127.0.0.1';
}

export async function startServer() {
  const port = Number(process.env.PORT || 8787);
  const host = resolveListenHost();
  const { server, store } = createServer();
  await store.init();
  await new Promise((resolveListen) => server.listen(port, host, resolveListen));
  console.log(`Diary sync server listening on http://${host}:${port}`);
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
