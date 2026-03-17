# Implementation Plan

# notchpets — Implementation Plan
**For use with Claude Code — v1.0 — March 2026**

---

## How to use this document

This plan is structured as six sequential stages. Each stage has a clear goal, a file structure, explicit acceptance criteria, and a ready-to-paste Claude Code prompt. Complete each stage fully before moving to the next — later stages depend on earlier ones being stable.

At the start of each Claude Code session, paste the stage prompt verbatim. Claude Code will scaffold the required files. Review the acceptance criteria before calling a stage done. Do not move forward until every checkbox passes.

**Stack:** Electron + React + TypeScript, Supabase (Postgres, Auth, Realtime, Edge Functions), HTML Canvas for pet rendering, compiled Swift binary for system now-playing detection.

---

## Pre-stage: project initialisation

Run these commands once before starting Stage 1. Claude Code does not need to do this — run them manually in terminal.

```bash
mkdir notchpets && cd notchpets
npm create electron-vite@latest . -- --template react-ts
npm install
npm install @supabase/supabase-js
npm install electron-store
npm install -D @types/node

# Supabase project
npx supabase init
npx supabase login
# Create a new project at supabase.com, copy your project URL and anon key
```

Create a `.env` file at the project root:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

---

## Stage 1 — Notch window & static panel
*Get a transparent panel rendering beneath the MacBook notch*

### Goal

A frameless transparent Electron window sits directly beneath the notch. It collapses to a 4px strip and expands to the full panel on hover. No real data yet — static placeholder pets and backgrounds only.

### Files created this stage

```
src/
  main/
    index.ts          # Electron main process
    notchWindow.ts    # Window creation, positioning, show/hide logic
  renderer/
    App.tsx           # Root component
    Panel.tsx         # Expanded panel layout (two pet slots)
    PetSlot.tsx       # Single pet area (canvas + placeholder art)
    panel.css         # Pixel art panel styles
  shared/
    constants.ts      # Panel dimensions, animation timings
```

### Key implementation details

- **Window:** BrowserWindow with `frame: false`, `transparent: true`, `alwaysOnTop: true`, `hasShadow: false`
- **Positioning:** read `screen.getPrimaryDisplay().workArea` — position window so top edge sits at `workArea.y` (just below notch safe area)
- **Width:** 400px centred on the screen horizontally
- **Collapsed height:** 4px. Expanded height: 160px
- **Expand trigger:** IPC message from renderer on `mouseenter` of the strip, collapse on `mouseleave` with a 300ms debounce
- **Animation:** CSS transition on height, pixel-art easing (`steps()` or `ease-out`)
- **Always on top:** `setAlwaysOnTop(true, 'screen-saver')` so it floats above full-screen apps
- **All spaces:** `setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })`
- **Ignore mouse when collapsed:** `setIgnoreMouseEvents(true)` in collapsed state, `false` when expanded

### Acceptance criteria

- [ ] App launches without errors
- [ ] A thin 4px strip is visible at the top-centre of the screen beneath the notch
- [ ] Hovering the strip expands the panel smoothly downward to 160px
- [ ] Moving the mouse off the panel collapses it after ~300ms
- [ ] Two placeholder pet areas are visible side by side when expanded
- [ ] Panel sits above all other windows including full-screen apps
- [ ] Panel persists across all macOS Spaces
- [ ] Clicking elsewhere does not steal focus from the active app
- [ ] Window has no title bar, shadow, or visible chrome

### Claude Code prompt

