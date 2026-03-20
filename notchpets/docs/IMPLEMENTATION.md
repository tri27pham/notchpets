# notchpets — Implementation Plan
**For use with Claude Code — v2.0 — March 2026**

---

## How to use this document

This plan is structured as six sequential stages. Each stage has a clear goal, a file structure, explicit acceptance criteria, and a ready-to-paste Claude Code prompt. Complete each stage fully before moving to the next — later stages depend on earlier ones being stable.

At the start of each Claude Code session, paste the stage prompt verbatim. Claude Code will scaffold the required files. Review the acceptance criteria before calling a stage done. Do not move forward until every checkbox passes.

**Stack:** SwiftUI + AppKit (NSPanel), supabase-swift SDK (Postgres, Auth, Realtime), MediaRemote private framework for now-playing, Keychain for session storage, Sparkle for auto-updates.

**Note on animations:** v1 uses static `Image` views for pets — no SpriteKit. Spritesheet animation is deferred to Stage 7 (v2), after core real-time features (messaging, now-playing) are working.

---

## Pre-stage: project initialisation

Run these steps once before starting Stage 1. Claude Code does not need to do this — run them manually.

1. Open Xcode → New Project → macOS → App
2. Product name: `notchpets`, Bundle ID: `com.notchpets.app`, Interface: SwiftUI, Language: Swift
3. Add Swift Package dependencies via File → Add Package Dependencies:
   - `https://github.com/supabase/supabase-swift.git` (from: 2.0.0)
   - `https://github.com/sparkle-project/Sparkle` (from: 2.0.0)
4. In the target's Info.plist, add:
   - `LSUIElement = YES` — hides the Dock icon (menu-bar-style app)
   - `NSUserNotificationsUsageDescription` — required for local notifications
5. Set Deployment Target to macOS 13.0

```bash
# Supabase project
npx supabase init
npx supabase login
# Create a new project at supabase.com, copy project URL and anon key
```

Create a `Config.xcconfig` file (gitignored) at the project root:

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key
```

Reference it in the Xcode scheme's build settings or read it via a `Config.swift` helper that loads from a bundled plist.

---

## Stage 1 — Notch window & static panel
*Get a transparent panel surrounding the MacBook notch*

### Goal

A borderless transparent NSPanel surrounds the physical MacBook notch. The notch cap (transparent, exactly the width and height of the hardware notch) sits at the top. Below it, the panel collapses to nothing and expands to the full 160px pet area on hover. No real data yet — static placeholder pets and backgrounds only.

### Files created this stage

```
notchpets/
  App/
    NotchpetsApp.swift       # @main, creates AppDelegate, no dock icon
    AppDelegate.swift        # NSApplicationDelegate, creates NotchWindowController
  Window/
    NotchPanel.swift         # NSPanel subclass: borderless, transparent, correct level
    NotchWindowController.swift  # Manages panel, NSTrackingArea, expand/collapse
    NotchMetrics.swift       # Reads notch dimensions from NSScreen APIs
  Views/
    PanelView.swift          # Root SwiftUI view: notch cap + collapsible pet area
    PetSlotView.swift        # 180x150 placeholder pet slot
  Shared/
    Constants.swift          # Panel dimensions, animation timings
```

### Key implementation details

- **NSPanel config:** `styleMask: [.borderless, .nonactivatingPanel]`, `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false`, `isMovable = false`
- **Window level:** `level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)` — above the menu bar
- **Collection behaviour:** `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`
- **Notch metrics:** Read from `NSScreen.screens[0].safeAreaInsets.top` (height) and `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` (to compute width)
- **Positioning:** `window.setFrameOrigin(NSPoint(x: screen.frame.midX - notchWidth / 2, y: screen.frame.maxY - notchHeight))`
- **Hover:** `NSTrackingArea` on the panel's content view with `.mouseEnteredAndExited` and `.activeAlways` — expand on `mouseEntered`, collapse on `mouseExited` with a 300ms debounce
- **Panel shape:** On expand, resize the panel frame downward: `window.setFrame(expandedRect, display: true, animate: false)` — SwiftUI handles the content animation
- **Mouse passthrough when collapsed:** `panel.ignoresMouseEvents = true` in collapsed state; `false` when expanded

### Acceptance criteria

- [ ] App launches with no Dock icon
- [ ] The panel appears at the top of the screen, cap aligned to the physical notch
- [ ] Notch cap is transparent — the hardware black shows through
- [ ] Hovering the notch area expands the panel smoothly downward to 160px
- [ ] Moving the mouse off the panel collapses it after ~300ms
- [ ] Two placeholder pet slots are visible side by side when expanded
- [ ] Panel sits above all other windows including full-screen apps
- [ ] Panel persists across all macOS Spaces
- [ ] Clicking elsewhere does not steal focus from the active app
- [ ] Panel has no title bar, shadow, or visible chrome

### Claude Code prompt

```
Build Stage 1 of the notchpets macOS app: the notch window and static panel.

