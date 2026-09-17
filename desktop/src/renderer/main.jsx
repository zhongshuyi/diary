import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { CalendarView } from './components/CalendarView';
import { ConflictView } from './components/ConflictView';
import { EntriesView, RecycleBinView } from './components/EntriesView';
import { InsightsView } from './components/InsightsView';
import { LibraryView } from './components/LibraryView';
import { MediaViewer } from './components/MediaViewer';
import { PlaceholderView } from './components/PlaceholderView';
import { QuickCapture } from './components/QuickCapture';
import { SettingsView } from './components/SettingsView';
import { SidebarRail } from './components/SidebarRail';
import { TagsView } from './components/TagsView';
import { Titlebar } from './components/Titlebar';
import { TodayView } from './components/TodayView';
import { WorkspaceHeader } from './components/WorkspaceHeader';
import { dateKey, mediaKind } from './lib/format';
import './styles.css';

const STORAGE = {
  entries: 'diary.desktop.entries.v1',
  outbox: 'diary.desktop.outbox.v1',
  cursor: 'diary.desktop.cursor.v1',
  deviceId: 'diary.desktop.device-id.v1',
  theme: 'diary.desktop.theme.v1',
  serverUrl: 'diary.desktop.server-url.v1',
};
const PREVIEW_DRAFT = 'diary.desktop.preview-draft.v1';

function previewDraftKey(id = 'main') {
  return id === 'main' ? PREVIEW_DRAFT : `${PREVIEW_DRAFT}.${id}`;
}

const PLACEHOLDERS = {
};

function loadJson(key, fallback) {
  try {
    const value = JSON.parse(localStorage.getItem(key) || 'null');
    return value ?? fallback;
  } catch {
    return fallback;
  }
}

