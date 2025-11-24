// Preload exposing IPC bridge
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('BladeAPI', {
  evalAgency: (features) => ipcRenderer.invoke('agency:eval', features),
  queryTruth: (question) => ipcRenderer.invoke('truth:query', question),
  getSovereignStatus: () => ipcRenderer.invoke('sovereign:status')
});
