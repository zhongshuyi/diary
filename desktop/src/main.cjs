const { app, BrowserWindow, dialog, globalShortcut, ipcMain, Menu, nativeImage, screen, shell, Tray } = require('electron');
const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { createDiaryStore } = require('./main/database/store.cjs');
const { DEFAULT_QUICK_CAPTURE_ACCELERATOR, formatAccelerator, normalizeAccelerator } = require('./main/shortcut.cjs');
const { restoreQuickCaptureBounds } = require('./main/window-bounds.cjs');
const { checkForUpdate, isSafeExternalUrl } = require('./main/update-check.cjs');
const { createSyncRequest, createUpdateCheck } = require('./main/connection-settings.cjs');
const { getDesktopIconPath } = require('./main/app-icon.cjs');

let mainWindow;
let quickCaptureWindow;
let tray;
let diaryStore;
let isQuitting = false;
let lastFocusedWindow;
let quickCaptureAccelerator = DEFAULT_QUICK_CAPTURE_ACCELERATOR;
let quickCaptureRegistered = false;
let quickBoundsTimer;
const APP_ICON_PATH = getDesktopIconPath(__dirname);

function rememberFocusedWindow() {
  const focusedWindow = BrowserWindow.getFocusedWindow();
  if (focusedWindow && focusedWindow !== quickCaptureWindow) lastFocusedWindow = focusedWindow;
}

function restorePreviousFocus() {
  if (!lastFocusedWindow || lastFocusedWindow.isDestroyed()) return;
  lastFocusedWindow.show();
  lastFocusedWindow.focus();
}

function hideQuickCaptureWindow() {
  if (!quickCaptureWindow || quickCaptureWindow.isDestroyed()) return;
  quickCaptureWindow.hide();
  restorePreviousFocus();
}

function showMainWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) {
    createWindow();
  }
  mainWindow?.show();
  mainWindow?.focus();
}

function persistQuickCaptureBounds() {
  if (!quickCaptureWindow || quickCaptureWindow.isDestroyed() || !diaryStore) return;
  diaryStore.saveSetting('quickCaptureBounds', quickCaptureWindow.getBounds());
}

function scheduleQuickCaptureBoundsSave() {
  clearTimeout(quickBoundsTimer);
  quickBoundsTimer = setTimeout(() => persistQuickCaptureBounds(), 250);
}

function toggleQuickCapture() {
  if (quickCaptureWindow && !quickCaptureWindow.isDestroyed() && quickCaptureWindow.isVisible()) {
    hideQuickCaptureWindow();
    return;
  }
  rememberFocusedWindow();
  if (!quickCaptureWindow || quickCaptureWindow.isDestroyed()) createQuickCaptureWindow();
  quickCaptureWindow.show();
  quickCaptureWindow.focus();
  const notify = () => {
    if (quickCaptureWindow && !quickCaptureWindow.isDestroyed()) quickCaptureWindow.webContents.send('quick-capture:open');
  };
  if (quickCaptureWindow.webContents.isLoading()) quickCaptureWindow.webContents.once('did-finish-load', notify);
  else notify();
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1100,
    minHeight: 720,
    show: false,
    frame: false,
    titleBarStyle: 'hidden',
    backgroundColor: '#f4f1eb',
    icon: APP_ICON_PATH,
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      spellcheck: true,
    },
  });

  mainWindow.loadFile(path.join(__dirname, '..', 'dist', 'index.html'));
  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.on('close', (event) => {
    if (isQuitting) return;
    event.preventDefault();
    mainWindow.hide();
  });
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function createQuickCaptureWindow() {
  quickCaptureWindow = new BrowserWindow({
    width: 560,
    height: 520,
    minWidth: 420,
    minHeight: 360,
    show: false,
    frame: false,
    resizable: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    backgroundColor: '#f4f1eb',
    icon: APP_ICON_PATH,
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      spellcheck: true,
    },
  });

  const savedBounds = diaryStore?.snapshot()?.settings?.quickCaptureBounds;
  const bounds = restoreQuickCaptureBounds(savedBounds, screen.getAllDisplays());
  quickCaptureWindow.setBounds(bounds);
  quickCaptureWindow.loadFile(path.join(__dirname, '..', 'dist', 'index.html'), { query: { mode: 'quick-capture' } });
  quickCaptureWindow.once('ready-to-show', () => {
    if (quickCaptureWindow?.isVisible()) quickCaptureWindow.focus();
  });
  quickCaptureWindow.on('close', (event) => {
    if (isQuitting) return;
    event.preventDefault();
    hideQuickCaptureWindow();
  });
  quickCaptureWindow.on('move', scheduleQuickCaptureBoundsSave);
  quickCaptureWindow.on('resize', scheduleQuickCaptureBoundsSave);
  quickCaptureWindow.on('closed', () => {
    quickCaptureWindow = null;
  });
}