function createId(prefix) {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function buildDateTime(day) {
  const now = new Date();
  const value = new Date(`${day}T${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`);
  return Number.isNaN(value.getTime()) ? now.toISOString() : value.toISOString();
}

function previewSnapshot() {
  return {
    entries: loadJson(STORAGE.entries, []),
    entryCount: loadJson(STORAGE.entries, []).length,
    outbox: loadJson(STORAGE.outbox, []),
    cursor: localStorage.getItem(STORAGE.cursor) || '0',
    deviceId: localStorage.getItem(STORAGE.deviceId) || createId('preview'),
    settings: { theme: localStorage.getItem(STORAGE.theme) || 'light', serverUrl: localStorage.getItem(STORAGE.serverUrl) || 'http://127.0.0.1:8787' },
    draft: loadJson(PREVIEW_DRAFT, null),
  };
}

const previewDb = {
  async bootstrap() { return { migrated: false, snapshot: previewSnapshot() }; },
  async snapshot() { return previewSnapshot(); },
  async listEntries({ includeTrash = true, limit = 500, offset = 0 } = {}) { return previewSnapshot().entries.filter((entry) => includeTrash || !entry.isInTrash).slice(offset, offset + limit); },
  async search(query, options = {}) {
    const normalizedQuery = String(query || '').trim().toLowerCase();
    const includeTrash = options.includeTrash === true;
    const tags = Array.isArray(options.tags) ? options.tags.filter(Boolean) : [];
    const from = String(options.dateFrom || '').slice(0, 10);
    const to = String(options.dateTo || '').slice(0, 10);
    const matches = previewSnapshot().entries.filter((entry) => {
      if (!includeTrash && entry.isInTrash) return false;
      const occurred = String(entry.occurredAt || entry.createdAt || '').slice(0, 10);
      if (from && occurred < from) return false;
      if (to && occurred > to) return false;
      if (options.category && entry.category !== options.category) return false;
      if (tags.some((tag) => !(entry.tags || []).includes(tag))) return false;
      if (options.favorite === true && !entry.isFavorite) return false;
      if (options.mood !== undefined && options.mood !== '' && Number(entry.mood) !== Number(options.mood)) return false;
      if (options.attachmentKind) {
        const paths = [...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])];
        if (options.attachmentKind === 'any' && !paths.length) return false;
        if (['image', 'video', 'audio'].includes(options.attachmentKind) && !paths.some((path) => mediaKind(path) === options.attachmentKind)) return false;
      }
      if (!normalizedQuery) return true;
      return `${entry.title || ''} ${entry.contentText || entry.content || ''} ${entry.category || ''} ${(entry.tags || []).join(' ')}`.toLowerCase().includes(normalizedQuery);
    }).sort((left, right) => new Date(right.occurredAt || right.createdAt) - new Date(left.occurredAt || left.createdAt));
    const limit = Math.min(500, Math.max(1, Number(options.limit) || 100));
    const offset = Math.max(0, Number(options.offset) || 0);
    return matches.slice(offset, offset + limit);
  },
  async taxonomyUsage() {
    const entries = previewSnapshot().entries;
    return { categories: usageOptions(entries, 'category', defaultCategories), tags: usageOptions(entries, 'tags') };
  },
  async attachmentHealth() {
    const entries = previewSnapshot().entries;
    const paths = entries.flatMap((entry) => [...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])]);
    return { total: paths.length, ready: paths.length, missing: 0, orphaned: 0 };
  },
  async saveEntry(entry) {
    const current = previewSnapshot();
    const nextEntries = [entry, ...current.entries.filter((item) => item.id !== entry.id)];
    const mutation = { mutationId: `${current.deviceId}:${entry.id}:${entry.updatedAt}`, entry };
    const nextOutbox = [...current.outbox.filter((item) => item.entry?.id !== entry.id), mutation];
    localStorage.setItem(STORAGE.entries, JSON.stringify(nextEntries));
    localStorage.setItem(STORAGE.outbox, JSON.stringify(nextOutbox));
    return { entry, snapshot: previewSnapshot() };
  },
  async saveDraft(draft) { localStorage.setItem(previewDraftKey(draft?.id), JSON.stringify(draft)); return previewSnapshot(); },
  async loadDraft(id = 'main') { return loadJson(previewDraftKey(id), null); },
  async clearDraft(id = 'main') { localStorage.removeItem(previewDraftKey(id)); return previewSnapshot(); },
  async saveSetting(key, value) { if (key === 'theme') localStorage.setItem(STORAGE.theme, value); if (key === 'serverUrl') localStorage.setItem(STORAGE.serverUrl, value); return previewSnapshot(); },
  async applySync({ changes = [], conflicts = [], acknowledgedMutationIds = [], cursor = null } = {}) {
    const current = previewSnapshot();
    let entries = [...current.entries];
    [...changes.map((change) => change.entry), ...conflicts.map((conflict) => conflict.serverEntry)].filter(Boolean).forEach((remote) => {
      const local = entries.find((entry) => entry.id === remote.id);
      if (!local || new Date(remote.updatedAt) >= new Date(local.updatedAt)) entries = [remote, ...entries.filter((entry) => entry.id !== remote.id)];
    });
    const acknowledged = new Set(acknowledgedMutationIds);
    const outbox = current.outbox.filter((mutation) => !acknowledged.has(mutation.mutationId));
    localStorage.setItem(STORAGE.entries, JSON.stringify(entries));
    localStorage.setItem(STORAGE.outbox, JSON.stringify(outbox));
    if (cursor !== null && cursor !== undefined) localStorage.setItem(STORAGE.cursor, String(cursor));
    localStorage.setItem('diary.desktop.conflicts.v1', JSON.stringify(conflicts));
    return previewSnapshot();
  },
  async listConflicts() { return loadJson('diary.desktop.conflicts.v1', []); },
  async resolveConflict({ conflictId, resolution }) {
    const current = await previewDb.listConflicts();
    const next = current.filter((item) => item.conflictId !== conflictId);
    localStorage.setItem('diary.desktop.conflicts.v1', JSON.stringify(next));
    return (await previewDb.saveEntry({ ...resolution, isConflict: false, conflictStatus: 'resolved', updatedAt: new Date().toISOString() })).snapshot;
  },
  async trashEntry(id) {
    const current = previewSnapshot();
    const entry = current.entries.find((item) => item.id === id);
    if (!entry) return current;
    const updatedAt = new Date().toISOString();
    return (await previewDb.saveEntry({ ...entry, updatedAt, deletedAt: updatedAt, isInTrash: true })).snapshot;
  },
  async restoreEntry(id) {
    const current = previewSnapshot();
    const entry = current.entries.find((item) => item.id === id);
    if (!entry) return current;
    return (await previewDb.saveEntry({ ...entry, updatedAt: new Date().toISOString(), deletedAt: null, isInTrash: false })).snapshot;
  },
  async deleteEntry(id) {
    const current = previewSnapshot();
    const entry = current.entries.find((item) => item.id === id);
    if (!entry || !entry.isInTrash) return current;
    localStorage.setItem(STORAGE.entries, JSON.stringify(current.entries.filter((item) => item.id !== id)));
    localStorage.setItem(STORAGE.outbox, JSON.stringify(current.outbox.filter((item) => item.entry?.id !== id)));
    return previewSnapshot();
  },
  async batchFavorite(ids, isFavorite) {
    let snapshot = previewSnapshot();
    for (const id of [...new Set(ids || [])]) {
      const entry = snapshot.entries.find((item) => item.id === id && !item.isInTrash);
      if (!entry || Boolean(entry.isFavorite) === Boolean(isFavorite)) continue;
      snapshot = (await previewDb.saveEntry({ ...entry, updatedAt: new Date().toISOString(), isFavorite: Boolean(isFavorite) })).snapshot;
    }
    return snapshot;
  },
  async batchTrash(ids) {
    let snapshot = previewSnapshot();
    for (const id of [...new Set(ids || [])]) {
      const entry = snapshot.entries.find((item) => item.id === id && !item.isInTrash);
      if (!entry) continue;
      const updatedAt = new Date().toISOString();
      snapshot = (await previewDb.saveEntry({ ...entry, updatedAt, deletedAt: updatedAt, isInTrash: true })).snapshot;
    }
    return snapshot;
  },
  async batchRestore(ids) {
    let snapshot = previewSnapshot();
    for (const id of [...new Set(ids || [])]) {
      const entry = snapshot.entries.find((item) => item.id === id && item.isInTrash);
      if (!entry) continue;
      snapshot = (await previewDb.saveEntry({ ...entry, updatedAt: new Date().toISOString(), deletedAt: null, isInTrash: false })).snapshot;
    }
    return snapshot;
  },
  async batchOrganize(ids, options = {}) {
    let snapshot = previewSnapshot();
    const additions = [...new Set((options.addTags || []).filter(Boolean))];
    const removals = new Set((options.removeTags || []).filter(Boolean));
    for (const id of [...new Set(ids || [])]) {
      const entry = snapshot.entries.find((item) => item.id === id && !item.isInTrash);
      if (!entry) continue;
      const nextTags = [...new Set([...(entry.tags || []).filter((tag) => !removals.has(tag)), ...additions])];
      const nextCategory = options.category === undefined ? entry.category : (options.category || '未分类');
      if (nextCategory === entry.category && nextTags.length === (entry.tags || []).length && nextTags.every((tag, index) => tag === entry.tags[index])) continue;
      snapshot = (await previewDb.saveEntry({ ...entry, category: nextCategory, tags: nextTags, updatedAt: new Date().toISOString() })).snapshot;
    }
    return snapshot;
  },
  async renameTag(from, to) {
    const source = String(from || '').trim();
    const target = String(to || '').trim();
    if (!source || !target) throw new Error('标签名不能为空');
    let snapshot = previewSnapshot();
    for (const entry of snapshot.entries) {
      if (!(entry.tags || []).includes(source)) continue;
      const tags = [...new Set((entry.tags || []).map((tag) => tag === source ? target : tag))];
      snapshot = (await previewDb.saveEntry({ ...entry, tags, updatedAt: new Date().toISOString() })).snapshot;
    }
    return snapshot;
  },
  async deleteTag(value) {
    const target = String(value || '').trim();
    if (!target) throw new Error('标签名不能为空');
    let snapshot = previewSnapshot();
    for (const entry of snapshot.entries) {
      if (!(entry.tags || []).includes(target)) continue;
      snapshot = (await previewDb.saveEntry({ ...entry, tags: (entry.tags || []).filter((tag) => tag !== target), updatedAt: new Date().toISOString() })).snapshot;
    }
    return snapshot;
  },
  async renameCategory(from, to) {
    const source = String(from || '').trim();
    const target = String(to || '').trim() || '未分类';
    if (!source) throw new Error('分类名不能为空');
    let snapshot = previewSnapshot();
    for (const entry of snapshot.entries) {
      if ((entry.category || '生活') !== source) continue;
      snapshot = (await previewDb.saveEntry({ ...entry, category: target, updatedAt: new Date().toISOString() })).snapshot;
    }
    return snapshot;
  },
  async deleteCategory(value) {
    const target = String(value || '').trim();
    if (!target) throw new Error('分类名不能为空');
    let snapshot = previewSnapshot();
    for (const entry of snapshot.entries) {
      if ((entry.category || '生活') !== target) continue;
      snapshot = (await previewDb.saveEntry({ ...entry, category: '未分类', updatedAt: new Date().toISOString() })).snapshot;
    }
    return snapshot;
  },
};

