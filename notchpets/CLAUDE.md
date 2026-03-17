# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

notchpets is a macOS menu bar app for two people. Each user has a pixel art pet that lives in a panel beneath the MacBook notch. Both pets sync in real time via Supabase Realtime. See @notchpets/docs/PRD.md for full requirements and @notchpets/docs/IMPLEMENTATION.md for the staged build plan.

**Stack:** Electron + React + TypeScript + Vite, Supabase (Postgres, Auth, Realtime, Edge Functions), HTML Canvas for pet animation, compiled Swift binary for macOS now-playing detection.

## Commands

All commands run from this directory (where `package.json` lives):

```bash
npm run dev       # Start Electron app in development mode
npm run build     # tsc + vite build + electron-builder (.dmg)
npm run lint      # ESLint (0 warnings allowed)
```

## Architecture

### Process split

The scaffold separates Electron main process code from the React renderer:

```
electron/         ← Main process (Node.js + Electron APIs)
  main.ts         ← App entry, BrowserWindow creation
  preload.ts      ← contextBridge — bridges main ↔ renderer
src/              ← Renderer process (React, runs in Chromium)
  main.tsx        ← Renderer entry point
  App.tsx         ← Root component
  shared/         ← Types and constants safe to import in both processes
```

**Never import `electron` directly in `src/` renderer code.** All Electron APIs must go through the preload bridge.

### IPC bridge

`electron/preload.ts` exposes `window.ipcRenderer` via contextBridge. In renderer components use:

```ts
window.ipcRenderer.send('channel', payload)
window.ipcRenderer.on('channel', handler)
window.ipcRenderer.invoke('channel', payload)  // for async request/response
```

`electron/electron-env.d.ts` types `window.ipcRenderer` — reference it with `/// <reference types="vite-plugin-electron/electron-env" />`.

### Build output

- `dist/` — compiled renderer (Vite)
- `dist-electron/` — compiled main + preload (Vite plugin)
- `package.json` `"main"` points to `dist-electron/main.js`

### Notch window (to be built in Stage 1)

The panel is a frameless transparent `BrowserWindow` positioned at `workArea.y` (just below the notch safe area), centred horizontally. It collapses to 4px and expands to 160px on hover via IPC (`panel:expand` / `panel:collapse`). Always-on-top level `screen-saver`, visible on all Spaces and full-screen apps.

### Supabase Realtime

All pet state lives in Postgres. Both clients subscribe to a channel keyed on `pair:{pair_id}` and receive UPDATE events on the `pets` table. Expected latency < 200ms. Last-write-wins conflict resolution via `updated_at`.

### Swift helper (Stage 5)

`swift-helper/NowPlaying.swift` uses the macOS MediaRemote private framework to emit now-playing JSON to stdout. Electron spawns it as a child process on launch and kills it on `before-quit`.

## Key conventions

- Pixel art throughout: `image-rendering: pixelated`, no `border-radius`, no `box-shadow`, Press Start 2P font
- All Supabase tables must have RLS enabled
- `src/shared/` is the only directory safe to import from both `electron/` and `src/` — keep it free of Electron and browser-only APIs
- Canvas `requestAnimationFrame` loop must pause when the panel is collapsed