function createTray() {
  tray = new Tray(nativeImage.createFromPath(APP_ICON_PATH));
  tray.setToolTip('此刻 · 个人日记');
  updateTrayMenu();
  tray.on('double-click', showMainWindow);
}

function updateTrayMenu() {
  if (!tray) return;
  tray.setContextMenu(Menu.buildFromTemplate([
    { label: '新建速记', accelerator: quickCaptureAccelerator, click: toggleQuickCapture },
    { type: 'separator' },
    { label: '打开主窗口', click: showMainWindow },
    { type: 'separator' },
    { label: '退出此刻', click: () => { isQuitting = true; app.quit(); } },
  ]));
}

function registerQuickCaptureShortcut() {
  try {
    const configured = diaryStore?.snapshot()?.settings?.quickCaptureShortcut || process.env.DIARY_QUICK_CAPTURE_SHORTCUT || DEFAULT_QUICK_CAPTURE_ACCELERATOR;
    quickCaptureAccelerator = normalizeAccelerator(configured);
  } catch {
    quickCaptureAccelerator = DEFAULT_QUICK_CAPTURE_ACCELERATOR;
  }
  quickCaptureRegistered = globalShortcut.register(quickCaptureAccelerator, toggleQuickCapture);
  if (!quickCaptureRegistered) console.warn(`Unable to register quick-capture shortcut: ${quickCaptureAccelerator}`);
  return quickCaptureRegistered;
}

function setQuickCaptureShortcut(value) {
  let next;
  try {
    next = normalizeAccelerator(value);
  } catch (error) {
    return { accelerator: quickCaptureAccelerator, label: formatAccelerator(quickCaptureAccelerator), registered: quickCaptureRegistered, error: error.message || '快捷键格式不支持' };
  }
  if (next === quickCaptureAccelerator && quickCaptureRegistered) return { accelerator: next, label: formatAccelerator(next), registered: true };
  globalShortcut.unregister(quickCaptureAccelerator);
  const registered = globalShortcut.register(next, toggleQuickCapture);
  if (!registered) {
    quickCaptureRegistered = globalShortcut.register(quickCaptureAccelerator, toggleQuickCapture);
    return { accelerator: quickCaptureAccelerator, label: formatAccelerator(quickCaptureAccelerator), registered: quickCaptureRegistered, error: '快捷键已被其他应用占用' };
  }
  quickCaptureAccelerator = next;
  quickCaptureRegistered = true;
  diaryStore?.saveSetting('quickCaptureShortcut', next);
  updateTrayMenu();
  return { accelerator: next, label: formatAccelerator(next), registered: true };
}

function mediaDirectory() {
  return path.join(app.getPath('userData'), 'media');
}

function isWithinDirectory(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative === '' || (relative && !relative.startsWith('..') && !path.isAbsolute(relative));
}