```
Build Stage 1 of the notchpets Electron app: the notch window and static panel.

Stack: Electron + React + TypeScript + Vite. The project has already been initialised
with npm create electron-vite. Do not reinitialise — only create/edit files listed below.

Create the following files:

src/main/notchWindow.ts
- Export a createNotchWindow() function
- BrowserWindow config: width 400, height 4 (collapsed), frame false, transparent true,
  alwaysOnTop true with level 'screen-saver', hasShadow false, resizable false,
  skipTaskbar true
- Centre horizontally on primary display
- Position top edge at screen.getPrimaryDisplay().workArea.y
- setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
- setIgnoreMouseEvents(true) in collapsed state
- Export expandPanel() and collapsePanel() functions that animate height 4 <-> 160
  and toggle setIgnoreMouseEvents accordingly
- Listen for IPC channels 'panel:expand' and 'panel:collapse'

src/main/index.ts
- Import and call createNotchWindow() on app ready
- Register IPC handlers for panel:expand and panel:collapse

src/renderer/Panel.tsx
- Full-width flex row containing two <PetSlot> components
- mouseenter fires ipcRenderer.send('panel:expand')
- mouseleave fires ipcRenderer.send('panel:collapse') after 300ms debounce

src/renderer/PetSlot.tsx
- 180x150px container
- Solid pixel art placeholder background (#1a1a2e)
- Centred 32x32 white square as placeholder pet sprite

src/shared/constants.ts
- PANEL_WIDTH = 400, PANEL_COLLAPSED = 4, PANEL_EXPANDED = 160
- PET_SLOT_WIDTH = 180, PET_SLOT_HEIGHT = 150

src/renderer/panel.css
- Import Press Start 2P from Google Fonts
- Panel background: transparent
- PetSlot: pixel-rendering: pixelated, image-rendering: pixelated
- No box shadows, no blur

src/renderer/App.tsx
- Render <Panel /> only, no other wrapper

Use TypeScript throughout. No placeholder comments — all code must be functional.
Do not install any additional npm packages.
```

---

## Stage 2 — Supabase backend & auth
*Schema, auth, and invite-based pairing*

### Goal

Supabase schema is fully migrated. Magic link auth works. A user can generate an invite code and a second user can enter it to form a pair. Both users' `pair_id` is stored in app state and persisted across restarts via electron-store.

### Files created this stage

```
supabase/
  migrations/
    001_schema.sql          # All tables: pairs, invites, pets
  functions/
    pet-decay/index.ts      # Cron: hunger/happiness decay
    invite-cleanup/index.ts # Cron: expired invite deletion
src/
  main/
    store.ts                # electron-store wrapper (session, pairId)
  renderer/
    supabase.ts             # Supabase client initialisation
    auth/
      AuthGate.tsx          # Wraps app — shows login if no session
      LoginScreen.tsx       # Magic link email input
      PairScreen.tsx        # Generate or enter invite code
  shared/
    types.ts                # User, Pet, Pair, Invite TypeScript types
```

### Database schema

```sql
-- pairs
id uuid primary key default gen_random_uuid()
user_a uuid references auth.users
user_b uuid references auth.users
created_at timestamptz default now()

-- invites
id uuid primary key default gen_random_uuid()
code text unique not null
creator_id uuid references auth.users
created_at timestamptz default now()
expires_at timestamptz not null
accepted boolean default false

-- pets
id uuid primary key default gen_random_uuid()
pair_id uuid references pairs
owner_id uuid references auth.users
name text not null
species text not null
background text not null
hunger int default 100
happiness int default 100
last_fed timestamptz
last_played timestamptz
current_message text
message_sent_at timestamptz
current_track_name text
current_track_artist text
updated_at timestamptz default now()
```

### Acceptance criteria

- [ ] `supabase db push` runs without errors
- [ ] Magic link email is sent and clicking it opens the app and establishes a session
- [ ] Session persists across app restarts (electron-store)
- [ ] User A can generate a 6-character invite code
- [ ] User B can enter the code and a pairs row is created linking both users
- [ ] `pair_id` is written to electron-store on both machines after pairing
- [ ] Expired invites (>24h) are not accepted
- [ ] pet-decay Edge Function deploys and decrements hunger/happiness on schedule
- [ ] All tables have RLS enabled (even if policies are permissive for now)

### Claude Code prompt

