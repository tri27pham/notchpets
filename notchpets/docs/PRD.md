# notchpets — Product Requirements Document
**v2.1 — March 2026**

---

## 1. Overview

notchpets is a macOS menu bar / notch companion app for two people. Each user has a pixel art pet that lives in a shared panel surrounding the MacBook notch. Both pets are visible to both users in real time — you can see your partner's pet, interact with it, watch it react to whatever they are listening to, and send each other messages as floating pixel art speech bubbles.

The experience is intimate and ambient — always there, never intrusive. It is built for couples, close friends, or long-distance pairs who want a persistent, playful presence on each other's screens.

---

## 2. Problem

- Long-distance relationships lack a persistent, low-friction sense of presence between messages and calls.
- Existing tools (iMessage, WhatsApp) are transactional — you open them, you send, you close. There is no ambient awareness.
- Tamagotchi-style apps are single-player and disconnected from your actual computing environment.
- There is no pixel art, notch-native, real-time shared pet app for macOS.

---

## 3. Goals

### 3.1 Primary goals

- Ship a working native macOS app that two users can link together via an invite code.
- Render two pixel art pets side by side in a notch-surrounding panel, each in their own customisable pixel art background.
- Sync all pet state, interactions, now-playing data, and messages in real time across both machines.
- Make the experience feel delightful — pixel art aesthetic throughout, smooth animations, zero latency feel.

### 3.2 Non-goals (v1)

- Mobile app companion (future).
- Groups of more than two users.
- Pet breeding, evolution, or persistent progression beyond hunger/happiness stats.
- App Store distribution (direct download only for v1).

---

## 4. Users

notchpets is designed for exactly two users linked as a pair. There is no solo mode in v1.

| | |
|---|---|
| **Primary users** | Couples or close friends, one MacBook each |
| **Technical comfort** | Non-technical — setup must be friction-free |
| **Usage pattern** | Ambient background presence, checked casually throughout the day |
| **Geography** | Same city or long-distance — both valid |

---

## 5. Technology stack

| | |
|---|---|
| **App framework** | SwiftUI + AppKit (NSPanel for the notch window) |
| **Pet rendering** | SwiftUI `Image` — static pixel art image per species (v1). SpriteKit spritesheet animation added in v2. |
| **Backend** | Supabase (Postgres + Auth + Realtime + Storage + Edge Functions) |
| **Supabase client** | supabase-swift SDK — Auth, PostgREST, Realtime channels |
| **Real-time sync** | Supabase Realtime — WebSocket channels keyed on pair ID |
| **Now-playing detection** | macOS MediaRemote private framework via `@_silgen_name` — integrated directly, no helper binary |
| **Asset pipeline** | Static pixel art images per species (v1). Spritesheets for animation added in v2. |
| **Session storage** | macOS Keychain via Security framework |
| **Auto-updates** | Sparkle framework |
| **Distribution** | Direct download .dmg, signed with Developer ID |
| **Notch positioning** | NSPanel with `level = .mainMenu + 3`, positioned using `NSScreen.safeAreaInsets` and `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` |
| **Minimum macOS** | macOS 13 Ventura |

---

## 6. Features

### 6.1 Notch panel

The app renders a borderless, transparent NSPanel that surrounds the MacBook notch. The notch cap (the area over the physical hardware cutout) is transparent, blending with the natural black of the display. The panel expands downward on hover or click of the notch region.