function safeMediaName(name, fallback = 'pasted-media') {
  const cleaned = path.basename(String(name || fallback)).replace(/[<>:"/\\|?*\x00-\x1F]/g, '-').trim();
  return cleaned || fallback;
}

function extensionForMime(mime) {
  return {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'image/bmp': '.bmp',
    'video/mp4': '.mp4',
    'video/webm': '.webm',
    'video/quicktime': '.mov',
    'video/x-matroska': '.mkv',
    'audio/mpeg': '.mp3',
    'audio/wav': '.wav',
    'audio/x-wav': '.wav',
    'audio/mp4': '.m4a',
    'audio/ogg': '.ogg',
  }[String(mime || '').toLowerCase()] || '';
}

async function saveMediaBuffer({ buffer, name, mime }) {
  if (!buffer) return null;
  const bytes = Buffer.from(buffer);
  if (!bytes.length || bytes.byteLength > 128 * 1024 * 1024) return null;
  const originalName = safeMediaName(name);
  const extension = path.extname(originalName) || extensionForMime(mime) || '.bin';
  const stem = path.basename(originalName, path.extname(originalName)) || 'pasted-media';
  const filePath = path.join(mediaDirectory(), `${Date.now()}-${crypto.randomUUID()}-${stem}${extension}`);
  await fs.mkdir(mediaDirectory(), { recursive: true });
  await fs.writeFile(filePath, bytes);
  return filePath;
}

async function copyMediaFiles(filePaths) {
  const imported = [];
  for (const sourcePath of Array.isArray(filePaths) ? filePaths.slice(0, 20) : []) {
    if (typeof sourcePath !== 'string' || !sourcePath.trim()) continue;
    try {
      const stats = await fs.stat(sourcePath);
      if (!stats.isFile() || stats.size > 128 * 1024 * 1024) continue;
      const originalName = safeMediaName(sourcePath);
      const extension = path.extname(originalName);
      const stem = path.basename(originalName, extension) || 'pasted-media';
      const destination = path.join(mediaDirectory(), `${Date.now()}-${crypto.randomUUID()}-${stem}${extension}`);
      await fs.mkdir(mediaDirectory(), { recursive: true });
      await fs.copyFile(sourcePath, destination);
      imported.push(destination);
    } catch {
      // A clipboard file can disappear before it is copied; keep the paste flow usable.
    }
  }
  return imported;
}

ipcMain.handle('window:minimize', () => {
  mainWindow?.minimize();
});

ipcMain.handle('window:maximize', () => {
  if (!mainWindow) return false;
  if (mainWindow.isMaximized()) {
    mainWindow.unmaximize();
  } else {
    mainWindow.maximize();
  }
  return mainWindow.isMaximized();
});

ipcMain.handle('window:isMaximized', () => mainWindow?.isMaximized() ?? false);

ipcMain.handle('window:close', () => {
  mainWindow?.close();
});

ipcMain.handle('window:quit', () => {
  isQuitting = true;
  app.quit();
});

ipcMain.handle('quick-capture:hide', () => {
  hideQuickCaptureWindow();
});

ipcMain.handle('quick-capture:show', () => {
  toggleQuickCapture();
});

ipcMain.handle('quick-capture:status', () => ({ accelerator: quickCaptureAccelerator, label: formatAccelerator(quickCaptureAccelerator), registered: quickCaptureRegistered }));
ipcMain.handle('quick-capture:set-shortcut', (_event, value) => setQuickCaptureShortcut(value));

ipcMain.handle('assets:pickMedia', async () => {
  if (!mainWindow) return [];
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '添加媒体',
    properties: ['openFile', 'multiSelections'],
    filters: [{ name: '媒体文件', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'mp4', 'webm', 'mov', 'mkv', 'avi', 'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'] }],
  });
  return result.canceled ? [] : copyMediaFiles(result.filePaths);
});

ipcMain.handle('assets:saveClipboard', async (_event, payload = {}) => {
  try {
    return await saveMediaBuffer(payload);
  } catch {
    return null;
  }
});

ipcMain.handle('assets:importFiles', async (_event, filePaths = []) => {
  return copyMediaFiles(filePaths);
});