function databaseAPI() {
  return globalThis.diaryAPI?.db || previewDb;
}

function defaultDraft(date = new Date()) {
  return { date: dateKey(date), title: '', content: '', category: '生活', mood: '0.7', moodSet: false, tags: [] };
}

const defaultCategories = ['生活', '灵感', '心情', '工作'];
const emptySearchFilters = { category: '', tags: [], mood: '', favorite: false, attachmentKind: '', dateFrom: '', dateTo: '' };
const SEARCH_PAGE_SIZE = 200;

function usageOptions(entries, field, defaults = []) {
  const usage = new Map(defaults.map((value) => [value, { value, count: 0, latest: 0 }]));
  entries.filter((entry) => !entry.isInTrash).forEach((entry) => {
    const values = field === 'tags' ? (Array.isArray(entry.tags) ? entry.tags : []) : [entry.category || '生活'];
    const latest = Date.parse(entry.occurredAt || entry.updatedAt || entry.createdAt) || 0;
    values.filter(Boolean).forEach((value) => {
      const current = usage.get(value) || { value, count: 0, latest: 0 };
      current.count += 1;
      current.latest = Math.max(current.latest, latest);
      usage.set(value, current);
    });
  });
  return [...usage.values()].sort((left, right) => right.count - left.count || right.latest - left.latest || left.value.localeCompare(right.value, 'zh-CN')).map((item) => item.value);
}

function hasSearchFilters(filters) {
  return Object.values(filters || {}).some((value) => Array.isArray(value) ? value.length > 0 : Boolean(value));
}

