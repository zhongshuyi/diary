const { contextBridge, ipcRenderer, webUtils } = require('electron');

contextBridge.exposeInMainWorld('diaryAPI', {
  appVersion: '0.1.0',
  platform: 'desktop',
  window: {
    minimize: () => ipcRenderer.invoke('window:minimize'),
    maximize: () => ipcRenderer.invoke('window:maximize'),
    isMaximized: () => ipcRenderer.invoke('window:isMaximized'),
    close: () => ipcRenderer.invoke('window:close'),
  },
  assets: {
    pickMedia: () => ipcRenderer.invoke('assets:pickMedia'),
    saveClipboard: (payload) => ipcRenderer.invoke('assets:saveClipboard', payload),
    importFiles: (paths) => ipcRenderer.invoke('assets:importFiles', paths),
    pathForFile: (file) => {
      try {
        return webUtils.getPathForFile(file);
      } catch {
        return '';
      }
    },
    read: (assetPath) => ipcRenderer.invoke('assets:read', assetPath),
  },
  sync: (payload) => ipcRenderer.invoke('sync:request', payload),
});