Stack: SwiftUI + AppKit. Xcode project already created with supabase-swift and Sparkle
packages added. Target is macOS 13. Do not modify project settings — only create Swift files.

Create notchpets/Shared/Constants.swift:
- PANEL_EXPANDED: CGFloat = 160
- PET_SLOT_WIDTH: CGFloat = 180
- PET_SLOT_HEIGHT: CGFloat = 150
- COLLAPSE_DEBOUNCE_SECONDS: Double = 0.3

Create notchpets/Window/NotchMetrics.swift:
- Struct NotchMetrics: notchHeight, notchWidth, leftAux, rightAux, hasNotch (all CGFloat / Bool)
- Static func current() -> NotchMetrics:
  - screen = NSScreen.screens[0]
  - notchHeight = screen.safeAreaInsets.top (0 if no notch)
  - If notchHeight > 0: read auxiliaryTopLeftArea and auxiliaryTopRightArea (NSRect values)
    notchWidth = screen.frame.width - leftRect.width - rightRect.width + 4
  - hasNotch = notchHeight > 0

Create notchpets/Window/NotchPanel.swift:
- Class NotchPanel: NSPanel
- init(metrics: NotchMetrics):
  - contentRect for collapsed state: notchWidth x notchHeight, positioned at
    x = screen.frame.midX - notchWidth/2, y = screen.frame.maxY - notchHeight
  - styleMask: [.borderless, .nonactivatingPanel]
  - isOpaque = false, backgroundColor = .clear, hasShadow = false, isMovable = false
  - level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)
  - collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
  - isReleasedWhenClosed = false

Create notchpets/Window/NotchWindowController.swift:
- Class NotchWindowController: NSWindowController
- Properties: metrics (NotchMetrics), isExpanded (Bool), collapseTask (Task?)
- init(): builds NotchMetrics.current(), creates NotchPanel, sets contentView to
  NSHostingView(rootView: PanelView(isExpanded: $isExpanded, metrics: metrics))
  then calls orderFrontRegardless()
- setupTracking(): adds NSTrackingArea(.mouseEnteredAndExited, .activeAlways) to contentView
- override mouseEntered: cancel collapseTask, expand()
- override mouseExited: schedule collapse after COLLAPSE_DEBOUNCE_SECONDS
- expand(): set isExpanded = true, resize panel frame to include PANEL_EXPANDED height below cap,
  panel.ignoresMouseEvents = false
- collapse(): set isExpanded = false, resize panel frame back to notch cap only,
  panel.ignoresMouseEvents = true

Create notchpets/App/AppDelegate.swift:
- Class AppDelegate: NSObject, NSApplicationDelegate
- var windowController: NotchWindowController?
- applicationDidFinishLaunching: windowController = NotchWindowController()

Create notchpets/App/NotchpetsApp.swift:
- @main struct NotchpetsApp: App
- @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
- var body: some Scene { Settings { EmptyView() } }
  (Settings scene required to suppress default window; Dock icon hidden via LSUIElement in Info.plist)

Create notchpets/Views/PetSlotView.swift:
- SwiftUI View, 180x150 fixed frame
- Background: Color(red: 0.1, green: 0.1, blue: 0.18) — dark pixel art placeholder
- Centred 32x32 white rectangle as placeholder pet sprite
- image-rendering equivalent: .interpolation(.none) on any Image

Create notchpets/Views/PanelView.swift:
- SwiftUI View with @Binding isExpanded: Bool and let metrics: NotchMetrics
- VStack spacing 0:
  - Top: transparent Rectangle() of notchWidth x notchHeight (the cap — blends with hardware notch)
  - Bottom: HStack of two PetSlotViews, height animates 0 <-> PANEL_EXPANDED
    using .animation(.easeOut(duration: 0.12), value: isExpanded)