function App() {
  const [entries, setEntries] = useState([]);
  const [entryCount, setEntryCount] = useState(0);
  const [loadingMore, setLoadingMore] = useState(false);
  const [outbox, setOutbox] = useState([]);
  const [conflicts, setConflicts] = useState([]);
  const [cursor, setCursor] = useState('0');
  const [deviceId, setDeviceId] = useState('');
  const [theme, setTheme] = useState(() => localStorage.getItem(STORAGE.theme) || 'light');
  const [serverUrl, setServerUrl] = useState(() => localStorage.getItem(STORAGE.serverUrl) || 'http://127.0.0.1:8787');
  const [bootstrapped, setBootstrapped] = useState(false);
  const [view, setView] = useState('timeline');
  const [search, setSearch] = useState('');
  const [searchResults, setSearchResults] = useState(null);
  const [searchLoading, setSearchLoading] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [searchHasMore, setSearchHasMore] = useState(false);
  const [searchFilters, setSearchFilters] = useState(emptySearchFilters);
  const [taxonomy, setTaxonomy] = useState(null);
  const [attachmentHealth, setAttachmentHealth] = useState(null);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [composerOpen, setComposerOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [attachments, setAttachments] = useState([]);
  const [draft, setDraft] = useState(() => defaultDraft());
  const [syncState, setSyncState] = useState({ kind: '', label: '仅本地保存' });
  const [mediaViewer, setMediaViewer] = useState(null);
  const [toast, setToast] = useState({ message: '', action: null });
  const stateRef = useRef({ entries, searchResults, outbox, conflicts, cursor, serverUrl, deviceId, bootstrapped, syncing: false });
  const toastTimer = useRef(null);

  useEffect(() => { stateRef.current = { entries, searchResults, outbox, conflicts, cursor, serverUrl, deviceId, bootstrapped, syncing: stateRef.current.syncing }; }, [entries, searchResults, outbox, conflicts, cursor, serverUrl, deviceId, bootstrapped]);
  useEffect(() => { document.body.classList.toggle('dark', theme === 'dark'); if (bootstrapped) void databaseAPI().saveSetting('theme', theme); }, [theme, bootstrapped]);
  useEffect(() => { if (outbox.length) setSyncState({ kind: 'error', label: `${outbox.length} 条待同步` }); }, [outbox.length]);
  useEffect(() => {
    if (!bootstrapped) return undefined;
    let active = true;
    databaseAPI().taxonomyUsage?.().then((result) => { if (active && result) setTaxonomy(result); }).catch(() => {});
    databaseAPI().attachmentHealth?.().then((result) => { if (active && result) setAttachmentHealth(result); }).catch(() => {});
    return () => { active = false; };
  }, [bootstrapped, entries]);

  const showToast = (message, action = null) => { setToast({ message, action }); window.clearTimeout(toastTimer.current); toastTimer.current = window.setTimeout(() => setToast({ message: '', action: null }), 2400); };
  useEffect(() => {
    let active = true;
    const legacyState = {
      entries: loadJson(STORAGE.entries, []),
      outbox: loadJson(STORAGE.outbox, []),
      cursor: localStorage.getItem(STORAGE.cursor) || '0',
      deviceId: localStorage.getItem(STORAGE.deviceId) || createId('desktop'),
      settings: { theme: localStorage.getItem(STORAGE.theme) || 'light', serverUrl: localStorage.getItem(STORAGE.serverUrl) || 'http://127.0.0.1:8787' },
    };
    databaseAPI().bootstrap(legacyState).then((result) => {
      if (!active || !result?.snapshot) return;
      const snapshot = result.snapshot;
      setEntries(snapshot.entries || []);
      setEntryCount(snapshot.entryCount ?? snapshot.entries?.length ?? 0);
      setOutbox(snapshot.outbox || []);
      setCursor(snapshot.cursor || '0');
      setDeviceId(snapshot.deviceId || legacyState.deviceId);
      if (snapshot.settings?.theme) setTheme(snapshot.settings.theme);
      if (snapshot.settings?.serverUrl) setServerUrl(snapshot.settings.serverUrl);
      if (snapshot.draft?.payload) {
        const recovered = snapshot.draft.payload;
        setDraft({ ...defaultDraft(), ...recovered });
        setAttachments(Array.isArray(recovered.attachments) ? recovered.attachments : []);
        setEditingId(recovered.editingId || null);
        if (recovered.content || recovered.title || recovered.attachments?.length) setComposerOpen(Boolean(recovered.editingId));
      }
      setBootstrapped(true);
    }).catch(() => {
      if (active) { setBootstrapped(true); setSyncState({ kind: 'error', label: '本地数据库不可用' }); }
    });
    return () => { active = false; };
  }, []);

  useEffect(() => {
    if (!bootstrapped) return undefined;
    const hasContent = Boolean(draft.content.trim() || draft.title.trim() || attachments.length);
    if (!hasContent) return undefined;
    const timer = window.setTimeout(() => {
      void databaseAPI().saveDraft({ id: 'main', entryId: editingId, payload: { ...draft, attachments, editingId } });
    }, 500);
    return () => window.clearTimeout(timer);
  }, [bootstrapped, draft, attachments, editingId]);

  useEffect(() => {
    if (!bootstrapped) return undefined;
    const normalizedQuery = search.trim();
    const active = normalizedQuery.length > 0 || hasSearchFilters(searchFilters);
    if (!active) {
      setSearchResults(null);
      setSearchHasMore(false);
      setSearchError('');
      setSearchLoading(false);
      return undefined;
    }
    let cancelled = false;
    const timer = window.setTimeout(async () => {
      setSearchLoading(true);
      setSearchError('');
      try {
        const result = await databaseAPI().search?.(normalizedQuery, { ...searchFilters, includeTrash: view === 'recycle', limit: SEARCH_PAGE_SIZE, offset: 0 });
        if (cancelled) return;
        const next = Array.isArray(result) ? result : [];
        setSearchResults(next);
        setSearchHasMore(next.length === SEARCH_PAGE_SIZE);
      } catch (error) {
        if (!cancelled) {
          setSearchResults([]);
          setSearchHasMore(false);
          setSearchError(error?.message || '本地搜索不可用');
        }
      } finally {
        if (!cancelled) setSearchLoading(false);
      }
    }, 180);
    return () => { cancelled = true; window.clearTimeout(timer); };
  }, [bootstrapped, search, searchFilters, view, entries]);

  const openComposer = (date = new Date()) => { setEditingId(null); setAttachments([]); setDraft(defaultDraft(date)); setComposerOpen(true); };
  const findEntry = (id) => stateRef.current.entries.find((item) => item.id === id) || stateRef.current.searchResults?.find((item) => item.id === id);
  const editEntry = (id) => { const entry = findEntry(id); if (!entry) return; setEditingId(id); setAttachments([...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])]); setDraft({ ...defaultDraft(new Date(entry.occurredAt || entry.createdAt)), title: entry.title === '未命名的一刻' ? '' : entry.title, content: entry.contentText || entry.content || '', category: entry.category || '生活', mood: String(entry.mood ?? 0.7), moodSet: entry.moodSet === true || entry.mood !== null, tags: entry.tags || [] }); setComposerOpen(true); };

  const syncNow = async () => {
    if (stateRef.current.syncing || !stateRef.current.bootstrapped || !stateRef.current.deviceId) return;
    const persisted = await databaseAPI().snapshot();
    const current = { ...stateRef.current, ...(persisted || {}) };
    if (persisted) {
      setEntries(persisted.entries || []);
      setOutbox(persisted.outbox || []);
      setConflicts(persisted.conflicts || await databaseAPI().listConflicts?.() || []);
      setCursor(persisted.cursor || current.cursor);
      stateRef.current = { ...stateRef.current, ...persisted };
    }
    stateRef.current.syncing = true;
    setSyncState({ kind: 'syncing', label: '正在同步…' });
    try {
      if (!globalThis.diaryAPI?.sync) return;
      const result = await globalThis.diaryAPI.sync({ baseUrl: current.serverUrl, body: { protocolVersion: 2, deviceId: current.deviceId, cursor: current.cursor, limit: 100, client: { platform: 'desktop', appVersion: globalThis.diaryAPI.appVersion || 'preview' }, changes: current.outbox } });
      if (!result.ok) throw new Error(result.body?.error?.message || '同步服务不可用');
      const data = result.body.data;
      const done = new Set([...(data.appliedMutationIds || []), ...(data.conflicts || []).map((conflict) => conflict.mutationId)]);
      const nextCursor = data.nextCursor || stateRef.current.cursor;
      const snapshot = await databaseAPI().applySync({ changes: data.changes || [], conflicts: data.conflicts || [], acknowledgedMutationIds: [...done], cursor: nextCursor });
      const nextOutbox = snapshot?.outbox || [];
      setEntries(snapshot?.entries || []); setOutbox(nextOutbox); setCursor(snapshot?.cursor || nextCursor);
      const nextConflicts = snapshot?.conflicts || await databaseAPI().listConflicts?.() || data.conflicts || [];
      setConflicts(nextConflicts);
      setSyncState({ kind: data.conflicts?.length ? 'conflict' : '', label: data.conflicts?.length ? `${data.conflicts.length} 个待处理冲突` : nextOutbox.length ? `${nextOutbox.length} 条待同步` : '已同步' });
      if (data.conflicts?.length) showToast('发现版本差异，已保留双方版本');
    } catch { setSyncState({ kind: 'error', label: stateRef.current.outbox.length ? '本地已保存 · 待同步' : '仅本地保存' }); }
    finally { stateRef.current.syncing = false; }
  };

  const saveEntry = async ({ inline = false } = {}) => {
    const contentText = draft.content.trim();
    if (!contentText && attachments.length === 0) { showToast('写几句话，或添加一个附件'); document.querySelector('#inline-content-input, #content-input')?.focus(); return; }
    const current = stateRef.current;
    if (!current.bootstrapped || !current.deviceId) { showToast('本地数据库正在准备，请稍后再试'); return; }
    const existing = current.entries.find((entry) => entry.id === editingId);
    const now = new Date().toISOString();
    const imagePaths = attachments.filter((path) => mediaKind(path) === 'image');
    const videoPaths = attachments.filter((path) => mediaKind(path) === 'video');
    const audioPaths = attachments.filter((path) => mediaKind(path) === 'audio');
    const entry = { schemaVersion: 1, id: editingId || createId('entry'), createdAt: existing?.createdAt || buildDateTime(draft.date), occurredAt: buildDateTime(draft.date), updatedAt: now, title: draft.title.trim(), content: contentText, contentText, editorType: 'plain_text', mood: draft.moodSet ? Number(draft.mood) : null, moodSet: draft.moodSet === true, category: draft.category, tags: draft.tags || existing?.tags || [], imagePaths, audioPaths, videoPaths, weather: existing?.weather || [], positions: existing?.positions || [], latitude: existing?.latitude ?? null, longitude: existing?.longitude ?? null, colorValue: existing?.colorValue || 0xffe4e0ed, isFavorite: existing?.isFavorite || false, isInTrash: false };
    try {
      const result = await databaseAPI().saveEntry(entry);
      if (!result?.snapshot) throw new Error('本地保存失败');
      setEntries(result.snapshot.entries || []);
      setEntryCount(result.snapshot.entryCount ?? result.snapshot.entries?.length ?? 0);
      setOutbox(result.snapshot.outbox || []);
      setCursor(result.snapshot.cursor || current.cursor);
      setComposerOpen(false); setEditingId(null);
      setAttachments([]); setDraft(defaultDraft());
      await databaseAPI().clearDraft('main');
      showToast(existing ? '已更新这篇日记' : '已记下这一刻');
      window.setTimeout(syncNow, 0);
    } catch { showToast('本地保存失败，草稿仍保留在编辑器中'); }
  };

  const applySnapshot = (snapshot) => {
    if (!snapshot) return;
    setEntries(snapshot.entries || []);
    setEntryCount(snapshot.entryCount ?? snapshot.entries?.length ?? 0);
    setOutbox(snapshot.outbox || []);
    setConflicts(snapshot.conflicts || []);
    setCursor(snapshot.cursor || stateRef.current.cursor);
    stateRef.current = { ...stateRef.current, entries: snapshot.entries || [], outbox: snapshot.outbox || [], conflicts: snapshot.conflicts || [], cursor: snapshot.cursor || stateRef.current.cursor };
  };

  const updateTaxonomy = async (action, successMessage) => {
    try {
      const result = await action();
      if (!result?.entries) throw new Error('组织关系保存失败');
      applySnapshot(result);
      showToast(successMessage);
      return result;
    } catch (error) {
      showToast(error?.message || '组织关系保存失败');
      throw error;
    }
  };
  const renameTagValue = (from, to) => updateTaxonomy(() => databaseAPI().renameTag?.(from, to), `已将标签“${from}”重命名为“${to}”`);
  const deleteTagValue = (value) => updateTaxonomy(() => databaseAPI().deleteTag?.(value), `已移除标签“${value}”`);
  const renameCategoryValue = (from, to) => updateTaxonomy(() => databaseAPI().renameCategory?.(from, to), `已将分类“${from}”重命名为“${to}”`);
  const deleteCategoryValue = (value) => updateTaxonomy(() => databaseAPI().deleteCategory?.(value), `已将分类“${value}”下的记录归入未分类`);

  const toggleFavorite = async (id) => {
    const entry = findEntry(id);
    if (!entry) return;
    try {
      const result = await databaseAPI().saveEntry({ ...entry, updatedAt: new Date().toISOString(), isFavorite: !entry.isFavorite });
      applySnapshot(result?.snapshot);
      showToast(entry.isFavorite ? '已取消收藏' : '已加入收藏');
    } catch { showToast('收藏状态保存失败'); }
  };

  const copyEntry = async (id) => {
    const entry = findEntry(id);
    if (!entry) return;
    const now = new Date().toISOString();
    try {
      const result = await databaseAPI().saveEntry({ ...entry, id: createId('entry'), createdAt: now, occurredAt: now, updatedAt: now, deletedAt: null, isInTrash: false, isFavorite: false, revision: 1 });
      applySnapshot(result?.snapshot);
      showToast('已复制为新记录');
    } catch { showToast('复制失败'); }
  };

  const trashEntry = async (id) => {
    try {
      const result = await databaseAPI().trashEntry(id);
      applySnapshot(result);
      showToast('已移入回收站', { label: '撤销', run: () => restoreEntry(id) });
    } catch { showToast('移入回收站失败'); }
  };

  const restoreEntry = async (id) => {
    try {
      const result = await databaseAPI().restoreEntry(id);
      applySnapshot(result);
      showToast('已恢复记录');
    } catch { showToast('恢复失败'); }
  };

  const permanentlyDelete = async (id) => {
    if (!window.confirm('永久删除这条记录？正文、搜索索引和待同步变更都会被移除，无法撤销。')) return;
    try {
      const result = await databaseAPI().deleteEntry(id);
      applySnapshot(result);
      showToast('记录已永久删除');
    } catch { showToast('永久删除失败'); }
  };

  const batchAction = async (action, ids) => {
    const uniqueIds = [...new Set(ids || [])];
    if (!uniqueIds.length) return;
    try {
      if (action?.type === 'favorite') {
        const result = await databaseAPI().batchFavorite?.(uniqueIds, action.value);
        applySnapshot(result);
        showToast(action.value ? `已收藏 ${uniqueIds.length} 条记录` : `已取消 ${uniqueIds.length} 条收藏`);
      }
      if (action?.type === 'trash') {
        const result = await databaseAPI().batchTrash?.(uniqueIds);
        applySnapshot(result);
        showToast(`已移入回收站 ${uniqueIds.length} 条`, { label: '撤销', run: () => batchRestore(uniqueIds) });
      }
      if (action?.type === 'organize') {
        const result = await databaseAPI().batchOrganize?.(uniqueIds, action.options);
        applySnapshot(result);
        showToast(`已整理 ${uniqueIds.length} 条记录`);
      }
    } catch { showToast('批量操作失败，未保存全部变更'); }
  };

  const batchRestore = async (ids) => {
    try {
      const result = await databaseAPI().batchRestore?.(ids);
      applySnapshot(result);
      showToast(`已恢复 ${ids.length} 条记录`);
    } catch { showToast('批量恢复失败'); }
  };

  const loadMoreEntries = async () => {
    const searchActive = search.trim().length > 0 || hasSearchFilters(searchFilters);
    if (loadingMore || searchLoading || (searchActive ? !searchHasMore : entries.length >= entryCount)) return;
    setLoadingMore(true);
    try {
      if (searchActive) {
        const next = await databaseAPI().search?.(search.trim(), { ...searchFilters, includeTrash: view === 'recycle', limit: SEARCH_PAGE_SIZE, offset: searchResults?.length || 0 });
        const page = Array.isArray(next) ? next : [];
        setSearchResults((current) => [...(current || []), ...page.filter((item) => !(current || []).some((existing) => existing.id === item.id))]);
        setSearchHasMore(page.length === SEARCH_PAGE_SIZE);
      } else {
        const next = await databaseAPI().listEntries?.({ includeTrash: true, limit: 500, offset: entries.length });
        if (Array.isArray(next) && next.length) setEntries((current) => [...current, ...next.filter((item) => !current.some((existing) => existing.id === item.id))]);
        else setEntryCount(entries.length);
      }
    } finally { setLoadingMore(false); }
  };

  const focusInlineComposer = () => {
    if (view === 'timeline') { document.querySelector('#inline-content-input')?.focus(); return; }
    openComposer();
  };

  const openMediaViewer = (items, activeIndex = 0) => {
    const normalized = items.map((item) => typeof item === 'string' ? { path: item } : item).filter((item) => item.path);
    if (!normalized.length) return;
    setMediaViewer({ items: normalized, activeIndex: Math.min(Math.max(activeIndex, 0), normalized.length - 1) });
  };
  const openEntryFromMedia = (id) => { setMediaViewer(null); editEntry(id); };
  const relocateAttachment = async (oldPath) => {
    const action = globalThis.diaryAPI?.assets?.relocate;
    if (!action) { showToast('附件重新定位仅在桌面端运行时可用'); return false; }
    const result = await action(oldPath);
    if (result?.cancelled) return false;
    if (result?.error) { showToast(result.error); return false; }
    if (result?.snapshot) applySnapshot(result.snapshot);
    if (result?.path) setMediaViewer((current) => current ? { ...current, items: current.items.map((item) => item.path === oldPath ? { ...item, path: result.path } : item) } : null);
    showToast(result?.merged ? '附件已恢复并合并重复文件' : '附件已重新定位');
    return true;
  };

  const saveSettings = async () => { const nextUrl = serverUrl.trim().replace(/\/$/, '') || 'http://127.0.0.1:8787'; setServerUrl(nextUrl); await databaseAPI().saveSetting('serverUrl', nextUrl); showToast('设置已保存'); window.setTimeout(syncNow, 0); };
  const exportBackup = async () => { const action = globalThis.diaryAPI?.backup?.export; if (!action) { showToast('备份功能仅在桌面端运行时可用'); return; } const result = await action(); if (result?.cancelled) return; if (result?.error) { showToast(result.error); return; } showToast(`备份已导出 · ${result.entries} 条记录`); };
  const importBackup = async () => { const action = globalThis.diaryAPI?.backup?.import; if (!action) { showToast('备份功能仅在桌面端运行时可用'); return; } const result = await action(); if (result?.cancelled) return; if (result?.error) { const phaseLabel = { validate: '校验阶段', file: '附件阶段', database: '写入阶段' }[result.phase]; const removed = Number(result.cleanup?.removedFiles || 0); const cleanupNote = removed ? `，已清理 ${removed} 个导入附件` : ''; showToast(`${phaseLabel ? `${phaseLabel}失败：` : ''}${result.error}${cleanupNote}`); return; } applySnapshot(result?.snapshot); showToast(`已合并 ${result?.importedEntries || 0} 条记录`); };
  const handleSearchChange = (value) => { setSearch(value); setSearchError(''); if (value.trim() && view !== 'recycle') setView('all'); };
  const focusGlobalSearch = () => { if (view === 'timeline' || view === 'media') setView('all'); window.requestAnimationFrame(() => document.querySelector('#global-search-input')?.focus()); };
  useEffect(() => { if (!bootstrapped) return undefined; const timer = window.setTimeout(syncNow, 700); return () => window.clearTimeout(timer); }, [bootstrapped]);
  useEffect(() => { const onKeyDown = (event) => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'n') { event.preventDefault(); focusInlineComposer(); } if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); focusGlobalSearch(); } if ((event.ctrlKey || event.metaKey) && event.key === ',') { event.preventDefault(); setView('settings'); } if ((event.ctrlKey || event.metaKey) && event.key === 'Enter' && (composerOpen || view === 'timeline')) { event.preventDefault(); saveEntry({ inline: !composerOpen && view === 'timeline' }); } if (event.key === 'Escape' && composerOpen) setComposerOpen(false); }; document.addEventListener('keydown', onKeyDown); return () => document.removeEventListener('keydown', onKeyDown); });

  const activeEntries = entries.filter((entry) => !entry.isInTrash);
  const tagOptions = taxonomy ? taxonomy.tags || [] : usageOptions(entries, 'tags');
  const categoryOptions = taxonomy ? [...new Set([...(taxonomy.categories || []), ...defaultCategories])] : usageOptions(entries, 'category', defaultCategories);
  const matchesSearch = (entry) => !search || `${entry.title || ''} ${entry.contentText || entry.content || ''} ${entry.category || ''} ${(entry.tags || []).join(' ')}`.toLowerCase().includes(search.toLowerCase());
  const filteredEntries = activeEntries.filter(matchesSearch);
  const trashedEntries = entries.filter((entry) => entry.isInTrash).filter(matchesSearch);
  const searchActive = search.trim().length > 0 || hasSearchFilters(searchFilters);
  const visibleAllEntries = searchActive ? (searchResults || []) : activeEntries;
  const visibleTrashEntries = searchActive ? (searchResults || []) : trashedEntries;
  const selectTag = (tag) => { setSearch(''); setSearchFilters({ ...emptySearchFilters, tags: [tag] }); setView('all'); };
  const selectCategory = (category) => { setSearch(''); setSearchFilters({ ...emptySearchFilters, category }); setView('all'); };
  const clearSearchFilters = () => setSearchFilters({ ...emptySearchFilters });
  const resolveConflictValue = async (conflict, resolution) => {
    const result = await databaseAPI().resolveConflict?.({ conflictId: conflict.conflictId, resolution });
    if (result) applySnapshot(result);
    const remaining = await databaseAPI().listConflicts?.();
    setConflicts(Array.isArray(remaining) ? remaining : []);
    showToast('冲突已处理');
  };
  if (view === 'conflicts') {
    return <div className="window-shell"><Titlebar theme={theme} onToggleTheme={() => setTheme(theme === 'dark' ? 'light' : 'dark')} /><div className="app-layout"><SidebarRail view={view} onView={setView} syncKind={syncState.kind} syncLabel={syncState.label} /><main className="main-area"><section className="view-panel"><ConflictView conflicts={conflicts} onResolve={resolveConflictValue} /></section></main></div></div>;
  }
  return <div className="window-shell"><Titlebar theme={theme} onToggleTheme={() => setTheme(theme === 'dark' ? 'light' : 'dark')} /><div className="app-layout"><SidebarRail view={view} onView={setView} syncKind={syncState.kind} syncLabel={syncState.label} /><main className="main-area">{view !== 'timeline' && view !== 'media' && <WorkspaceHeader view={view} entryCount={activeEntries.length} search={search} onSearch={handleSearchChange} onSync={syncNow} onNew={focusInlineComposer} />}{view === 'timeline' && <section className="view-panel desk-view"><TodayView entries={filteredEntries} onEdit={editEntry} onPreview={openMediaViewer} onToggleFavorite={toggleFavorite} onCopy={copyEntry} onTrash={trashEntry} composer={{ draft, setDraft, attachments, setAttachments, editing: false, categoryOptions, tagOptions, onSave: () => saveEntry({ inline: true }), onNotify: showToast }} /></section>}{view === 'all' && <section className="view-panel"><EntriesView entries={visibleAllEntries} hasMore={searchActive ? searchHasMore : entryCount > entries.length} loading={searchLoading || loadingMore} searchError={searchError} search={search} filters={searchFilters} categories={categoryOptions} tags={tagOptions} onFiltersChange={setSearchFilters} onClearFilters={clearSearchFilters} onBatchAction={batchAction} onLoadMore={loadMoreEntries} onEdit={editEntry} onPreview={openMediaViewer} onToggleFavorite={toggleFavorite} onCopy={copyEntry} onTrash={trashEntry} /></section>}{view === 'recycle' && <section className="view-panel"><RecycleBinView entries={visibleTrashEntries} search={search} filters={searchFilters} categories={categoryOptions} tags={tagOptions} searchError={searchError} loading={searchLoading} hasMore={searchActive ? searchHasMore : false} onLoadMore={loadMoreEntries} onFiltersChange={setSearchFilters} onClearFilters={clearSearchFilters} onEdit={editEntry} onPreview={openMediaViewer} onRestore={restoreEntry} onDeletePermanent={permanentlyDelete} /></section>}{view === 'tags' && <section className="view-panel"><TagsView entries={entries} taxonomy={taxonomy} categories={categoryOptions} onSelect={selectTag} onSelectCategory={selectCategory} onRenameTag={renameTagValue} onDeleteTag={deleteTagValue} onRenameCategory={renameCategoryValue} onDeleteCategory={deleteCategoryValue} /></section>}{view === 'calendar' && <section className="view-panel"><CalendarView entries={activeEntries} selectedDate={selectedDate} setSelectedDate={setSelectedDate} onNew={openComposer} onEdit={editEntry} onPreview={openMediaViewer} /></section>}{view === 'media' && <section className="view-panel media-view-panel"><LibraryView entries={activeEntries} search={search} onPreview={openMediaViewer} /></section>}{view === 'insights' && <section className="view-panel"><InsightsView entries={activeEntries} /></section>}{view === 'settings' && <section className="view-panel"><SettingsView serverUrl={serverUrl} setServerUrl={setServerUrl} onSave={saveSettings} attachmentHealth={attachmentHealth} onExportBackup={exportBackup} onImportBackup={importBackup} /></section>}{PLACEHOLDERS[view] && <section className="view-panel"><PlaceholderView title={PLACEHOLDERS[view][0]} description={PLACEHOLDERS[view][1]} onBack={() => setView('timeline')} /></section>}</main></div>{composerOpen && <QuickCapture draft={draft} setDraft={setDraft} attachments={attachments} setAttachments={setAttachments} editing={Boolean(editingId)} categoryOptions={categoryOptions} tagOptions={tagOptions} onSave={saveEntry} onClose={() => setComposerOpen(false)} onNotify={showToast} />}{mediaViewer && <MediaViewer items={mediaViewer.items} activeIndex={mediaViewer.activeIndex} onActiveIndexChange={(activeIndex) => setMediaViewer((current) => current ? { ...current, activeIndex } : null)} onClose={() => setMediaViewer(null)} onOpenEntry={openEntryFromMedia} onRelocate={relocateAttachment} />}<div className={`toast ${toast.message ? 'show' : ''}`} id="toast" role="status"><span>{toast.message}</span>{toast.action && <button type="button" onClick={async () => { const action = toast.action; setToast({ message: '', action: null }); await action.run?.(); }}>{toast.action.label || '撤销'}</button>}</div></div>;
}