```
Build Stage 2 of notchpets: Supabase backend, auth, and pairing flow.

Supabase project is already initialised (supabase/ directory exists).
VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY are set in .env.

Create supabase/migrations/001_schema.sql with the following tables:
pairs (id, user_a, user_b, created_at)
invites (id, code unique, creator_id, created_at, expires_at, accepted bool default false)
pets (id, pair_id, owner_id, name, species, background, hunger int default 100,
  happiness int default 100, last_fed, last_played, current_message,
  message_sent_at, current_track_name, current_track_artist, updated_at)
Enable RLS on all tables. Add a permissive policy for authenticated users for now.

Create supabase/functions/pet-decay/index.ts:
- Deno cron every 30 minutes
- UPDATE pets SET hunger = GREATEST(0, hunger - 5), happiness = GREATEST(0, happiness - 3)

Create supabase/functions/invite-cleanup/index.ts:
- Deno cron every hour
- DELETE FROM invites WHERE expires_at < now() AND accepted = false

Create src/renderer/supabase.ts:
- Initialise Supabase client from import.meta.env values
- Export typed client

Create src/shared/types.ts with TypeScript interfaces for:
User, Pet, Pair, Invite — matching the schema exactly

Create src/main/store.ts:
- electron-store wrapper
- get/set for: session (Supabase session object), pairId (string), userId (string)

Create src/renderer/auth/AuthGate.tsx:
- On mount, check supabase.auth.getSession()
- If no session, show <LoginScreen />
- If session but no pairId in store, show <PairScreen />
- Otherwise render children

Create src/renderer/auth/LoginScreen.tsx:
- Email input + Send magic link button
- Calls supabase.auth.signInWithOtp({ email })
- Shows confirmation message after send
- Full pixel art styling: dark background, chunky border, Press Start 2P font

Create src/renderer/auth/PairScreen.tsx:
- Two tabs: Generate code / Enter code
- Generate: calls a generateInvite() function that inserts into invites table
  with a random 6-char code (A-Z, 2-9) and expires_at = now() + interval '24 hours'
  Displays the code in large pixel art text
- Enter: text input for 6-char code, on submit:
  1. Fetch invite row by code where accepted = false and expires_at > now()
  2. Insert into pairs (user_a = invite.creator_id, user_b = current user)
  3. Update invite set accepted = true
  4. Store pairId in electron-store
  5. Redirect to main app

Wrap src/renderer/App.tsx in <AuthGate>.

Use TypeScript throughout. Handle loading and error states in all async operations.
```

---

## Stage 3 — Pet rendering & setup wizard
*Spritesheet animation, backgrounds, and onboarding*

### Goal

Pets are rendered on HTML Canvas using pixel art spritesheets with a full animation state machine. New users complete a setup wizard to choose species, name their pet, and pick a background. Pet data is written to Supabase and rendered live in the panel.

### Files created this stage

```
src/
  renderer/
    canvas/
      PetCanvas.tsx        # Canvas component, drives animation loop
      SpriteEngine.ts      # Spritesheet loader, frame sequencer
      AnimationState.ts    # State machine (idle/happy/eating/playing/sleeping/sad/dancing)
    setup/
      SetupWizard.tsx      # 3-step wizard: species, name, background
      SpeciesPicker.tsx    # Grid of pixel art pet previews
      BackgroundPicker.tsx # Grid of background scene thumbnails
    hooks/
      usePets.ts           # Fetch both pets for current pair, subscribe to changes
  assets/
    sprites/               # Spritesheet PNGs per species (sourced externally)
    backgrounds/           # Background scene PNGs (sourced externally)
    sprite-manifest.ts     # Frame coords, animation sequences per species
```

### Animation state machine

| State | Behaviour |
|---|---|
| **idle** | Default. Breathing loop ~2s. Triggered on init and after any other state completes. |
| **happy** | Bouncing loop. Triggered when feed or play action is received. Plays once then returns to idle. |
| **eating** | Nom animation. Triggered by feed action. Plays once then returns to idle. |
| **playing** | Running or spinning. Triggered by play action. Plays once then returns to idle. |
| **sleeping** | zZz loop. Auto-triggered when happiness < 20. Overrides idle until happiness >= 20. |
| **sad** | Drooping loop. Auto-triggered when hunger < 20. Overrides idle until hunger >= 20. |
| **dancing** | Short dance loop. Triggered when current_track changes. Plays once then returns to idle. |

