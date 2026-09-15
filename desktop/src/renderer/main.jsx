import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { CalendarView } from './components/CalendarView';
import { InsightsView } from './components/InsightsView';
import { LibraryView } from './components/LibraryView';
import { MediaViewer } from './components/MediaViewer';
import { PlaceholderView } from './components/PlaceholderView';
import { QuickCapture } from './components/QuickCapture';
import { SettingsView } from './components/SettingsView';
import { SidebarRail } from './components/SidebarRail';
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

const PLACEHOLDERS = {
  tags: ['标签', '把零散记录聚拢成可回看的主题，标签管理即将接入。'],
  recycle: ['回收站', '被移入回收站的记录会在这里保留，避免误删。'],
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

function App() {
  const [entries, setEntries] = useState(() => loadJson(STORAGE.entries, []));
  const [outbox, setOutbox] = useState(() => loadJson(STORAGE.outbox, []));
  const [cursor, setCursor] = useState(() => localStorage.getItem(STORAGE.cursor) || '0');
  const [deviceId] = useState(() => localStorage.getItem(STORAGE.deviceId) || createId('desktop'));
  const [theme, setTheme] = useState(() => localStorage.getItem(STORAGE.theme) || 'light');
  const [serverUrl, setServerUrl] = useState(() => localStorage.getItem(STORAGE.serverUrl) || 'http://127.0.0.1:8787');
  const [view, setView] = useState('timeline');
  const [search, setSearch] = useState('');
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [composerOpen, setComposerOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [attachments, setAttachments] = useState([]);
  const [draft, setDraft] = useState({ date: dateKey(new Date()), title: '', content: '', category: '生活', mood: '0.7' });
  const [syncState, setSyncState] = useState({ kind: '', label: '仅本地保存' });
  const [mediaViewer, setMediaViewer] = useState(null);
  const stateRef = useRef({ entries, outbox, cursor, serverUrl, deviceId, syncing: false });
  const toastTimer = useRef(null);

  useEffect(() => { stateRef.current = { entries, outbox, cursor, serverUrl, deviceId, syncing: stateRef.current.syncing }; }, [entries, outbox, cursor, serverUrl, deviceId]);
  useEffect(() => { localStorage.setItem(STORAGE.deviceId, deviceId); }, [deviceId]);
  useEffect(() => { document.body.classList.toggle('dark', theme === 'dark'); localStorage.setItem(STORAGE.theme, theme); }, [theme]);
  useEffect(() => { if (outbox.length) setSyncState({ kind: 'error', label: `${outbox.length} 条待同步` }); }, [outbox.length]);

  const persist = (nextEntries, nextOutbox, nextCursor) => { localStorage.setItem(STORAGE.entries, JSON.stringify(nextEntries)); localStorage.setItem(STORAGE.outbox, JSON.stringify(nextOutbox)); localStorage.setItem(STORAGE.cursor, nextCursor); };
  const showToast = (message) => { const node = document.querySelector('#toast'); if (!node) return; node.textContent = message; node.classList.add('show'); window.clearTimeout(toastTimer.current); toastTimer.current = window.setTimeout(() => node.classList.remove('show'), 2400); };
  const openComposer = (date = new Date()) => { setEditingId(null); setAttachments([]); setDraft({ date: dateKey(date), title: '', content: '', category: '生活', mood: '0.7' }); setComposerOpen(true); };
  const editEntry = (id) => { const entry = stateRef.current.entries.find((item) => item.id === id); if (!entry) return; setEditingId(id); setAttachments([...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])]); setDraft({ date: dateKey(entry.createdAt), title: entry.title === '未命名的一刻' ? '' : entry.title, content: entry.contentText || entry.content || '', category: entry.category || '生活', mood: String(entry.mood ?? 0.7) }); setComposerOpen(true); };

  const syncNow = async () => {
    const current = stateRef.current;
    if (current.syncing) return;
    stateRef.current.syncing = true;
    setSyncState({ kind: 'syncing', label: '正在同步…' });
    try {
      const result = await window.diaryAPI.sync({ baseUrl: current.serverUrl, body: { protocolVersion: 1, deviceId: current.deviceId, cursor: current.cursor, limit: 100, client: { platform: 'desktop', appVersion: window.diaryAPI.appVersion }, changes: current.outbox } });
      if (!result.ok) throw new Error(result.body?.error?.message || '同步服务不可用');
      const data = result.body.data;
      let nextEntries = [...stateRef.current.entries];
      const merge = (remote) => { const local = nextEntries.find((entry) => entry.id === remote.id); if (!local || new Date(remote.updatedAt) >= new Date(local.updatedAt)) nextEntries = [remote, ...nextEntries.filter((entry) => entry.id !== remote.id)]; };
      (data.changes || []).forEach((change) => merge(change.entry));
      (data.conflicts || []).forEach((conflict) => merge(conflict.serverEntry));
      const done = new Set([...(data.appliedMutationIds || []), ...(data.conflicts || []).map((conflict) => conflict.mutationId)]);
      const nextOutbox = stateRef.current.outbox.filter((mutation) => !done.has(mutation.mutationId));
      const nextCursor = data.nextCursor || stateRef.current.cursor;
      setEntries(nextEntries); setOutbox(nextOutbox); setCursor(nextCursor); persist(nextEntries, nextOutbox, nextCursor);
      setSyncState({ kind: '', label: nextOutbox.length ? `${nextOutbox.length} 条待同步` : '已同步' });
      if (data.conflicts?.length) showToast('发现版本差异，已保留服务端最新版本');
    } catch { setSyncState({ kind: 'error', label: stateRef.current.outbox.length ? '本地已保存 · 待同步' : '仅本地保存' }); }
    finally { stateRef.current.syncing = false; }
  };

  const saveEntry = ({ inline = false } = {}) => {
    const contentText = draft.content.trim();
    if (!contentText && attachments.length === 0) { showToast('写几句话，或添加一个附件'); document.querySelector('#inline-content-input, #content-input')?.focus(); return; }
    const current = stateRef.current;
    const existing = current.entries.find((entry) => entry.id === editingId);
    const now = new Date().toISOString();
    const imagePaths = attachments.filter((path) => mediaKind(path) === 'image');
    const videoPaths = attachments.filter((path) => mediaKind(path) === 'video');
    const audioPaths = attachments.filter((path) => mediaKind(path) === 'audio');
    const entry = { schemaVersion: 1, id: editingId || createId('entry'), createdAt: existing?.createdAt || buildDateTime(draft.date), updatedAt: now, title: draft.title.trim(), content: contentText, contentText, editorType: 'plain_text', mood: Number(draft.mood), category: draft.category, tags: existing?.tags || [], imagePaths, audioPaths, videoPaths, weather: existing?.weather || [], positions: existing?.positions || [], latitude: existing?.latitude ?? null, longitude: existing?.longitude ?? null, colorValue: existing?.colorValue || 0xffe4e0ed, isFavorite: existing?.isFavorite || false, isInTrash: false };
    const nextEntries = [entry, ...current.entries.filter((item) => item.id !== entry.id)];
    const mutation = { mutationId: `${current.deviceId}:${entry.id}:${entry.updatedAt}`, entry };
    const nextOutbox = [...current.outbox.filter((item) => item.entry.id !== entry.id), mutation];
    setEntries(nextEntries); setOutbox(nextOutbox); persist(nextEntries, nextOutbox, current.cursor); setComposerOpen(false); setEditingId(null); if (inline) { setAttachments([]); setDraft({ date: dateKey(new Date()), title: '', content: '', category: '生活', mood: '0.7' }); } showToast(existing ? '已更新这篇日记' : '已记下这一刻'); window.setTimeout(syncNow, 0);
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

  const saveSettings = () => { const nextUrl = serverUrl.trim().replace(/\/$/, '') || 'http://127.0.0.1:8787'; setServerUrl(nextUrl); localStorage.setItem(STORAGE.serverUrl, nextUrl); showToast('设置已保存'); window.setTimeout(syncNow, 0); };
  useEffect(() => { const timer = window.setTimeout(syncNow, 700); return () => window.clearTimeout(timer); }, []);
  useEffect(() => { const onKeyDown = (event) => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'n') { event.preventDefault(); focusInlineComposer(); } if ((event.ctrlKey || event.metaKey) && event.key === 'Enter' && (composerOpen || view === 'timeline')) { event.preventDefault(); saveEntry({ inline: !composerOpen && view === 'timeline' }); } if (event.key === 'Escape' && composerOpen) setComposerOpen(false); }; document.addEventListener('keydown', onKeyDown); return () => document.removeEventListener('keydown', onKeyDown); });

  const activeEntries = entries.filter((entry) => !entry.isInTrash);
  const filteredEntries = activeEntries.filter((entry) => !search || `${entry.title} ${entry.contentText} ${entry.category}`.toLowerCase().includes(search.toLowerCase()));
  return <div className="window-shell"><Titlebar theme={theme} onToggleTheme={() => setTheme(theme === 'dark' ? 'light' : 'dark')} /><div className="app-layout"><SidebarRail view={view} onView={setView} syncKind={syncState.kind} syncLabel={syncState.label} /><main className="main-area">{view !== 'timeline' && view !== 'media' && <WorkspaceHeader view={view} entryCount={activeEntries.length} search={search} onSearch={setSearch} onSync={syncNow} onNew={focusInlineComposer} />}{view === 'timeline' && <section className="view-panel desk-view"><TodayView entries={filteredEntries} onEdit={editEntry} onPreview={openMediaViewer} composer={{ draft, setDraft, attachments, setAttachments, editing: false, onSave: () => saveEntry({ inline: true }), onNotify: showToast }} /></section>}{view === 'calendar' && <section className="view-panel"><CalendarView entries={activeEntries} selectedDate={selectedDate} setSelectedDate={setSelectedDate} onNew={openComposer} onEdit={editEntry} onPreview={openMediaViewer} /></section>}{view === 'media' && <section className="view-panel media-view-panel"><LibraryView entries={activeEntries} search={search} onPreview={openMediaViewer} /></section>}{view === 'insights' && <section className="view-panel"><InsightsView entries={activeEntries} /></section>}{view === 'settings' && <section className="view-panel"><SettingsView serverUrl={serverUrl} setServerUrl={setServerUrl} onSave={saveSettings} /></section>}{PLACEHOLDERS[view] && <section className="view-panel"><PlaceholderView title={PLACEHOLDERS[view][0]} description={PLACEHOLDERS[view][1]} onBack={() => setView('timeline')} /></section>}</main></div>{composerOpen && <QuickCapture draft={draft} setDraft={setDraft} attachments={attachments} setAttachments={setAttachments} editing={Boolean(editingId)} onSave={saveEntry} onClose={() => setComposerOpen(false)} onNotify={showToast} />}{mediaViewer && <MediaViewer items={mediaViewer.items} activeIndex={mediaViewer.activeIndex} onActiveIndexChange={(activeIndex) => setMediaViewer((current) => current ? { ...current, activeIndex } : null)} onClose={() => setMediaViewer(null)} />}<div className="toast" id="toast" role="status"></div></div>;
}

createRoot(document.getElementById('root')).render(<App />);
