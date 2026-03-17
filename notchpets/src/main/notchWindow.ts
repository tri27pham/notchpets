import { BrowserWindow, screen, ipcMain } from 'electron'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { PANEL_WIDTH, PANEL_COLLAPSED, PANEL_EXPANDED } from '../shared/constants'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const VITE_DEV_SERVER_URL = process.env['VITE_DEV_SERVER_URL']

let win: BrowserWindow | null = null

export function createNotchWindow(): BrowserWindow {
  const { workArea } = screen.getPrimaryDisplay()
  const x = Math.round(workArea.x + (workArea.width - PANEL_WIDTH) / 2)
  const y = workArea.y

  win = new BrowserWindow({
    width: PANEL_WIDTH,
    height: PANEL_COLLAPSED,
    x,
    y,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    hasShadow: false,
    resizable: false,
    skipTaskbar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.mjs'),
      contextIsolation: true,
    },
  })

  win.setAlwaysOnTop(true, 'screen-saver')
  win.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
  win.setIgnoreMouseEvents(true)

  if (VITE_DEV_SERVER_URL) {
    win.loadURL(VITE_DEV_SERVER_URL)
  } else {
    win.loadFile(path.join(__dirname, '..', 'dist', 'index.html'))
  }

  return win
}

export function expandPanel(): void {
  if (!win) return
  win.setSize(PANEL_WIDTH, PANEL_EXPANDED)
  win.setIgnoreMouseEvents(false)
}

export function collapsePanel(): void {
  if (!win) return
  win.setSize(PANEL_WIDTH, PANEL_COLLAPSED)
  win.setIgnoreMouseEvents(true)
}

export function registerPanelIPC(): void {
  ipcMain.on('panel:expand', expandPanel)
  ipcMain.on('panel:collapse', collapsePanel)
}