### Asset sourcing note

Spritesheets and backgrounds are not generated by Claude Code — source them from itch.io before starting this stage. Recommended search terms: `pixel art cat sprite sheet free`, `pixel art game backgrounds`. All assets must be CC0 or have a commercial-friendly licence. Place PNGs in `src/assets/sprites/` and `src/assets/backgrounds/` before running the Stage 3 prompt.

### Acceptance criteria

- [ ] New user sees the 3-step setup wizard after pairing
- [ ] Species picker shows all 6 options with preview sprites
- [ ] Background picker shows all 8 scenes
- [ ] Completing the wizard writes a pets row to Supabase
- [ ] Both pets render on canvas in the panel with correct backgrounds
- [ ] Idle animation plays continuously for both pets
- [ ] Animation state transitions are smooth with no frame flickering
- [ ] Canvas pauses `requestAnimationFrame` when panel is collapsed
- [ ] Sad state triggers automatically when hunger < 20
- [ ] Sleeping state triggers automatically when happiness < 20

### Claude Code prompt

```
Build Stage 3 of notchpets: pet canvas rendering, animation state machine, and setup wizard.

Stages 1 and 2 are complete. Supabase client, auth, pair_id in store, and the panel
layout all exist. Pixel art spritesheet PNGs are already in src/assets/sprites/ and
background PNGs are in src/assets/backgrounds/.

Create src/assets/sprite-manifest.ts:
- Export a SpriteManifest type: { [species: string]: { frameWidth, frameHeight,
  animations: { [state: string]: { row: number, frames: number, fps: number, loop: boolean } } } }
- Export a manifest object for all 6 species: cat, dog, frog, panda, penguin, rabbit
- All species share the same animation states: idle, happy, eating, playing, sleeping, sad, dancing

Create src/renderer/canvas/SpriteEngine.ts:
- Class SpriteEngine(canvas: HTMLCanvasElement, species: string)
- Loads the correct spritesheet PNG via new Image()
- setState(state: AnimationStateName): switches animation, resets frame counter
- tick(timestamp: number): advances frame based on fps, draws current frame to canvas
- Returns to 'idle' automatically after non-looping animations complete

Create src/renderer/canvas/AnimationState.ts:
- Type AnimationStateName = 'idle' | 'happy' | 'eating' | 'playing' | 'sleeping' | 'sad' | 'dancing'
- Export getAutoState(hunger: number, happiness: number): AnimationStateName
  Returns 'sad' if hunger < 20, 'sleeping' if happiness < 20, else 'idle'

Create src/renderer/canvas/PetCanvas.tsx:
- Props: species, background, hunger, happiness, triggerAnimation?: AnimationStateName
- Renders a <canvas> at 180x150px with image-rendering: pixelated
- Draws background PNG first, then pet sprite on top each frame
- Uses SpriteEngine for sprite rendering
- requestAnimationFrame loop — pauses when document is hidden
- Responds to triggerAnimation prop changes by calling engine.setState()
- Automatically calls engine.setState(getAutoState(hunger, happiness)) when hunger/happiness
  change and no triggered animation is playing

Create src/renderer/hooks/usePets.ts:
- Fetches both pets for the current pair_id from Supabase on mount
- Subscribes to Supabase Realtime channel 'pair:{pair_id}' for UPDATE events on pets table
- Returns { myPet, partnerPet, loading, error }
- Cleans up subscription on unmount

Create src/renderer/setup/SpeciesPicker.tsx:
- Grid of 6 species options, each showing a static preview frame from the spritesheet
- Highlights selected species with a pixel art border

Create src/renderer/setup/BackgroundPicker.tsx:
- Grid of 8 background thumbnails: bedroom, rainy_window, forest, mount_fuji,
  cafe, beach, library, snowy_field
- Highlights selected background

Create src/renderer/setup/SetupWizard.tsx:
- Step 1: SpeciesPicker
- Step 2: Pet name input (12 char max, pixel art text input)
- Step 3: BackgroundPicker
- On complete: INSERT into pets table with pair_id, owner_id, name, species, background,
  hunger 100, happiness 100. Store petId in electron-store. Navigate to main panel.

Update src/renderer/Panel.tsx:
- Use usePets() to get myPet and partnerPet
- Render <PetCanvas> in each PetSlot with real pet data
- Show SetupWizard if myPet is null

TypeScript throughout. All canvas operations must handle image load timing correctly
(wait for onload before drawing). No additional npm packages.
```

