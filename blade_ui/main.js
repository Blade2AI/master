// Electron main process skeleton for Blade Boardroom Shell
// Phase 3 - minimal IPC endpoints; expand later
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js')
    }
  });
  win.loadFile('index.html');
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// IPC stubs – will call python backends later
ipcMain.handle('agency:eval', async (_evt, payload) => {
  // placeholder returns static vector; integrate HTTP fetch to python
  return { A1:0.62,A2:0.58,A3:0.51,A4:0.55, AgencyScore:0.57, state:'STEADY' };
});

ipcMain.handle('truth:query', async (_evt, question) => {
  return { answer: 'Truth engine not wired yet.', cites: [] };
});

ipcMain.handle('sovereign:status', async () => {
  return { manifestDate: '2025-11-19', robocopyLast:'04:00 OK', freeSpaceGB: 812, indexStatus:'STALE' };
});
