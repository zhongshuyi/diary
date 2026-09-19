const CONNECTION_PREFIX = 'DIARY-CONNECTION:v1:';

function normalizeEndpoint(value) {
  return String(value ?? '').trim().replace(/\/+$/, '');
}

function validateEndpoint(value, label) {
  const endpoint = normalizeEndpoint(value);
  if (!endpoint) return endpoint;

  let parsed;
  try {
    parsed = new URL(endpoint);
  } catch {
    throw new Error(`${label}必须是完整的 http:// 或 https:// 地址`);
  }
  if (!['http:', 'https:'].includes(parsed.protocol) || !parsed.hostname) {
    throw new Error(`${label}必须是完整的 http:// 或 https:// 地址`);
  }
  return endpoint;
}

function normalizeConnectionSettings(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('连接配置必须是一个对象');
  }
  for (const key of ['syncEndpoint', 'syncToken', 'updateEndpoint']) {
    if (typeof value[key] !== 'string') throw new Error(`连接配置缺少 ${key}`);
  }
  return {
    syncEndpoint: validateEndpoint(value.syncEndpoint, '同步服务地址'),
    syncToken: value.syncToken.trim(),
    updateEndpoint: validateEndpoint(value.updateEndpoint, '公开更新地址'),
  };
}

function encodeConnectionSettings(value) {
  const settings = normalizeConnectionSettings(value);
  const payload = JSON.stringify({ version: 1, ...settings });
  return `${CONNECTION_PREFIX}${Buffer.from(payload, 'utf8').toString('base64url')}`;
}

function decodeConnectionSettings(value) {
  const source = String(value ?? '').trim();
  let payloadText = source;
  if (source.startsWith(CONNECTION_PREFIX)) {
    const encoded = source.slice(CONNECTION_PREFIX.length);
    if (!encoded || !/^[A-Za-z0-9_-]+$/.test(encoded)) throw new Error('连接配置编码无效');
    payloadText = Buffer.from(encoded, 'base64url').toString('utf8');
  }

  let payload;
  try {
    payload = JSON.parse(payloadText);
  } catch {
    throw new Error('连接配置不是有效的 JSON');
  }
  if (payload?.version !== 1) throw new Error('不支持的连接配置版本');
  return normalizeConnectionSettings(payload);
}

module.exports = {
  CONNECTION_PREFIX,
  decodeConnectionSettings,
  encodeConnectionSettings,
};