- Background: Color.clear for the whole view
- No border, no shadow, no corner radius

Use Swift 5.9+. All frame sizes come from Constants.swift. No third-party packages in this stage.
```

---

## Stage 2 — Data model & local pet store
*Models, local persistence, and wiring the existing backgrounds into the panel — no new assets needed*

### Goal

Introduce the Pet data model and local UserDefaults persistence. The panel renders both pet slots using the two existing background images (`japan_background`, `bedroom_background`). No new assets required. No setup wizard yet — pet data is hardcoded for testing. Setup wizard and real background picker come in Stage 3.

### Files created this stage

```
notchpets/
  Data/
    Models.swift             # Pet struct + Species/Background enums (Codable)
    PetStore.swift           # @MainActor ObservableObject: myPet, loads/saves via UserDefaults
  Views/
    PetSlotView.swift        # Updated: renders background image only (no pet image yet)
```

### Acceptance criteria

- [ ] Models.swift compiles with Pet, Species, and Background types
- [ ] PetStore loads and saves a Pet to UserDefaults
- [ ] Panel renders two slots using japan_background and bedroom_background
- [ ] Both slots visible side by side when panel expands

### Claude Code prompt

```
Build Stage 2 of notchpets: Pet data model and local persistence.

Stage 1 is complete. Do not add a setup wizard or new assets yet.
Two background images already exist in Assets.xcassets:
  japan_background, bedroom_background

Create notchpets/Data/Models.swift:
- Codable struct Pet: id (UUID), name (String), species (String), background (String),
  hunger (Int, default 100), happiness (Int, default 100)
- Pet.Species enum: cat, dog, frog, panda, penguin, rabbit (String RawRepresentable)
- Pet.Background enum: bedroom, rainy_window, forest, mount_fuji, cafe, beach, library,
  snowy_field, japan (String RawRepresentable)

Create notchpets/Data/PetStore.swift:
- @MainActor final class PetStore: ObservableObject
- @Published var myPet: Pet?
- @Published var partnerPet: Pet?
- init(): load() on init, seed a default myPet (species: "penguin", background: "japan_background",
  name: "Pingu") if UserDefaults is empty so the panel is never blank
- func load() — reads myPet from UserDefaults (JSON-decoded Pet)
- func save(_ pet: Pet) — writes myPet to UserDefaults
- Stage 3 will replace local storage with Supabase and populate partnerPet via Realtime

Update notchpets/Views/PetSlotView.swift:
- SwiftUI View, props: background: String
- GeometryReader filling the slot with Image(background) .resizable() .scaledToFill() .clipped()
- Clip to RoundedRectangle cornerRadius 12

Update notchpets/Views/PanelView.swift:
- Create PetStore as @StateObject
- Render two PetSlotViews:
  left:  background from petStore.myPet?.background ?? "japan_background"
  right: background from petStore.partnerPet?.background ?? "bedroom_background"

Swift 5.9. No SpriteKit. No additional packages.
```

---

## Stage 3 — Animations for one pet (penguin)
*SpriteKit for a single species — no backend, no setup wizard*

### Goal

Replace the static penguin image with a SpriteKit animated sprite. All other species remain as static images. No Supabase, no setup wizard — the penguin spritesheet is hardcoded. This stage proves the animation pipeline works before scaling to all species.

### Files created this stage

```
notchpets/
  Pet/
    AnimationState.swift     # AnimationState enum + AnimationDef struct + penguinManifest
    PetSpriteNode.swift      # SKSpriteNode: loads penguin atlas, slices frames, runs states
    PetScene.swift           # SKScene: background image + PetSpriteNode, trigger API
  Views/
    PetSlotView.swift        # Updated: SpriteView when species == "penguin", Image otherwise
  Assets.xcassets/
    penguin.spriteatlas/     # Spritesheet PNG (192×320px, 10 rows × 6 cols, 32×32 frames)