function QuickCaptureWindow() {
  const [draft, setDraft] = useState(() => defaultDraft());
  const [attachments, setAttachments] = useState([]);
  const [usageEntries, setUsageEntries] = useState([]);
  const [taxonomy, setTaxonomy] = useState(null);
  const [notice, setNotice] = useState('');
  const [shortcutLabel, setShortcutLabel] = useState('Ctrl + Shift + Space');
  const noticeTimer = useRef(null);

  const notify = (message) => {
    setNotice(message);
    window.clearTimeout(noticeTimer.current);
    noticeTimer.current = window.setTimeout(() => setNotice(''), 2200);
  };

  useEffect(() => {
    document.body.classList.toggle('dark', localStorage.getItem(STORAGE.theme) === 'dark');
    let active = true;
    const load = async () => {
      try {
        const existingEntries = await databaseAPI().listEntries?.({ includeTrash: false, limit: 2000, offset: 0 });
        if (active && Array.isArray(existingEntries)) setUsageEntries(existingEntries);
        const usage = await databaseAPI().taxonomyUsage?.();
        if (active && usage) setTaxonomy(usage);
        const saved = await databaseAPI().loadDraft?.('quick-capture');
        if (!active || !saved?.payload) return;
        setDraft({ ...defaultDraft(), ...saved.payload });
        setAttachments(Array.isArray(saved.payload.attachments) ? saved.payload.attachments : []);
      } catch {
        // A missing quick-capture draft should not block the capture window.
      }
    };
    void load();
    const shortcutStatus = globalThis.diaryAPI?.quickCapture?.status?.();
    if (shortcutStatus) shortcutStatus.then((status) => { if (status?.label) setShortcutLabel(status.label); }).catch(() => {});
    const unsubscribe = globalThis.diaryAPI?.quickCapture?.onOpen?.(() => {
      window.requestAnimationFrame(() => document.querySelector('#content-input')?.focus());
    });
    return () => { active = false; unsubscribe?.(); window.clearTimeout(noticeTimer.current); };
  }, []);

  useEffect(() => {
    const hasContent = Boolean(draft.content.trim() || draft.title.trim() || attachments.length);
    if (!hasContent) return undefined;
    const timer = window.setTimeout(() => {
      void databaseAPI().saveDraft({ id: 'quick-capture', payload: { ...draft, attachments } });
    }, 350);
    return () => window.clearTimeout(timer);
  }, [draft, attachments]);

  useEffect(() => {
    const onKeyDown = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        globalThis.diaryAPI?.quickCapture?.hide?.();
      }
      if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
        event.preventDefault();
        void saveCapture();
      }
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  });

  const saveCapture = async () => {
    const contentText = draft.content.trim();
    if (!contentText && attachments.length === 0) {
      notify('写几句话，或添加一个附件');
      document.querySelector('#content-input')?.focus();
      return;
    }
    const now = new Date().toISOString();
    const imagePaths = attachments.filter((path) => mediaKind(path) === 'image');
    const videoPaths = attachments.filter((path) => mediaKind(path) === 'video');
    const audioPaths = attachments.filter((path) => mediaKind(path) === 'audio');
    const entry = { schemaVersion: 1, id: createId('entry'), createdAt: buildDateTime(draft.date), occurredAt: buildDateTime(draft.date), updatedAt: now, title: draft.title.trim(), content: contentText, contentText, editorType: 'plain_text', mood: draft.moodSet ? Number(draft.mood) : null, moodSet: draft.moodSet === true, category: draft.category, tags: draft.tags || [], imagePaths, audioPaths, videoPaths, weather: [], positions: [], latitude: null, longitude: null, colorValue: 0xffe4e0ed, isFavorite: false, isInTrash: false };
    try {
      const result = await databaseAPI().saveEntry(entry);
      if (!result?.snapshot) throw new Error('本地保存失败');
      await databaseAPI().clearDraft('quick-capture');
      setDraft(defaultDraft());
      setAttachments([]);
      notify('已保存到日记');
      window.setTimeout(() => globalThis.diaryAPI?.quickCapture?.hide?.(), 80);
    } catch {
      notify('保存失败，草稿仍保留');
    }
  };

  const close = () => globalThis.diaryAPI?.quickCapture?.hide?.();
  const tagOptions = taxonomy ? taxonomy.tags || [] : usageOptions(usageEntries, 'tags');
  const categoryOptions = taxonomy ? [...new Set([...(taxonomy.categories || []), ...defaultCategories])] : usageOptions(usageEntries, 'category', defaultCategories);
  return <div className="quick-capture-shell">
    <header className="quick-capture-bar" style={{ WebkitAppRegion: 'drag' }}>
      <div><span className="quick-capture-mark">✦</span><strong>此刻速记</strong><span className="quick-capture-subtitle">随手记下，不打断工作</span></div>
      <div className="quick-capture-bar-actions"><span className="quick-capture-shortcut-label">{shortcutLabel}</span><button type="button" aria-label="关闭速记窗口" onClick={close} style={{ WebkitAppRegion: 'no-drag' }}>×</button></div>
    </header>
    <main className="quick-capture-body"><QuickCapture draft={draft} setDraft={setDraft} attachments={attachments} setAttachments={setAttachments} editing={false} windowed categoryOptions={categoryOptions} tagOptions={tagOptions} onSave={saveCapture} onClose={close} onNotify={notify} /></main>
    {notice && <div className="quick-capture-notice" role="status">{notice}</div>}
  </div>;
}

const isQuickCapture = new URLSearchParams(window.location.search).get('mode') === 'quick-capture';
createRoot(document.getElementById('root')).render(isQuickCapture ? <QuickCaptureWindow /> : <App />);
