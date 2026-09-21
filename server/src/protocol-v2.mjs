const EDITOR_TYPES = new Set(['plain_text', 'markdown', 'rich_text']);
const ASSET_KINDS = new Set(['image', 'video', 'audio', 'file']);
const MAX_ASSET_BYTES = 128 * 1024 * 1024;

function normalizedString(value, fallback = '') {
  return typeof value === 'string' ? value : fallback;
}

function normalizedStringList(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.filter((item) => typeof item === 'string').map((item) => item.trim()).filter(Boolean))];
}

export function normalizeEntryV2(value = {}) {
  const entry = value && typeof value === 'object' ? value : {};
  const createdAt = normalizedString(entry.createdAt || entry.occurredAt, new Date().toISOString());
  const rawMood = entry.mood == null ? null : Number(entry.mood);
  const mood = rawMood == null || !Number.isFinite(rawMood) ? null : Math.min(1, Math.max(0, rawMood));
  return {
    schemaVersion: 2,
    id: normalizedString(entry.id),
    createdAt,
    occurredAt: normalizedString(entry.occurredAt, createdAt),
    updatedAt: normalizedString(entry.updatedAt, createdAt),
    deletedAt: entry.deletedAt == null ? null : normalizedString(entry.deletedAt),
    isDeleted: entry.isDeleted === true,
    title: normalizedString(entry.title),
    content: normalizedString(entry.content),
    contentText: normalizedString(entry.contentText, normalizedString(entry.content)),
    editorType: EDITOR_TYPES.has(entry.editorType) ? entry.editorType : 'plain_text',
    mood,
    moodLabel: entry.moodLabel == null ? null : (normalizedString(entry.moodLabel).trim() || null),
    category: normalizedString(entry.category, '生活'),
    tags: normalizedStringList(entry.tags),
    attachmentIds: normalizedStringList(entry.attachmentIds),
    imagePaths: Array.isArray(entry.imagePaths) ? entry.imagePaths : [],
    audioPaths: Array.isArray(entry.audioPaths) ? entry.audioPaths : [],
    videoPaths: Array.isArray(entry.videoPaths) ? entry.videoPaths : [],
    weather: normalizedStringList(entry.weather),
    positions: normalizedStringList(entry.positions),
    latitude: entry.latitude == null ? null : Number(entry.latitude),
    longitude: entry.longitude == null ? null : Number(entry.longitude),
    colorValue: Number(entry.colorValue ?? 0xffe4e0ed),
    isFavorite: entry.isFavorite === true,
    revision: Math.max(1, Number(entry.revision) || 1),
    deviceId: normalizedString(entry.deviceId),
    isConflict: entry.isConflict === true,
    conflictOf: entry.conflictOf == null ? null : normalizedString(entry.conflictOf),
    conflictStatus: entry.conflictStatus === 'resolved' ? 'resolved' : 'pending',
  };
}

export function normalizeV2Request(body = {}) {
  if (body.protocolVersion !== 2) throw Object.assign(new Error('protocolVersion must be 2'), { statusCode: 422 });
  if (typeof body.deviceId !== 'string' || body.deviceId.trim().length < 3) throw Object.assign(new Error('deviceId is required'), { statusCode: 422 });
  if (body.cursor !== undefined && !/^\d+$/.test(String(body.cursor))) throw Object.assign(new Error('cursor must be numeric'), { statusCode: 422 });
  const changes = Array.isArray(body.changes) ? body.changes : [];
  if (changes.length > 100) throw Object.assign(new Error('at most 100 changes are allowed'), { statusCode: 422 });
  const mutations = changes.map((change) => {
    if (!change || typeof change !== 'object' || typeof change.mutationId !== 'string' || !change.mutationId.trim()) throw Object.assign(new Error('mutationId is required'), { statusCode: 422 });
    const entry = normalizeEntryV2(change.entry);
    if (!entry.id) throw Object.assign(new Error('entry.id is required'), { statusCode: 422 });
    return { mutationId: change.mutationId.trim(), entry };
  });
  return {
    deviceId: body.deviceId.trim(),
    cursor: String(body.cursor ?? '0'),
    limit: Math.min(200, Math.max(1, Number(body.limit) || 100)),
    mutations,
  };
}

export function validateAssetMetadata(value = {}) {
  const details = [];
  const sha256 = normalizedString(value.sha256).toLowerCase();
  if (!/^[a-f0-9]{64}$/.test(sha256)) details.push({ field: 'sha256', message: 'Must be a SHA-256 hex digest' });
  if (!ASSET_KINDS.has(value.kind)) details.push({ field: 'kind', message: 'Unsupported asset kind' });
  if (!Number.isSafeInteger(value.byteSize) || value.byteSize < 0 || value.byteSize > MAX_ASSET_BYTES) details.push({ field: 'byteSize', message: 'Must be between 0 and 128 MB' });
  return { valid: details.length === 0, details, sha256 };
}

export { ASSET_KINDS, MAX_ASSET_BYTES };