```

### Spritesheet spec

Single PNG, 10 rows × 6 frames, 32×32px per frame, transparent background. Row order: idle (4f), happy (6f), eating (6f), playing (6f), sleeping (4f), sad (4f), dancing (6f), run (6f), jump (4f), catch (4f). Unused cells in shorter rows left transparent.

### Acceptance criteria

- [ ] Penguin renders via SpriteKit with idle animation looping
- [ ] All 11 animation states play correctly when triggered
- [ ] Non-looping states (happy, eating, etc.) return to idle on completion
- [ ] Static image fallback still renders for all other species
- [ ] No regression to Stage 2 panel layout or expand/collapse behaviour

### Claude Code prompt

```
Build Stage 3 of notchpets: SpriteKit animation for the penguin only.

Stages 1 and 2 are complete. PetStore and Models exist. The penguin spritesheet PNG
is in Assets.xcassets/penguin.spriteatlas. It is 192×320px: 10 rows × 6 cols, 32×32px
frames, transparent background.

Row order (0-indexed):
0: idle (4f), 1: happy (6f), 2: eating (6f), 3: playing (6f), 4: sleeping (4f),
5: sad (4f), 6: dancing (6f), 7: run (6f), 8: jump (4f), 9: catch (4f)

Create notchpets/Pet/AnimationState.swift:
- Enum AnimationState: String, CaseIterable
  cases: idle, happy, eating, playing, sleeping, sad, dancing, run, jump, catch_ball
- Struct AnimationDef: row (Int, 0-indexed), frameCount (Int), fps (Int), loops (Bool)
- Let penguinManifest: [AnimationState: AnimationDef] hardcoded per above row order

Create notchpets/Pet/PetSpriteNode.swift:
- Class PetSpriteNode: SKSpriteNode
- init(): loads SKTextureAtlas(named: "penguin"), slices frames using SKTexture(rect:in:)
  frameW = 1/6, frameH = 1/10, UV origin bottom-left (rowFromBottom = 9 - row)
- Set filteringMode = .nearest on all textures
- func setState(_ state: AnimationState, onComplete: (() -> Void)? = nil):
  builds SKAction.animate(with:timePerFrame:); loops: repeatForever; one-shot: run then onComplete

Create notchpets/Pet/PetScene.swift:
- Class PetScene: SKScene, init(size:background:)
- didMove(to:): fills scene with Image(background) node, adds PetSpriteNode centred, scale 3, starts idle
- func trigger(_ state: AnimationState): one-shot states return to idle via onComplete;
  looping states (sleeping, sad) set directly

Update notchpets/Views/PetSlotView.swift:
- Props: background: String, species: String
- If species == "penguin": show SpriteView(scene: PetScene(size:background:)) fixed at slot size
- Otherwise: show existing ZStack Image layout (background + static species image)
- Hold PetScene in a @StateObject wrapper so it is not recreated on re-render

Swift 5.9. SpriteKit only, no additional packages.
```

---

## Stage 4 — All species, all backgrounds & setup wizard
*Complete the asset set and add species/background selection*

### Goal

All 6 species have spritesheet animations. All 8 background scenes are added. A setup wizard lets the user choose their species, name their pet, and pick a background. Data is saved to UserDefaults. The panel renders the chosen combination.

### Files created this stage

```
notchpets/
  Setup/
    SetupWizard.swift        # 3-step wizard: species picker, name, background picker
    SpeciesPicker.swift      # Grid of all 6 species (idle frame preview or static image)
    BackgroundPicker.swift   # Grid of all 8 background thumbnails
  Assets.xcassets/
    cat.spriteatlas/         # Spritesheet per remaining species
    dog.spriteatlas/
    frog.spriteatlas/
    panda.spriteatlas/
    rabbit.spriteatlas/
    + 6 remaining background Image Sets
```

### Acceptance criteria

- [ ] Setup wizard appears on first launch (no pet in UserDefaults)
- [ ] Species picker shows all 6 species
- [ ] Background picker shows all 8 backgrounds
- [ ] Completing wizard saves pet and renders it in the panel with the correct animation
- [ ] All 6 species animate correctly with the same state machine
- [ ] All 8 backgrounds render correctly behind the pet

### Claude Code prompt

```
Build Stage 4 of notchpets: all species animations, all backgrounds, and setup wizard.

Stage 3 is complete. PetSpriteNode, PetScene, AnimationState, and penguinManifest exist.
All 6 species spritesheets are in Assets.xcassets as .spriteatlas folders named:
  cat, dog, frog, panda, penguin, rabbit
