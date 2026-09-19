const { contextBridge, ipcRenderer, webUtils } = require('electron');

contextBridge.exposeInMainWorld('diaryAPI', {
  appVersion: '0.1.0',
  platform: 'desktop',
  window: {
    minimize: () => ipcRenderer.invoke('window:minimize'),
    maximize: () => ipcRenderer.invoke('window:maximize'),
    isMaximized: () => ipcRenderer.invoke('window:isMaximized'),
    close: () => ipcRenderer.invoke('window:close'),
    quit: () => ipcRenderer.invoke('window:quit'),
  },
  quickCapture: {
    hide: () => ipcRenderer.invoke('quick-capture:hide'),
    show: () => ipcRenderer.invoke('quick-capture:show'),
    status: () => ipcRenderer.invoke('quick-capture:status'),
    setShortcut: (value) => ipcRenderer.invoke('quick-capture:set-shortcut', value),
    onOpen: (handler) => {
      const listener = () => handler?.();
      ipcRenderer.on('quick-capture:open', listener);
      return () => ipcRenderer.removeListener('quick-capture:open', listener);
    },
  },
  connectionConfig: {
    copy: (settings) => ipcRenderer.invoke('connection-config:copy', settings),
    paste: () => ipcRenderer.invoke('connection-config:paste'),
  },
  assets: {
    pickMedia: () => ipcRenderer.invoke('assets:pickMedia'),
    saveClipboard: (payload) => ipcRenderer.invoke('assets:saveClipboard', payload),
    importFiles: (paths) => ipcRenderer.invoke('assets:importFiles', paths),
    relocate: (currentPath) => ipcRenderer.invoke('assets:relocate', currentPath),
    pathForFile: (file) => {
      try {
        return webUtils.getPathForFile(file);
      } catch {
        return '';
      }
    },
    read: (assetPath, options) => ipcRenderer.invoke('assets:read', assetPath, options),
  },
  sync: (payload) => ipcRenderer.invoke('sync:request', payload),
  updates: {
    check: (baseUrl) => ipcRenderer.invoke('updates:check', { baseUrl }),
    open: (url) => ipcRenderer.invoke('updates:open', url),
  },
  backup: {
    export: () => ipcRenderer.invoke('backup:export'),
    import: () => ipcRenderer.invoke('backup:import'),
  },
  db: {
    bootstrap: (legacyState) => ipcRenderer.invoke('db:bootstrap', legacyState),
    snapshot: () => ipcRenderer.invoke('db:snapshot'),
    listEntries: (options) => ipcRenderer.invoke('db:listEntries', options),
    taxonomyUsage: () => ipcRenderer.invoke('db:taxonomyUsage'),
    attachmentHealth: () => ipcRenderer.invoke('db:attachmentHealth'),
    saveEntry: (entry) => ipcRenderer.invoke('db:saveEntry', entry),
    saveDraft: (draft) => ipcRenderer.invoke('db:saveDraft', draft),
    loadDraft: (id) => ipcRenderer.invoke('db:loadDraft', id),
    clearDraft: (id) => ipcRenderer.invoke('db:clearDraft', id),
    onQuickCaptureSaved: (handler) => {
      const listener = () => handler?.();
      ipcRenderer.on('db:quick-capture-saved', listener);
      return () => ipcRenderer.removeListener('db:quick-capture-saved', listener);
    },
    saveSetting: (key, value) => ipcRenderer.invoke('db:saveSetting', { key, value }),
    applySync: (payload) => ipcRenderer.invoke('db:applySync', payload),
    trashEntry: (id) => ipcRenderer.invoke('db:trashEntry', id),
    restoreEntry: (id) => ipcRenderer.invoke('db:restoreEntry', id),
    batchFavorite: (ids, isFavorite) => ipcRenderer.invoke('db:batchFavorite', ids, isFavorite),
    batchTrash: (ids) => ipcRenderer.invoke('db:batchTrash', ids),
    batchRestore: (ids) => ipcRenderer.invoke('db:batchRestore', ids),
    batchOrganize: (ids, options) => ipcRenderer.invoke('db:batchOrganize', ids, options),
    renameTag: (from, to) => ipcRenderer.invoke('db:renameTag', from, to),
    deleteTag: (value) => ipcRenderer.invoke('db:deleteTag', value),
    renameCategory: (from, to) => ipcRenderer.invoke('db:renameCategory', from, to),
    deleteCategory: (value) => ipcRenderer.invoke('db:deleteCategory', value),
    deleteEntry: (id) => ipcRenderer.invoke('db:deleteEntry', id),
    search: (query, options) => ipcRenderer.invoke('db:search', query, options),
  },
});