---

## Stage 4 — Interactions & messaging
*Feed, play, speech bubbles, and real-time sync*

### Goal

Either user can click feed or play on either pet. Actions update Supabase, trigger animations on both screens in real time, and update hunger/happiness values. Users can type a message that appears as a pixel art speech bubble above their pet on both screens.

### Files created this stage

```
src/
  renderer/
    interactions/
      PetControls.tsx      # Feed + Play buttons per pet slot
      useInteractions.ts   # Feed/play mutation logic
    messaging/
      MessageBubble.tsx    # Pixel art speech bubble overlay
      MessageInput.tsx     # Text input + send, shown on click
      useMessages.ts       # Message send/receive/fade logic
```

### Interaction logic

| | |
|---|---|
| **Feed** | `UPDATE pets SET hunger = LEAST(100, hunger + 30), last_fed = now()`. Triggers `eating` animation via Realtime on both clients. |
| **Play** | `UPDATE pets SET happiness = LEAST(100, happiness + 25), last_played = now()`. Triggers `playing` animation via Realtime on both clients. |
| **Animation trigger** | After writing to Supabase, the Realtime UPDATE event fires on both clients. Both clients call `engine.setState()` based on the incoming payload. |
| **Message send** | `UPDATE pets SET current_message = text, message_sent_at = now()` for sender's pet. Realtime broadcasts to partner. |
| **Message display** | Bubble renders above the pet. Fades out after 60 seconds via a client-side timer. New message resets the timer. |
| **Optimistic UI** | Apply stat changes locally immediately, then write to Supabase. Roll back on error. |

### Acceptance criteria

- [ ] Feed button on either pet increments hunger and triggers eating animation on both screens
- [ ] Play button on either pet increments happiness and triggers playing animation on both screens
- [ ] Hunger and happiness values update visibly in the UI after interaction
- [ ] Animation triggers arrive on the partner's screen within 200ms
- [ ] Typing a message and sending renders a speech bubble above the sender's pet
- [ ] The speech bubble appears on the partner's screen within 200ms
- [ ] Sending a new message replaces the previous bubble immediately
- [ ] Speech bubble fades out after 60 seconds with no new message
- [ ] Optimistic updates are applied immediately, rolled back cleanly on error

### Claude Code prompt

