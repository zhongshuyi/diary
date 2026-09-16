import { createHash } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { mkdir, open, rename, stat, unlink } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { Readable } from 'node:stream';
import { MAX_ASSET_BYTES, validateAssetMetadata } from './protocol-v2.mjs';

function safeSha(value) {
  const sha = String(value || '').toLowerCase();
  if (!/^[a-f0-9]{64}$/.test(sha)) throw Object.assign(new Error('Invalid asset SHA-256'), { statusCode: 422 });
  return sha;
}

export class AssetStore {
  constructor(rootPath) {
    this.rootPath = resolve(rootPath);
  }

  pathFor(sha256) {
    return join(this.rootPath, safeSha(sha256));
  }

  async head(sha256) {
    const target = this.pathFor(sha256);
    try {
      const info = await stat(target);
      return { exists: info.isFile(), byteSize: info.size };
    } catch (error) {
      if (error.code === 'ENOENT') return { exists: false, byteSize: 0 };
      throw error;
    }
  }

  async put({ sha256, kind = 'file', mimeType = 'application/octet-stream', byteSize, body }) {
    const metadata = { sha256, kind, byteSize: Number.isSafeInteger(byteSize) ? byteSize : 0 };
    const validation = validateAssetMetadata(metadata);
    if (!validation.valid) throw Object.assign(new Error('Invalid asset metadata'), { statusCode: 422, details: validation.details });
    if (!body || typeof body[Symbol.asyncIterator] !== 'function') throw Object.assign(new Error('Asset body is required'), { statusCode: 400 });

    await mkdir(this.rootPath, { recursive: true });
    const target = this.pathFor(validation.sha256);
    const temporary = `${target}.${process.pid}.${Date.now()}.tmp`;
    const handle = await open(temporary, 'w');
    const hash = createHash('sha256');
    let size = 0;
    try {
      for await (const chunk of body) {
        const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
        size += buffer.byteLength;
        if (size > MAX_ASSET_BYTES) throw Object.assign(new Error('Asset is too large'), { statusCode: 413 });
        hash.update(buffer);
        await handle.write(buffer);
      }
      await handle.close();
      if (Number.isSafeInteger(byteSize) && size !== byteSize) throw Object.assign(new Error('Asset size mismatch'), { statusCode: 422 });
      if (hash.digest('hex') !== validation.sha256) throw Object.assign(new Error('Asset SHA-256 mismatch'), { statusCode: 422 });
      const existing = await this.head(validation.sha256);
      if (!existing.exists) await rename(temporary, target);
      else await unlink(temporary);
      return { sha256: validation.sha256, byteSize: size, mimeType, kind };
    } catch (error) {
      try { await handle.close(); } catch { /* preserve original error */ }
      try { await unlink(temporary); } catch { /* cleanup is best effort */ }
      throw error;
    }
  }

  async open(sha256) {
    const target = this.pathFor(sha256);
    const info = await stat(target);
    return { stream: createReadStream(target), byteSize: info.size, mimeType: 'application/octet-stream' };
  }

  async putBuffer({ sha256, kind, mimeType, buffer }) {
    return this.put({ sha256, kind, mimeType, byteSize: buffer.byteLength, body: Readable.from([buffer]) });
  }
}