- Panel width: matched precisely to the physical notch width using `NSScreen.auxiliaryTopLeftArea` and `auxiliaryTopRightArea`
- Notch cap height: matched to `NSScreen.safeAreaInsets.top` — the physical notch height
- Expanded height: ~160px below the notch cap
- Collapsed state: notch cap only — thin visible presence at the notch edges
- Expand/collapse: smooth SwiftUI animation on hover via `NSTrackingArea`
- Always on top: `level = .mainMenu + 3` — floats above all other apps
- Multi-space: `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
- macOS version support: macOS 13 Ventura and above

### 6.2 Account system & pairing

Users sign up with email (magic link via Supabase Auth). After creating an account, one user generates a 6-character invite code. The other user enters it to form a permanent pair. Each pair has a single shared channel for all real-time data.

| | |
|---|---|
| **Auth method** | Magic link email (no passwords) |
| **Pairing** | 6-character alphanumeric invite code, expires after 24 hours |
| **Pair structure** | One-to-one, permanent — no re-pairing in v1 |
| **Session** | Persistent login stored in macOS Keychain, auto-refresh via supabase-swift |

### 6.3 Pets

Each user owns one pet. Both pets are visible in the shared panel — your pet on the left, your partner's pet on the right (or based on join order). Either user can interact with either pet.

#### Pet species (v1 roster)

- Cat
- Dog
- Frog
- Panda
- Penguin
- Rabbit

**v1 — Static image per species**

Each species has a single static pixel art image displayed in the panel. No animation in v1.

**v2 — Full spritesheet animation (deferred)**

Each species will have a full pixel art spritesheet with the following animation states:

- **idle** — breathing loop, ~2s cycle. Default state when no interaction is happening.
- **happy** — bouncing, triggered by tapping/clicking the pet or when a partner message arrives.
- **eating** — nom animation, triggered by the feed button. Grants +30 hunger.
- **playing** — running / spinning, triggered by double-tapping the pet or the play button. Grants +25 happiness.
- **sleeping** — zZz loop, auto-triggered when idle for 5+ minutes or happiness < 20. Tap pet to wake.
- **sad** — drooping loop, auto-triggered when hunger < 20. Feed to recover.
- **dancing** — short dance loop, triggered when a new track starts playing (MediaRemote).
- **run** — legs cycling, used while pet moves horizontally across the panel during ball-catch.
- **jump** — rise → peak → fall arc, used during ball catch approach.
- **catch** — reach/grab/land sequence, plays once on successful catch then returns to idle.

#### Interaction triggers

| Action | Animation | Effect |
|---|---|---|
| **Tap pet** | happy | Pet bounces — no stat change |
| **Double-tap pet** | playing | Pet spins — +25 happiness (capped at 100) |
| **Feed button** | eating | Pet eats — +30 hunger (capped at 100) |
| **Idle 5+ minutes** | sleeping | Pet falls asleep — tap to wake |
| **Hunger < 20** | sad | Pet droops — feed to recover |
| **Happiness < 20** | sleeping | Pet sleeps — play or tap to recover |
| **Track changes** | dancing | Pet dances when new music detected via MediaRemote |
| **Throw ball** | run → jump → catch | Pet chases ball across panel — +10 happiness |
| **Partner sends message** | happy | Pet bounces when a message arrives |

#### Pet stats

| | |
|---|---|
| **Hunger** | 0–100. Starts at 100. Decays 5 points per 30 minutes via cron. |
| **Happiness** | 0–100. Starts at 100. Decays 3 points per 30 minutes via cron. |
| **Feed action** | +30 hunger (capped at 100). Triggers eating animation on both screens. |
| **Play action** | +25 happiness (capped at 100). Triggers playing animation on both screens. |
| **Notification** | Local push notification when either pet reaches hunger or happiness < 20. |
| **Cross-interaction** | Either user can feed or play with either pet. |

### 6.4 Backgrounds

Each user independently selects a pixel art background scene for their pet. The background applies only to their pet's side of the panel. Backgrounds sync — both users see user A's background behind user A's pet, and user B's background behind user B's pet.

#### Background scenes (v1 roster)

- Bedroom
- Rainy window
- Forest
- Mount Fuji
- Cafe
- Beach
- Library
- Snowy field

Backgrounds are static pixel art scenes at 200×160px. No parallax or animation in v1. User selects via a scene picker in the settings panel.

### 6.5 Ball-catching mini-game *(v2 — deferred)*

Either user can throw a ball to either pet. The pet runs across the panel to catch it, jumps, grabs the ball, lands, then returns to idle. Requires spritesheet animations — deferred to v2.

| | |
|---|---|
| **Trigger** | User taps a throw button in the interaction controls |
| **Sequence** | idle → run (looping while moving) → jump → catch → idle |
| **Pet movement** | SpriteKit `SKAction.moveBy` moves the sprite's x position while the run frames cycle |
| **Ball sprite** | Separate sprite with a short spin animation, travels from one side to the other |
| **Sync** | Throw action written to Supabase, broadcast via Realtime — both screens see the animation |
| **Happiness effect** | Successful catch grants +10 happiness |

### 6.6 Messages

Either user can send a message that appears as a pixel art speech bubble above their own pet. Only one message exists at a time per user — sending a new message replaces the previous one. Messages are free text, capped at 48 characters to fit the bubble.

| | |
|---|---|
| **Input** | Free text, 48 character cap |
| **Display** | Pixel art speech bubble above sender's pet |
| **Persistence** | Single message per user — new message replaces old immediately |
| **Sync** | Real-time via Supabase Realtime — appears on partner's screen within ~200ms |
| **Fade** | Bubble fades out after 60 seconds if no new message is sent |
| **Font** | Pixel bitmap font (e.g. Press Start 2P or similar CC0 font) |

### 6.7 Now playing

The app automatically detects whatever is currently playing on each user's machine using the macOS MediaRemote private framework — the same system used by Boring Notch, NowPlaying CLI, and the macOS lock screen media controls. No account connection or OAuth required. Works with Spotify, Apple Music, YouTube, or any app that registers with the system audio session.

MediaRemote is integrated directly into the Swift app via `@_silgen_name` function declarations. No separate helper binary or child process is needed — the app subscribes to now-playing change notifications natively on the main process.

| | |
|---|---|
| **Detection method** | macOS MediaRemote framework (private API, safe for direct .dmg distribution) |
| **Integration** | Native Swift — `@_silgen_name` declarations, no helper binary required |
| **Works with** | Any app registered with the system audio session — Spotify, Apple Music, browser, etc. |
| **Data** | Track title + artist name, playing/paused state |
| **Update trigger** | Event-driven via `MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler` — no polling |
| **Display** | Small pixel art bubble above the pet: music note icon + track name + artist (truncated to 24 chars) |
| **Sync** | Track info written to pets table on change, broadcast via Realtime to partner's screen |
| **No playback** | Bubble hidden when nothing is playing or machine is paused |
| **Pet reaction** | Pet does a small dance animation when track changes (v2 — requires spritesheet). |
| **App Store** | Not compatible — private API. Irrelevant for v1 direct .dmg distribution. |

---

## 7. Data model

### users (managed by Supabase Auth)

- `id` — uuid, primary key
- `email` — text

### pairs

- `id` — uuid, primary key
- `user_a` — uuid, references auth.users
- `user_b` — uuid, references auth.users
- `created_at` — timestamptz

### invites

- `id` — uuid, primary key
- `code` — text (6 chars), unique
- `creator_id` — uuid, references auth.users
- `created_at` — timestamptz
- `expires_at` — timestamptz (24h from creation)
- `accepted` — boolean, default false

### pets

- `id` — uuid, primary key
- `pair_id` — uuid, references pairs
- `owner_id` — uuid, references auth.users
- `name` — text
- `species` — text (`cat` | `dog` | `frog` | `panda` | `penguin` | `rabbit`)
- `background` — text (`bedroom` | `forest` | `mount_fuji` | `cafe` | `beach` | `library` | `rainy_window` | `snowy_field`)
- `hunger` — int, default 100
- `happiness` — int, default 100
- `last_fed` — timestamptz
- `last_played` — timestamptz
- `current_message` — text, nullable (max 48 chars)
- `message_sent_at` — timestamptz, nullable
- `current_track_name` — text, nullable
- `current_track_artist` — text, nullable
- `updated_at` — timestamptz

---

## 8. Real-time sync

All state is stored in Postgres. Both Swift clients subscribe to a Supabase Realtime channel keyed on their pair ID via the supabase-swift SDK. Any mutation to the pets table (feed, play, message, now-playing update, background change) broadcasts to both subscribers immediately.

| | |
|---|---|
| **Channel key** | `pair:{pair_id}` |
| **Subscribed table** | pets — all columns |
| **Events** | UPDATE only (no inserts/deletes after setup) |
| **Expected latency** | < 200ms under normal network conditions |
| **Offline handling** | Client queues interactions locally, syncs on reconnect. Shows stale state with a small indicator. |
| **Conflict resolution** | Last-write-wins — Supabase updated_at timestamp |

---

## 9. Edge functions

| | |
|---|---|
| **pet-decay** | Cron: every 30 minutes. Decrements hunger by 5 and happiness by 3 for all pets. Floors at 0. |
| **invite-cleanup** | Cron: every hour. Deletes expired (>24h) unaccepted invite rows. |

---

## 10. Setup & onboarding flow

### 10.1 First launch

- User opens app for the first time — sees a pixel art splash screen with the notchpets logo.
- Prompted to enter email — magic link sent.
- On click, session established — user lands in the setup wizard.

### 10.2 Setup wizard (4 steps)

- **Step 1** — Choose your pet species from the pixel art roster.
- **Step 2** — Name your pet (up to 12 characters).
- **Step 3** — Choose your background scene.
- **Step 4** — Pair with your partner: either generate an invite code or enter one received from a partner.

### 10.3 Post-pairing

- Both pets appear in the panel immediately once the pair is confirmed.
- Now-playing detection begins automatically — no setup required.
- App minimises to notch — panel accessible on hover.

---

## 11. Settings panel

Accessible via a gear icon in the expanded notch panel. Settings are personal — they do not affect the partner's view except where noted.

| | |
|---|---|
| **Change pet background** | Personal — only changes your pet's background scene. Syncs to partner's view. |
| **Change pet name** | Personal — renames your pet. Syncs to partner's view. |
| **Notification preferences** | Personal — toggle hunger / happiness alerts on/off. |
| **Sign out** | Clears session from Keychain. Pet remains in Postgres, stats continue decaying. |
| **Delete pair** | Destructive. Removes the pair permanently. Requires confirmation. |

---

## 12. Build order

Recommended implementation sequence for a vibe-coded build with heavy Claude Code usage:

- **Stage 1** — Swift/SwiftUI app shell. NSPanel notch window. Hover expand/collapse. Static panel renders correctly. ✓
- **Stage 2** — Pet data model (UserDefaults). Static pet image + background in panel. ✓
- **Stage 3** — SpriteKit animations for one species (penguin). Animation state machine proven.
- **Stage 4** — All 6 species animated. All 8 backgrounds added. Setup wizard for species/name/background selection.
- **Stage 5** — Local messaging. Speech bubble appears above own pet on own screen only.
- **Stage 6** — Spotify / now-playing detection via MediaRemote. Music bubble on own screen only.
- **Stage 7** — Supabase backend, auth, pairing. All local state (pets, messages, now-playing) wired to real-time sync.
- **Stage 8** — Local notifications, settings panel, .dmg packaging, Sparkle auto-updates.

---

## 13. Open questions

| | |
|---|---|
| **Pet customisation depth** | Should users be able to name the partner's pet or only their own? |
| **Message history** | Should there be a way to see the last N messages sent, or strictly one at a time? |
| **Unpaired state** | What should the panel show if one user is signed out or has lost connection? |
| **Sound** | Should interactions (feed, play, message) have optional pixel art sound effects? |
| **Background animation** | Should any background scenes have subtle looping animation (rain, stars) in v2? |
| **Pet switching** | Can a user change their pet species after initial setup, or is it permanent? |

---

*notchpets — PRD v2.0 — March 2026*