```
Build Stage 4 of notchpets: interactions (feed/play) and messaging.

Stages 1–3 are complete. usePets() hook exists, Realtime subscription to 'pair:{pair_id}'
is live, PetCanvas renders with AnimationState. Supabase client is initialised.

Create src/renderer/interactions/useInteractions.ts:
- Export useFeed(petId: string) and usePlay(petId: string) hooks
- Feed: optimistically sets local hunger = min(100, hunger + 30), then
  UPDATE pets SET hunger = LEAST(100, hunger + 30), last_fed = now() WHERE id = petId
- Play: optimistically sets local happiness = min(100, happiness + 25), then
  UPDATE pets SET happiness = LEAST(100, happiness + 25), last_played = now() WHERE id = petId
- Both roll back local state on Supabase error

Create src/renderer/interactions/PetControls.tsx:
- Props: petId, hunger, happiness
- Two pixel art icon buttons: feed (bone icon) and play (ball icon)
- Buttons are 24x24px, pixel art style
- Calls useFeed / usePlay on click
- Shows hunger and happiness as two small pixel art progress bars (0-100)

Update src/renderer/Panel.tsx PetSlot areas to include <PetControls> below each canvas.

Create src/renderer/messaging/useMessages.ts:
- Tracks current message text and message_sent_at for both pets (already in usePets data)
- Export sendMessage(text: string): UPDATE pets SET current_message = text,
  message_sent_at = now() WHERE id = myPet.id
- Export isBubbleVisible(message_sent_at: string | null): boolean
  Returns true if message_sent_at is within the last 60 seconds
- Re-evaluates visibility every second via setInterval

Create src/renderer/messaging/MessageBubble.tsx:
- Props: message: string | null, visible: boolean
- Pixel art speech bubble shape using CSS border tricks or a small SVG
- Press Start 2P font, 8px size, white text on dark background
- Position: absolute, above the pet canvas
- CSS opacity transition for fade in/out

Create src/renderer/messaging/MessageInput.tsx:
- Small pixel art text input, max 48 chars
- Appears on click of a small chat icon below the user's own pet
- On enter or send button: calls sendMessage(), clears input, hides input field
- Only shown for the user's own pet slot, not the partner's

Update Panel.tsx to compose MessageBubble above each PetCanvas and MessageInput
below the user's own pet slot.

The Realtime subscription in usePets already handles incoming UPDATE events —
animation triggers should fire in usePets when updated_at changes and
an animation state can be inferred from the delta (hunger decreased = eating,
happiness decreased = playing, track changed = dancing).

TypeScript throughout. No additional npm packages.
```

---

## Stage 5 — Now playing detection
*Swift MediaRemote helper + music bubble UI*

### Goal

A compiled Swift binary reads the system now-playing info via the macOS MediaRemote private framework and pipes track data to Electron over stdout. Electron writes the track to Supabase, which broadcasts it via Realtime so the music bubble appears above both pets on both screens. The pet does a brief dance when the track changes.

### Files created this stage

```
swift-helper/
  NowPlaying.swift         # MediaRemote listener, JSON stdout emitter
  build.sh                 # Compile script -> resources/now-playing-helper
resources/
  now-playing-helper       # Compiled binary (gitignored, built locally)
src/
  main/
    nowPlayingBridge.ts    # Spawns helper, parses stdout, sends IPC to renderer
  renderer/
    nowplaying/
      MusicBubble.tsx      # Small pixel art now-playing bubble above pet
      useNowPlaying.ts     # Reads track from pet data, formats display string
```

### Swift helper details

| | |
|---|---|
| **Framework** | MediaRemote (private) — declared via `@_silgen_name` |
| **Trigger** | `MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler` — event-driven, no polling |
| **Output** | JSON to stdout: `{ "title": string, "artist": string, "playing": boolean }` |
| **On nothing playing** | Emits `{ "title": "", "artist": "", "playing": false }` |
| **Compile command** | `swiftc NowPlaying.swift -o ../resources/now-playing-helper` |
| **Electron spawn** | `child_process.spawn('./resources/now-playing-helper')` — reads stdout line by line |

### Acceptance criteria

- [ ] `swift-helper/build.sh` compiles without errors on macOS
- [ ] Running the binary directly in terminal emits JSON when track changes
- [ ] Electron spawns the helper on launch and receives track updates
- [ ] Track name and artist appear in the music bubble above the correct pet
- [ ] Music bubble is hidden when nothing is playing
- [ ] Partner's screen shows the same track bubble within 200ms
- [ ] Pet plays the dancing animation once when the track changes
- [ ] Works with Spotify, Apple Music, and browser-based audio
- [ ] Helper process is killed cleanly when Electron app quits

### Claude Code prompt