All 8 backgrounds are Image Sets named:
  bedroom, rainy_window, forest, mount_fuji, cafe, beach, library, snowy_field, japan_background

Create notchpets/Pet/SpriteManifest.swift:
- Let speciesManifest: [String: [AnimationState: AnimationDef]]
- All 6 species share the same row/frame layout as penguinManifest
- Remove the hardcoded penguinManifest from AnimationState.swift and replace with speciesManifest

Update notchpets/Pet/PetSpriteNode.swift:
- init(species: String): load SKTextureAtlas(named: species) instead of hardcoded "penguin"
- Use speciesManifest[species] for frame definitions

Update notchpets/Pet/PetScene.swift:
- init(size:species:background:): pass species through to PetSpriteNode

Update notchpets/Views/PetSlotView.swift:
- Remove the species == "penguin" branch — always use SpriteView now

Create notchpets/Setup/SpeciesPicker.swift:
- SwiftUI View, @Binding selection: String?
- LazyVGrid of 6 species cards using Image(species) (static fallback) scaled to 64x64
- White border on selected

Create notchpets/Setup/BackgroundPicker.swift:
- SwiftUI View, @Binding selection: String?
- LazyVGrid of 8 background thumbnails using Image(background) scaled to 80x60
- White border on selected

Create notchpets/Setup/SetupWizard.swift:
- 3 steps: SpeciesPicker → name TextField (12 char max) → BackgroundPicker
- On complete: create Pet, call PetStore.save(_:), navigate to panel

Update notchpets/Views/PanelView.swift:
- If petStore.myPet == nil: show SetupWizard
- Otherwise: render PetSlotViews with real species and background from PetStore

Swift 5.9. No additional packages.
```

---

## Stage 5 — Local messaging
*Speech bubbles on your own screen — no backend*

### Goal

The user can type a message that appears as a speech bubble above their own pet on their own screen. No Supabase — the bubble is local state only. This proves the UI works before wiring it to real-time sync in Stage 7.

### Files created this stage

```
notchpets/
  Messaging/
    MessageBubble.swift      # Pixel art speech bubble overlay
    MessageInput.swift       # Text input + send button
    LocalMessageStore.swift  # @MainActor ObservableObject: current message + fade timer
```

### Message logic

| | |
|---|---|
| **Input** | Chat icon button below the user's own pet slot. Tap to show/hide TextField. |
| **Send** | Sets message in LocalMessageStore, starts 60-second fade timer. |
| **Display** | Bubble appears above pet immediately. Fades out after 60 seconds. Sending a new message resets the timer. |
| **Scope** | Local only — partner does not see it yet. Sync added in Stage 7. |

### Acceptance criteria

- [ ] Chat button appears below the left (own) pet slot
- [ ] Typing and sending a message shows a bubble above the pet
- [ ] Bubble fades out after 60 seconds
- [ ] Sending a new message replaces the current bubble and resets the timer
- [ ] No message bubble shown on the right (partner) slot

### Claude Code prompt

```
Build Stage 5 of notchpets: local messaging — speech bubble on own screen only.

Stages 1–4 are complete. No Supabase in this stage — message is local state only.

Create notchpets/Messaging/LocalMessageStore.swift:
- @MainActor final class LocalMessageStore: ObservableObject
- @Published var message: String? = nil
- @Published var bubbleVisible: Bool = false
- private var fadeTimer: Timer?
- func send(_ text: String):
  - Set message = text, bubbleVisible = true
  - Cancel existing timer, start new 60-second Timer
  - On timer fire: set bubbleVisible = false

Create notchpets/Messaging/MessageBubble.swift:
- SwiftUI View, props: message: String?, visible: Bool
- Rounded rectangle bubble with a small downward triangle pointer
- System monospaced font 8pt, white text on Color(hex: "#1a1a2e") background
- Max width 160px, clipped at 48 chars
- .opacity(visible ? 1 : 0).animation(.easeOut(duration: 0.4), value: visible)

Create notchpets/Messaging/MessageInput.swift:
- SwiftUI View, @ObservedObject store: LocalMessageStore
- Chat icon (💬) button; tap toggles @State var inputVisible: Bool
- When visible: TextField (max 48 chars) + send button
- On send: call store.send(_:), set inputVisible = false