ipcMain.handle('assets:relocate', async (_event, currentPath) => {
  if (!mainWindow || !diaryStore) return { cancelled: true };
  const result = await dialog.showOpenDialog(mainWindow, {
    title: '重新定位附件',
    properties: ['openFile'],
    filters: [{ name: '媒体和文件', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'mp4', 'webm', 'mov', 'mkv', 'avi', 'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'opus'] }],
  });
  if (result.canceled || !result.filePaths[0]) return { cancelled: true };
  try {
    return { cancelled: false, ...diaryStore.relocateAttachment(currentPath, result.filePaths[0]) };
  } catch (error) {
    return { cancelled: false, error: error.message || '附件重新定位失败' };
  }
});

ipcMain.handle('assets:read', async (_event, assetPath, options = {}) => {
  if (typeof assetPath !== 'string' || !assetPath.trim() || assetPath.startsWith('data:')) return assetPath || null;
  try {
    const resolvedPath = path.resolve(assetPath);
    if (!isWithinDirectory(path.resolve(mediaDirectory()), resolvedPath)) return null;
    const extension = path.extname(resolvedPath).toLowerCase();
    if (options?.thumbnail === true && ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].includes(extension)) {
      const image = nativeImage.createFromPath(resolvedPath);
      if (image.isEmpty()) return null;
      const size = image.getSize();
      const scale = Math.min(480 / Math.max(1, size.width), 360 / Math.max(1, size.height), 1);
      const thumbnail = image.resize({ width: Math.max(1, Math.round(size.width * scale)), height: Math.max(1, Math.round(size.height * scale)), quality: 'good' });
      return thumbnail.toDataURL();
    }
    const file = await fs.readFile(resolvedPath);
    if (file.byteLength > 128 * 1024 * 1024) return null;
    const mime = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.gif': 'image/gif', '.webp': 'image/webp', '.bmp': 'image/bmp', '.mp4': 'video/mp4', '.webm': 'video/webm', '.mov': 'video/quicktime', '.mkv': 'video/x-matroska', '.avi': 'video/x-msvideo', '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.m4a': 'audio/mp4', '.aac': 'audio/aac', '.ogg': 'audio/ogg', '.flac': 'audio/flac' }[extension] || 'application/octet-stream';
    return `data:${mime};base64,${file.toString('base64')}`;
  } catch {
    return null;
  }
});

ipcMain.handle('sync:request', async (_event, payload = {}) => {
  const request = createSyncRequest({
    baseUrl: payload.baseUrl || process.env.DIARY_SYNC_URL,
    token: payload.token || process.env.SYNC_AUTH_TOKEN,
    body: payload.body,
  });

  try {
    const response = await fetch(request.url, {
      method: 'POST',
      headers: request.headers,
      body: request.body,
    });
    const text = await response.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = { error: { code: 'invalid_response', message: 'Sync server returned invalid JSON' } };
    }
    return { ok: response.ok, status: response.status, body };
  } catch (error) {
    return {
      ok: false,
      status: 0,
      body: { error: { code: 'network_error', message: error.message || 'Unable to reach sync server' } },
    };
  }
});

ipcMain.handle('updates:check', async (_event, { baseUrl } = {}) => {
  try {
    const update = createUpdateCheck({
      updateEndpoint: baseUrl || process.env.DIARY_UPDATE_URL || 'http://127.0.0.1:8787',
    });
    const data = await checkForUpdate({
      baseUrl: update.baseUrl,
      platform: 'desktop',
      currentVersion: app.getVersion(),
    });
    return { ok: true, data };
  } catch (error) {
    return { ok: false, error: { message: error.message || '检查更新失败' } };
  }
});

ipcMain.handle('updates:open', async (_event, value) => {
  try {
    if (!isSafeExternalUrl(value)) return false;
    await shell.openExternal(String(value));
    return true;
  } catch {
    return false;
  }
});

