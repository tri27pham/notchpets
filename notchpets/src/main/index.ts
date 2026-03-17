import { app } from 'electron'
import { createNotchWindow, registerPanelIPC } from './notchWindow'

app.whenReady().then(() => {
  createNotchWindow()
  registerPanelIPC()
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