Update notchpets/Views/PanelView.swift:
- Add @StateObject var messageStore = LocalMessageStore()
- Overlay MessageBubble above the left PetSlotView, bound to messageStore
- Place MessageInput below the left PetSlotView

Swift 5.9, @MainActor where needed. No additional packages.
```

---

## Stage 6 — Spotify / now-playing detection
*MediaRemote local integration — music bubble on your screen only*

### Goal

The app reads now-playing info from the macOS MediaRemote framework and shows a music bubble above the user's own pet. Local only — no Supabase. This proves MediaRemote works before wiring it to real-time sync in Stage 7.

### Files created this stage

```
notchpets/
  NowPlaying/
    NowPlayingService.swift  # MediaRemote @_silgen_name declarations + change handler
    MusicBubble.swift        # Small music info bubble
```

### MediaRemote integration details

| | |
|---|---|
| **Framework** | MediaRemote — private, declared via `@_silgen_name` in Swift |
| **Trigger** | `MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler` — event-driven, no polling |
| **Query** | `MRMediaRemoteGetNowPlayingInfo` — called inside the change handler |
| **Keys** | `kMRMediaRemoteNowPlayingInfoTitle`, `kMRMediaRemoteNowPlayingInfoArtist`, `kMRMediaRemoteNowPlayingInfoPlaybackRate` |
| **Scope** | Local only — partner does not see it yet. Sync added in Stage 7. |

### Acceptance criteria

- [ ] App receives track change events when music starts, stops, or changes
- [ ] Track name and artist appear in the music bubble above the user's own pet
- [ ] Music bubble is hidden when nothing is playing
- [ ] Works with Spotify, Apple Music, and browser audio
- [ ] No polling — CPU usage negligible when music is not changing

### Claude Code prompt

```
Build Stage 6 of notchpets: local MediaRemote now-playing detection.

Stages 1–5 are complete. No Supabase in this stage — track info is local only.

Create notchpets/NowPlaying/NowPlayingService.swift:
- @_silgen_name declarations:
  func MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler(_ queue: DispatchQueue, _ handler: @escaping () -> Void)
  func MRMediaRemoteGetNowPlayingInfo(_ queue: DispatchQueue, _ handler: @escaping ([String: Any]?) -> Void)
- String key constants:
  let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
  let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
  let kMRMediaRemoteNowPlayingInfoPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
- Struct TrackInfo: title: String, artist: String
- @MainActor final class NowPlayingService: ObservableObject
- @Published var currentTrack: TrackInfo? = nil
- func start():
  - Register change handler on DispatchQueue.main
  - In handler: call MRMediaRemoteGetNowPlayingInfo on DispatchQueue.main
  - Extract title, artist, playbackRate from info dict
  - If playbackRate > 0 and title non-empty: set currentTrack = TrackInfo(title:artist:)
  - Otherwise: set currentTrack = nil

Create notchpets/NowPlaying/MusicBubble.swift:
- SwiftUI View, props: track: TrackInfo?
- Small bubble: "♪ title · artist" truncated to 24 chars
- System monospaced font 7pt, white on dark background
- .opacity(track != nil ? 1 : 0).animation(.easeOut(duration: 0.3), value: track != nil)

Update notchpets/Views/PanelView.swift:
- Add @StateObject var nowPlayingService = NowPlayingService()
- Call nowPlayingService.start() in .onAppear
- Overlay MusicBubble above MessageBubble on the left (own) pet slot

Swift 5.9. No additional packages. No child process.
```

---

## Stage 7 — Supabase backend & real-time sync
*Auth, pairing, and live sync of pets, messages, and now-playing*

### Goal

Supabase schema is migrated. Magic link auth works. Users pair via invite code. All local state (pet data, messages, now-playing) is wired to Supabase and broadcast to the partner in real time. PetStore, LocalMessageStore, and NowPlayingService are all updated to write to and read from Supabase.

### Files created this stage

```
supabase/
  migrations/
    001_schema.sql            # pairs, invites, pets tables
  functions/
    pet-decay/index.ts        # Cron: hunger/happiness decay every 30 min
    invite-cleanup/index.ts   # Cron: expired invite deletion every hour
