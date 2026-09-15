const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');

let mainWindow;

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
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function mediaDirectory() {
  return path.join(app.getPath('userData'), 'media');
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

ipcMain.handle('assets:read', async (_event, assetPath) => {
  if (typeof assetPath !== 'string' || !assetPath.trim() || assetPath.startsWith('data:')) return assetPath || null;
  try {
    const file = await fs.readFile(assetPath);
    if (file.byteLength > 128 * 1024 * 1024) return null;
    const extension = path.extname(assetPath).toLowerCase();
    const mime = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.gif': 'image/gif', '.webp': 'image/webp', '.bmp': 'image/bmp', '.mp4': 'video/mp4', '.webm': 'video/webm', '.mov': 'video/quicktime', '.mkv': 'video/x-matroska', '.avi': 'video/x-msvideo', '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.m4a': 'audio/mp4', '.aac': 'audio/aac', '.ogg': 'audio/ogg', '.flac': 'audio/flac' }[extension] || 'application/octet-stream';
    return `data:${mime};base64,${file.toString('base64')}`;
  } catch {
    return null;
  }
});

ipcMain.handle('sync:request', async (_event, payload = {}) => {
  const configuredBaseUrl = String(payload.baseUrl || process.env.DIARY_SYNC_URL || 'http://127.0.0.1:8787')
    .trim()
    .replace(/\/$/, '');
  const url = configuredBaseUrl.endsWith('/sync')
    ? configuredBaseUrl
    : `${configuredBaseUrl}/api/v1/sync`;
  const token = process.env.SYNC_AUTH_TOKEN || '';

  try {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers.Authorization = `Bearer ${token}`;
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload.body || {}),
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

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