ipcMain.handle('db:bootstrap', (_event, legacyState) => {
  const result = diaryStore?.bootstrap(legacyState) || { migrated: false, reason: 'database_unavailable' };
  if (result.snapshot) setTimeout(() => { try { diaryStore?.createRollingBackup(); } catch (error) { console.warn(`Rolling backup unavailable: ${error.message || error}`); } }, 0);
  return result;
});
ipcMain.handle('db:snapshot', () => diaryStore?.snapshot() || null);
ipcMain.handle('db:listEntries', (_event, options) => diaryStore?.listEntries(options) || []);
ipcMain.handle('db:taxonomyUsage', () => diaryStore?.taxonomyUsage() || { categories: [], tags: [] });
ipcMain.handle('db:attachmentHealth', () => diaryStore?.attachmentHealth() || { total: 0, ready: 0, missing: 0, orphaned: 0 });
ipcMain.handle('db:saveEntry', (_event, entry) => diaryStore?.saveEntry(entry) || null);
ipcMain.handle('db:saveDraft', (_event, draft) => diaryStore?.saveDraft(draft) || null);
ipcMain.handle('db:loadDraft', (_event, id) => diaryStore?.loadDraft(id) || null);
ipcMain.handle('db:clearDraft', (_event, id) => diaryStore?.clearDraft(id) || null);
ipcMain.handle('db:saveSetting', (_event, { key, value } = {}) => diaryStore?.saveSetting(key, value) || null);
ipcMain.handle('db:applySync', (_event, payload) => diaryStore?.applySync(payload) || null);
ipcMain.handle('db:listConflicts', (_event, options) => diaryStore?.listConflicts(options) || []);
ipcMain.handle('db:resolveConflict', (_event, payload) => diaryStore?.resolveConflict(payload) || null);
ipcMain.handle('db:trashEntry', (_event, id) => diaryStore?.trashEntry(id) || null);
ipcMain.handle('db:restoreEntry', (_event, id) => diaryStore?.restoreEntry(id) || null);
ipcMain.handle('db:batchFavorite', (_event, ids, isFavorite) => diaryStore?.batchFavorite(ids, isFavorite) || null);
ipcMain.handle('db:batchTrash', (_event, ids) => diaryStore?.batchTrash(ids) || null);
ipcMain.handle('db:batchRestore', (_event, ids) => diaryStore?.batchRestore(ids) || null);
ipcMain.handle('db:batchOrganize', (_event, ids, options) => diaryStore?.batchOrganize(ids, options) || null);
ipcMain.handle('db:renameTag', (_event, from, to) => diaryStore?.renameTag(from, to) || null);
ipcMain.handle('db:deleteTag', (_event, value) => diaryStore?.deleteTag(value) || null);
ipcMain.handle('db:renameCategory', (_event, from, to) => diaryStore?.renameCategory(from, to) || null);
ipcMain.handle('db:deleteCategory', (_event, value) => diaryStore?.deleteCategory(value) || null);
ipcMain.handle('db:deleteEntry', (_event, id) => diaryStore?.permanentlyDeleteEntry(id) || null);
ipcMain.handle('db:search', (_event, query, options) => diaryStore?.search(query, options) || []);
ipcMain.handle('backup:export', async () => {
  if (!mainWindow || !diaryStore) return { cancelled: true };
  const stamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-');
  const result = await dialog.showSaveDialog(mainWindow, { title: '导出日记备份', defaultPath: path.join(app.getPath('documents'), `diary-backup-${stamp}.diary.zip`), filters: [{ name: 'Diary 备份', extensions: ['zip'] }] });
  if (result.canceled || !result.filePath) return { cancelled: true };
  try { return { cancelled: false, ...diaryStore.exportBackup(result.filePath) }; } catch (error) { return { cancelled: false, error: error.message || '备份导出失败' }; }
});
ipcMain.handle('backup:import', async () => {
  if (!mainWindow || !diaryStore) return { cancelled: true };
  const result = await dialog.showOpenDialog(mainWindow, { title: '导入日记备份', properties: ['openFile'], filters: [{ name: 'Diary 备份', extensions: ['zip'] }] });
  if (result.canceled || !result.filePaths[0]) return { cancelled: true };
  try {
    const preview = diaryStore.previewBackup(result.filePaths[0]);
    const confirmation = await dialog.showMessageBox(mainWindow, { type: 'question', title: '确认导入备份', message: `发现 ${preview.entries} 条记录和 ${preview.attachments} 个附件`, detail: preview.missingAttachments ? `其中 ${preview.missingAttachments} 个附件缺少文件，将保留为缺失状态。导入会与当前资料库合并，不会覆盖较新的本地记录。` : '导入会与当前资料库合并，不会覆盖较新的本地记录。', buttons: ['导入并合并', '取消'], defaultId: 0, cancelId: 1 });
    if (confirmation.response !== 0) return { cancelled: true, preview };
    return { cancelled: false, ...diaryStore.importBackup(result.filePaths[0]), preview };
  } catch (error) {
    return { cancelled: false, error: error.message || '备份导入失败', phase: error.importPhase, cleanup: error.importCleanup };
  }
});

app.whenReady().then(() => {
  diaryStore = createDiaryStore({ userDataPath: app.getPath('userData') });
  try { diaryStore.cleanupOrphanedAttachments(); } catch (error) { console.warn(`Attachment cleanup unavailable: ${error.message || error}`); }
  createWindow();
  createTray();
  registerQuickCaptureShortcut();
  app.on('activate', () => {
    showMainWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin' && !tray) app.quit();
});

app.on('before-quit', () => {
  isQuitting = true;
  clearTimeout(quickBoundsTimer);
  persistQuickCaptureBounds();
  globalShortcut.unregisterAll();
  diaryStore?.close();
  tray?.destroy();
  tray = null;
});