notchpets/
  Data/
    SupabaseManager.swift     # Singleton SupabaseClient
    PetRepository.swift       # Supabase queries: fetch, insert, update pets
  Storage/
    KeychainService.swift     # Save/load/delete tokens from Keychain
  Auth/
    AuthManager.swift         # Session state, magic link sign-in, sign-out
    AuthGate.swift            # Routes to LoginView, SetupWizard, PairView, or PanelView
    LoginView.swift           # Email + magic link send
    PairView.swift            # Generate or enter invite code
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

### What gets wired up in this stage

| | |
|---|---|
| **Pet data** | PetStore replaces UserDefaults with Supabase. partnerPet populated via Realtime. |
| **Messages** | LocalMessageStore writes `current_message` to Supabase. Partner sees it via Realtime. |
| **Now-playing** | NowPlayingService writes track info to Supabase. Partner's music bubble updates via Realtime. |
| **Feed / play** | Hunger/happiness mutations write to Supabase and sync to partner via Realtime. |

### Acceptance criteria

- [ ] Magic link email sent and clicking it establishes a session
- [ ] Session persists across app restarts via Keychain
- [ ] User A generates invite code, User B enters it — pair created
- [ ] Both pets visible in panel after pairing
- [ ] Message typed by User A appears above their pet on User B's screen within 200ms
- [ ] Now-playing track shown on partner's screen within 200ms
- [ ] Pet stats sync across both screens
- [ ] pet-decay cron deploys and decrements stats on schedule

### Claude Code prompt

```
Build Stage 7 of notchpets: Supabase backend, auth, pairing, and real-time sync.

Stages 1–6 are complete. PetStore (UserDefaults), LocalMessageStore, and NowPlayingService
all work locally. Xcode project has supabase-swift added. Supabase project is initialised.
SUPABASE_URL and SUPABASE_ANON_KEY are available via Config.plist bundled in the app.

Create supabase/migrations/001_schema.sql:
pairs (id, user_a, user_b, created_at)
invites (id, code unique, creator_id, created_at, expires_at, accepted bool default false)
pets (id, pair_id, owner_id, name, species, background, hunger int default 100,
  happiness int default 100, last_fed, last_played, current_message, message_sent_at,
  current_track_name, current_track_artist, updated_at)
Enable RLS on all tables with permissive authenticated policies.

Create supabase/functions/pet-decay/index.ts:
- Deno cron every 30 minutes
- UPDATE pets SET hunger = GREATEST(0, hunger-5), happiness = GREATEST(0, happiness-3)

Create supabase/functions/invite-cleanup/index.ts:
- Deno cron every hour
- DELETE FROM invites WHERE expires_at < now() AND accepted = false

Create notchpets/Data/SupabaseManager.swift:
- Singleton actor, reads Config.plist, exposes `let client: SupabaseClient`

Create notchpets/Data/PetRepository.swift:
- Actor PetRepository
- func fetchPets(pairId: String) async throws -> [Pet]
- func insertPet(_ pet: Pet) async throws
- func updateMessage(petId: UUID, message: String) async throws
- func updateTrack(petId: UUID, title: String, artist: String) async throws
- func updateHunger(petId: UUID, hunger: Int) async throws
- func updateHappiness(petId: UUID, happiness: Int) async throws

Create notchpets/Storage/KeychainService.swift:
- Static save/load/delete using Security framework
- Keys: "notchpets.session", "notchpets.pairId", "notchpets.userId"

Create notchpets/Auth/AuthManager.swift:
- @MainActor ObservableObject: session, pairId
- signInWithEmail, signOut, handleDeepLink

Create notchpets/Auth/AuthGate.swift:
- No session → LoginView
- Session, no pairId → PairView
- Session + pairId, no pet → SetupWizard
- Session + pairId + pet → PanelView

Create notchpets/Auth/LoginView.swift and notchpets/Auth/PairView.swift as per earlier spec.

Update notchpets/Data/PetStore.swift:
- Replace UserDefaults with Supabase via PetRepository
- Add partnerPet populated from Realtime subscription on "pair:{pairId}"
- On Realtime UPDATE: update myPet or partnerPet by owner_id

Update notchpets/Messaging/LocalMessageStore.swift → rename to MessageStore.swift:
- On send: also call PetRepository.updateMessage — Realtime delivers to partner

Update notchpets/NowPlaying/NowPlayingService.swift:
- On track change: also call PetRepository.updateTrack — Realtime delivers to partner
- Partner's track from petStore.partnerPet.current_track_name / current_track_artist

Update notchpets/Views/PanelView.swift:
- Right slot now shows partnerPet from PetStore (real data, not placeholder)
- Partner's music bubble reads from partnerPet track fields

Swift 5.9, async/await throughout. Handle loading and error states.
```

