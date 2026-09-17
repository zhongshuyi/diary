export const EDITOR_TYPES = {
  plainText: 'plain_text',
  markdown: 'markdown',
  richText: 'rich_text',
};

const editorTypeLabels = {
  [EDITOR_TYPES.plainText]: '纯文本',
  [EDITOR_TYPES.markdown]: 'Markdown',
  [EDITOR_TYPES.richText]: '富文本',
};

export function normalizeEditorType(value) {
  return Object.values(EDITOR_TYPES).includes(value) ? value : EDITOR_TYPES.plainText;
}

export function editorTypeLabel(value) {
  return editorTypeLabels[normalizeEditorType(value)];
}

export function richTextOps(value) {
  try {
    const parsed = JSON.parse(String(value || ''));
    const ops = Array.isArray(parsed) ? parsed : parsed?.ops;
    return Array.isArray(ops) ? ops.filter((op) => op && typeof op === 'object' && Object.hasOwn(op, 'insert')) : null;
  } catch {
    return null;
  }
}

function embedLabel(insert) {
  if (!insert || typeof insert !== 'object') return '';
  if (Object.hasOwn(insert, 'image')) return '[图片]';
  if (Object.hasOwn(insert, 'video')) return '[视频]';
  if (Object.hasOwn(insert, 'audio')) return '[音频]';
  return '[附件]';
}

export function richTextToPlainText(value) {
  const ops = richTextOps(value);
  if (!ops) return String(value || '');
  return ops.map((op) => typeof op.insert === 'string' ? op.insert : embedLabel(op.insert)).join('').replace(/\n$/, '');
}

export function toRichTextContent(value) {
  const ops = richTextOps(value);
  if (ops) {
    const normalized = [...ops];
    const last = normalized.at(-1)?.insert;
    if (typeof last !== 'string' || !last.endsWith('\n')) normalized.push({ insert: '\n' });
    return JSON.stringify(normalized);
  }
  const text = String(value || '');
  return JSON.stringify([{ insert: text.endsWith('\n') ? text : `${text}\n` }]);
}

export function contentText(content, editorType) {
  return normalizeEditorType(editorType) === EDITOR_TYPES.richText
    ? richTextToPlainText(content)
    : String(content || '');
}

export function entryContentText(entry) {
  const indexed = String(entry?.contentText || '');
  return indexed || contentText(entry?.content, entry?.editorType);
}

export function draftContentText(draft) {
  const indexed = String(draft?.contentText || '');
  return indexed || contentText(draft?.content, draft?.editorType);
}
