# notchpets — Product Requirements Document
**v1.0 — March 2026**

---

## 1. Overview

notchpets is a macOS menu bar / notch companion app for two people. Each user has a pixel art pet that lives in a shared panel beneath the MacBook notch. Both pets are visible to both users in real time — you can see your partner's pet, interact with it, watch it react to whatever they are listening to, and send each other messages as floating pixel art speech bubbles.

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

- Ship a working macOS Electron app that two users can link together via an invite code.
- Render two pixel art pets side by side in a notch-adjacent panel, each in their own customisable pixel art background.
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
| **App framework** | Electron + React + TypeScript |
| **Styling** | CSS Modules — pixel art aesthetic, bitmap fonts |
| **Pet rendering** | HTML Canvas with requestAnimationFrame sprite animation |
| **Backend** | Supabase (Postgres + Auth + Realtime + Storage + Edge Functions) |
| **Real-time sync** | Supabase Realtime — WebSocket channels keyed on pair ID |
| **Now-playing detection** | macOS MediaRemote private framework via compiled Swift helper binary — system-wide, works with any audio app, no OAuth required |
| **Asset pipeline** | Pixel art spritesheets sourced from itch.io (CC0 / licensed packs) |
| **Distribution** | Direct download .dmg, auto-update via electron-updater |
| **Notch positioning** | Frameless transparent BrowserWindow positioned below notch safe area |

---

## 6. Features

### 6.1 Notch panel

The app renders a frameless, transparent Electron window positioned directly beneath the MacBook notch. The panel is hidden by default and expands downward on hover or click of the notch region.

- Panel dimensions: ~400px wide × ~160px tall when expanded
- Collapsed state: thin 4px indicator strip visible at notch edge
- Expand/collapse: smooth pixel-art slide animation on hover
- Always on top: window level set to float above all other apps
- Multi-space: panel persists across all macOS Spaces and full-screen apps
- macOS version support: macOS 12 Monterey and above (notch introduced on MacBook Pro 14/16 2021)

### 6.2 Account system & pairing

Users sign up with email (magic link via Supabase Auth). After creating an account, one user generates a 6-character invite code. The other user enters it to form a permanent pair. Each pair has a single shared channel for all real-time data.

| | |
|---|---|
| **Auth method** | Magic link email (no passwords) |
| **Pairing** | 6-character alphanumeric invite code, expires after 24 hours |
| **Pair structure** | One-to-one, permanent — no re-pairing in v1 |
| **Session** | Persistent login stored in Electron keychain, auto-refresh |

### 6.3 Pets

Each user owns one pet. Both pets are visible in the shared panel — your pet on the left, your partner's pet on the right (or based on join order). Either user can interact with either pet.

#### Pet species (v1 roster)

- Cat
- Dog
- Frog
- Panda
- Penguin
- Rabbit

Each species has a full pixel art spritesheet with the following animation states:

- **idle** — breathing loop, ~2s cycle
- **happy** — bouncing, triggered by interaction
- **eating** — nom animation, triggered by feed
- **playing** — running / spinning, triggered by play
- **sleeping** — zZz loop, triggered when happiness < 20
- **sad** — drooping loop, triggered when hunger < 20
- **dancing** — short dance loop, triggered when track changes

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

### 6.5 Messages

Either user can send a message that appears as a pixel art speech bubble above their own pet. Only one message exists at a time per user — sending a new message replaces the previous one. Messages are free text, capped at 48 characters to fit the bubble.

| | |
|---|---|
| **Input** | Free text, 48 character cap |
| **Display** | Pixel art speech bubble above sender's pet |
| **Persistence** | Single message per user — new message replaces old immediately |
| **Sync** | Real-time via Supabase Realtime — appears on partner's screen within ~200ms |
| **Fade** | Bubble fades out after 60 seconds if no new message is sent |
| **Font** | Pixel bitmap font (e.g. Press Start 2P or similar CC0 font) |

### 6.6 Now playing

The app automatically detects whatever is currently playing on each user's machine using the macOS MediaRemote private framework — the same system used by Boring Notch, NowPlaying CLI, and the macOS lock screen media controls. No account connection or OAuth required. Works with Spotify, Apple Music, YouTube, or any app that registers with the system audio session.

A small Swift helper binary is compiled and shipped with the app. Electron spawns it as a child process on launch and reads track info from stdout. The helper registers a MediaRemote notification listener and emits JSON whenever the now-playing info changes.

| | |
|---|---|
| **Detection method** | macOS MediaRemote framework (private API, safe for direct .dmg distribution) |
| **Helper** | Compiled Swift binary bundled with the Electron app, spawned as child process |
| **Works with** | Any app registered with the system audio session — Spotify, Apple Music, browser, etc. |
| **Data** | Track title + artist name, playing/paused state |
| **Update trigger** | Event-driven via MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler — no polling |
| **Display** | Small pixel art bubble above the pet: music note icon + track name + artist (truncated to 24 chars) |
| **Sync** | Track info written to pets table on change, broadcast via Realtime to partner's screen |
| **No playback** | Bubble hidden when nothing is playing or machine is paused |
| **Pet reaction** | Pet does a small dance frame when track changes (single cycle, returns to idle) |
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

All state is stored in Postgres. Both Electron clients subscribe to a Supabase Realtime channel keyed on their pair ID. Any mutation to the pets table (feed, play, message, now-playing update, background change) broadcasts to both subscribers immediately.

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
| **Sign out** | Clears session. Pet remains in Postgres, stats continue decaying. |
| **Delete pair** | Destructive. Removes the pair permanently. Requires confirmation. |

---

## 12. Build order

Recommended implementation sequence for a vibe-coded build with heavy Claude Code usage:

- **Day 1** — Electron app shell. Frameless transparent window. Notch positioning. Static pixel art panel renders correctly beneath notch.
- **Day 2** — Supabase schema, Auth magic link, invite/pairing flow, basic settings panel.
- **Day 3** — Pet canvas rendering, spritesheet animation state machine, background scenes, Realtime subscriptions wired up.
- **Day 4** — Feed/play interactions, message bubbles, speech bubble pixel art UI, free text input.
- **Day 5** — Swift MediaRemote helper binary, now-playing bubble UI, Realtime sync of track data, pet dance reaction on track change.
- **Buffer** — Pet decay cron, local notifications, polish, edge cases, .dmg packaging.

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

*notchpets — PRD v1.0 — March 2026*