```
Build Stage 5 of notchpets: macOS now-playing detection via Swift helper binary.

Stages 1–4 are complete. Supabase Realtime is live, pets table has current_track_name
and current_track_artist columns, usePets() hook returns both fields.

Create swift-helper/NowPlaying.swift:
- Import Foundation
- Use @_silgen_name to declare the following MediaRemote C functions:
  func MRMediaRemoteGetNowPlayingInfo(_ queue: DispatchQueue, _ handler: @escaping ([String: Any]?) -> Void)
  func MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler(_ queue: DispatchQueue, _ handler: @escaping () -> Void)
  let kMRMediaRemoteNowPlayingInfoTitle: String
  let kMRMediaRemoteNowPlayingInfoArtist: String
  let kMRMediaRemoteNowPlayingInfoPlaybackRate: String
- On info change: call MRMediaRemoteGetNowPlayingInfo, extract title, artist, playbackRate
- Print a single JSON line to stdout: {"title":"...","artist":"...","playing":true/false}
- Run indefinitely: dispatchMain()

Create swift-helper/build.sh:
  #!/bin/bash
  swiftc swift-helper/NowPlaying.swift -o resources/now-playing-helper

Create src/main/nowPlayingBridge.ts:
- Import child_process and path
- Export startNowPlayingBridge(pairId: string, userId: string, supabaseClient)
- Spawns ./resources/now-playing-helper as a child process
- Reads stdout line by line, parses JSON
- On each valid track object: UPDATE pets SET current_track_name = title,
  current_track_artist = artist, updated_at = now()
  WHERE owner_id = userId AND pair_id = pairId
- Only writes to Supabase if title has changed (debounce repeated identical events)
- On app quit (app.on('before-quit')): kills the child process

Call startNowPlayingBridge() in src/main/index.ts after session is confirmed.

Create src/renderer/nowplaying/useNowPlaying.ts:
- Takes petData (from usePets)
- Returns formatted display string: truncate to 24 chars — 'Track Name · Artist'
- Returns null if current_track_name is empty

Create src/renderer/nowplaying/MusicBubble.tsx:
- Props: trackDisplay: string | null
- Small pixel art bubble: music note character + track string
- Press Start 2P font at 7px
- Positioned above MessageBubble
- Hidden (opacity 0) when trackDisplay is null

Update Panel.tsx to render <MusicBubble> above each PetCanvas.

The dancing animation trigger: in usePets Realtime handler, if current_track_name
changed in the incoming UPDATE payload, call engine.setState('dancing').

TypeScript in all .ts/.tsx files. Swift in the helper only.
Do not add npm packages. Do not modify the Supabase schema.
```

---

## Stage 6 — Polish, notifications & packaging
*Final UX, alerts, and .dmg build*

### Goal

Local notifications alert users when a pet is hungry or sad. The settings panel allows background and name changes. The animation loop is throttled when the panel is collapsed. The app packages as a signed .dmg ready for direct distribution.

### Files created this stage

```
src/
  main/
    notifications.ts       # macOS local notification logic
    petMonitor.ts          # Polls pet stats, triggers notifications
  renderer/
    settings/
      SettingsPanel.tsx    # Gear icon overlay: name, background, sign out
      useSettings.ts       # Update pet name / background in Supabase
electron-builder.yml       # Build config for .dmg packaging
```

### Polish checklist

| | |
|---|---|
| **Animation throttle** | When panel collapses, cancel `requestAnimationFrame`. Resume on expand. Reduces CPU/battery to near zero when hidden. |
| **Notification: hungry** | Local macOS notification when own or partner's pet hunger drops below 20. Fire once per threshold crossing, not repeatedly. |
| **Notification: sad** | Same pattern for happiness < 20. |
| **Settings panel** | Gear icon in top-right of expanded panel. Opens overlay with: change pet name, change background, sign out button. |
| **Name/background sync** | Changes write to Supabase pets table. Realtime broadcasts update to partner's panel immediately. |
| **Offline indicator** | If Realtime connection drops, show a small pixel art disconnected icon. Auto-reconnects. |
| **App icon** | 32x32 and 512x512 pixel art icon. Set in electron-builder config. |
| **.dmg packaging** | electron-builder with dmg target. Code-sign if Apple Developer account available, otherwise unsigned for personal use. |

