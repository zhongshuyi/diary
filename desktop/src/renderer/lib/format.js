export function dateKey(value) {
  const date = new Date(value);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function dateLabel(value, options = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }) {
  return new Intl.DateTimeFormat('zh-CN', options).format(new Date(value));
}

export function shortDateLabel(value) {
  return new Intl.DateTimeFormat('zh-CN', { month: '2-digit', day: '2-digit' }).format(new Date(value));
}

export function timeLabel(value) {
  return new Intl.DateTimeFormat('zh-CN', { hour: '2-digit', minute: '2-digit' }).format(new Date(value));
}

export function fileName(value) {
  return String(value || '').split(/[\\/]/).pop() || '未命名附件';
}

export function mediaKind(value) {
  const name = String(value || '').split(/[?#]/)[0].toLowerCase();
  if (/\.(mp4|webm|mov|mkv|avi|ogv)$/.test(name)) return 'video';
  if (/\.(mp3|wav|m4a|aac|ogg|flac|opus)$/.test(name)) return 'audio';
  return 'image';
}

export function mediaCount(entry) {
  return (entry?.imagePaths?.length || 0) + (entry?.videoPaths?.length || 0) + (entry?.audioPaths?.length || 0);
}

export function sameMonth(left, right) {
  const a = new Date(left);
  const b = new Date(right);
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth();
}

export function monthLabel(value) {
  return new Intl.DateTimeFormat('zh-CN', { year: 'numeric', month: 'long' }).format(new Date(value));
}