---

## Stage 8 — Polish, notifications & packaging
*Local notifications, settings panel, and .dmg build*

### Goal

Local notifications alert users when a pet is hungry or sad. The settings panel allows background and name changes. The app packages as a signed .dmg with Sparkle auto-update support.

### Files created this stage

```
notchpets/
  Notifications/
    NotificationService.swift  # UNUserNotificationCenter wrapper
    PetMonitor.swift           # Watches pet stats, fires notifications
  Settings/
    SettingsView.swift         # Gear icon overlay: name, background, sign out
    SettingsService.swift      # Update name/background in Supabase
```

### Acceptance criteria

- [ ] Local notification fires when pet hunger crosses below 20
- [ ] Local notification fires when pet happiness crosses below 20
- [ ] Notifications do not repeat until stat recovers then drops again
- [ ] Settings panel opens and closes cleanly
- [ ] Changing pet name or background syncs to partner's screen within 200ms
- [ ] Sign out clears Keychain and returns to login screen
- [ ] Xcode Archive produces a valid signed .app
- [ ] Sparkle checks for updates on launch

### Claude Code prompt

```
Build Stage 8 of notchpets: notifications, settings panel, and packaging prep.

Stages 1–7 are complete. App is fully synced via Supabase Realtime.

Create notchpets/Notifications/NotificationService.swift:
- func requestPermission() async
- func send(title: String, body: String)

Create notchpets/Notifications/PetMonitor.swift:
- Observes PetStore.myPet and partnerPet via Combine
- Fires notification on hunger < 20 or happiness < 20 (once per threshold crossing)

Create notchpets/Settings/SettingsService.swift:
- func updateName(petId: UUID, name: String) async throws
- func updateBackground(petId: UUID, background: String) async throws

Create notchpets/Settings/SettingsView.swift:
- Name TextField + Save, BackgroundPicker, Sign out button
- Writes changes via SettingsService

Update notchpets/Views/PanelView.swift:
- Gear icon (⚙) in top-right of expanded panel → shows SettingsView overlay

Update AppDelegate.swift:
- Request notification permission on first launch
- Initialise PetMonitor after PetStore loads

For packaging:
- LSUIElement = YES in Info.plist
- SUFeedURL in Info.plist for Sparkle
- Hardened Runtime capability in Xcode signing
- Product → Archive → Distribute App → Developer ID
- create-dmg --volname "notchpets" --app-drop-link 600 185 notchpets.dmg notchpets.app

Swift 5.9 throughout.
```

---

## Notes for Claude Code sessions

- Always start a new session by telling Claude Code which stage you are on and pasting the full stage prompt.
- If Claude Code produces code that compiles but fails an acceptance criterion, describe the failure precisely — do not just say "it doesn't work".
- MediaRemote (Stage 6) can be tested standalone before integration: create a small Swift command-line tool with just the `@_silgen_name` declarations and `dispatchMain()`, run it in Terminal, and confirm track info emits when you change tracks.
- Supabase Realtime in Swift can have type inference issues with the generic payload — if you hit compile errors on the change handler, use explicit `[String: AnyJSON]` typing and revisit.
- SpriteKit texture atlases must be added as `.spriteatlas` folders in Assets.xcassets, not individual image sets — this affects how `SKTextureAtlas(named:)` loads them.
- Pixel art asset quality matters more than code quality for the feel of the app. Spend time sourcing good spritesheets before starting Stage 3.
- Do not skip acceptance criteria. Each stage's criteria exist because later stages will silently break if earlier ones are unstable.
- For the notch positioning in Stage 1: if `auxiliaryTopLeftArea` returns `NSZeroRect` (non-notch Mac during dev), fall back to a hardcoded width of ~200px so the panel still renders usably.

---

*notchpets — Implementation Plan v2.1 — March 2026*