### Acceptance criteria

- [ ] CPU usage drops to <1% when panel is collapsed (verify in Activity Monitor)
- [ ] Local notification fires when pet hunger crosses below 20
- [ ] Local notification fires when pet happiness crosses below 20
- [ ] Notifications do not repeat until stat recovers above 20 then drops again
- [ ] Settings panel opens and closes cleanly
- [ ] Changing pet name updates on both screens within 200ms
- [ ] Changing background updates on both screens within 200ms
- [ ] Sign out clears session and returns to login screen
- [ ] `npm run build` produces a valid .dmg that installs and runs on macOS
- [ ] Installed app launches to the notch panel with no console errors

### Claude Code prompt

```
Build Stage 6 of notchpets: notifications, settings panel, animation throttling, and .dmg packaging.

Stages 1–5 are complete and working. The app renders, syncs, plays animations,
and detects now-playing. This stage is polish and packaging only.

Create src/main/notifications.ts:
- Export showNotification(title: string, body: string)
- Uses Electron's Notification API: new Notification({ title, body }).show()

Create src/main/petMonitor.ts:
- Export startPetMonitor(supabaseClient, pairId: string)
- Polls both pets for the pair every 60 seconds
- Tracks last-notified state to avoid repeat notifications
- Calls showNotification when hunger < 20 (once per threshold crossing)
- Calls showNotification when happiness < 20 (once per threshold crossing)
- Resets notification state when stat recovers above 30

Call startPetMonitor() in src/main/index.ts after session confirmed.

Create src/renderer/settings/useSettings.ts:
- Export updatePetName(petId, name): UPDATE pets SET name = name WHERE id = petId
- Export updateBackground(petId, background): UPDATE pets SET background = background WHERE id = petId

Create src/renderer/settings/SettingsPanel.tsx:
- Small gear icon (⚙) in top-right corner of the panel, always visible when expanded
- Click toggles a settings overlay within the panel
- Overlay contains:
  1. Pet name input (pre-filled with current name, 12 char max) + save button
  2. <BackgroundPicker> (reuse from Stage 3) with current background highlighted
  3. Sign out button — calls supabase.auth.signOut(), clears electron-store
- All changes call useSettings hooks and close the overlay on success
- Pixel art styling consistent with rest of app

Update src/renderer/canvas/PetCanvas.tsx:
- Add a prop: active: boolean
- When active is false: cancel requestAnimationFrame loop
- When active becomes true: restart the loop

Update src/renderer/Panel.tsx:
- Track expanded/collapsed state
- Pass active={isExpanded} to both PetCanvas components

Create electron-builder.yml at project root:
  appId: com.notchpets.app
  productName: notchpets
  mac:
    target: dmg
    category: public.app-category.utilities
  dmg:
    title: notchpets
  files:
    - dist/**/*
    - resources/now-playing-helper

Add to package.json scripts:
  "build:dmg": "npm run build && electron-builder --mac"

Install electron-builder as dev dependency.

TypeScript throughout. After this stage the app should be fully functional and packageable.
```

---

## Notes for Claude Code sessions

- Always start a new session by telling Claude Code which stage you are on and pasting the full stage prompt.
- If Claude Code produces code that compiles but fails an acceptance criterion, describe the failure precisely — do not just say "it doesn't work".
- The Swift helper (Stage 5) may require manual debugging. Run it standalone in Terminal first before integrating with Electron.
- Supabase Realtime in TypeScript can be finicky with TypeScript generics — if you hit type errors on the subscription payload, use explicit `any` typing as a workaround and revisit later.
- Pixel art asset quality matters more than code quality for the feel of the app. Spend time sourcing good spritesheets before starting Stage 3.
- Do not skip acceptance criteria. Each stage's criteria exist because later stages will silently break if earlier ones are unstable.

---

*notchpets — Implementation Plan v1.0 — March 2026*