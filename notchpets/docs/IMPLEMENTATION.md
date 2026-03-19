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

## Stage 3 — Supabase backend & auth
*Schema, auth, invite-based pairing, and pet data migration to the cloud*

### Goal

Supabase schema is fully migrated. Magic link auth works. A user can generate an invite code and a second user can enter it to form a pair. Session is stored in the macOS Keychain and persists across restarts. PetStore and the setup wizard are wired to Supabase so pet data syncs between paired users via Realtime.

### Files created this stage

```
supabase/
  migrations/
    001_schema.sql            # All tables: pairs, invites, pets
  functions/
    pet-decay/index.ts        # Cron: hunger/happiness decay
    invite-cleanup/index.ts   # Cron: expired invite deletion
notchpets/
  Data/
    SupabaseManager.swift     # Singleton SupabaseClient, reads Config.plist for URL + key
    PetRepository.swift       # Supabase queries: fetch pets, insert pet
    PetStore.swift            # Updated: adds partnerPet, Realtime subscription, replaces UserDefaults
  Storage/
    KeychainService.swift     # Save/load/delete session token from Keychain
  Auth/
    AuthManager.swift         # @MainActor ObservableObject: session state, sign-in, sign-out
    AuthGate.swift            # SwiftUI view: routes to LoginView, PairView, or PanelView
    LoginView.swift           # Email input + send magic link
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

### Acceptance criteria

- [ ] `supabase db push` runs without errors
- [ ] Magic link email is sent and clicking it opens the app and establishes a session
- [ ] Session token is saved to Keychain and survives app restart
- [ ] User A can generate a 6-character invite code displayed in large pixel art text
- [ ] User B can enter the code and a pairs row is created linking both users
- [ ] `pair_id` is stored in Keychain / UserDefaults on both machines after pairing
- [ ] Expired invites (>24h) are not accepted
- [ ] pet-decay Edge Function deploys and decrements hunger/happiness on schedule
- [ ] All tables have RLS enabled
- [ ] Setup wizard writes a pets row to Supabase (replaces UserDefaults persistence)
- [ ] Both pets render in the panel with correct backgrounds (own + partner)
- [ ] Partner pet updates arrive via Realtime

### Claude Code prompt

```
Build Stage 3 of notchpets: Supabase backend, auth, pairing, and pet data sync.

Stages 1 and 2 are complete. SpriteKit pet rendering works with local data (UserDefaults).
PetStore, Models, PetSlotView, and SetupWizard exist. Xcode project has supabase-swift
package added. Supabase project is initialised (supabase/ directory exists).
SUPABASE_URL and SUPABASE_ANON_KEY are available via Config.plist bundled in the app.

Create supabase/migrations/001_schema.sql with:
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

Create notchpets/Data/SupabaseManager.swift:
- Singleton actor SupabaseManager
- Reads SUPABASE_URL and SUPABASE_ANON_KEY from Config.plist in the app bundle
- Exposes `let client: SupabaseClient`

Create notchpets/Data/PetRepository.swift:
- Actor PetRepository
- func fetchPets(pairId: String) async throws -> [Pet]
  SELECT * FROM pets WHERE pair_id = pairId
- func insertPet(_ pet: PetInsert) async throws — inserts a new pet row

Update notchpets/Data/Models.swift:
- Add Codable structs for Pair and Invite (matching schema)
- Add snake_case CodingKeys where needed
- Add remaining Pet fields: pair_id, owner_id, last_fed, last_played, current_message,
  message_sent_at, current_track_name, current_track_artist, updated_at

Update notchpets/Data/PetStore.swift:
- Replace UserDefaults persistence with Supabase via PetRepository
- Add @Published var partnerPet: Pet?
- Add @Published var myTrigger: AnimationState? and @Published var partnerTrigger: AnimationState?
- func load(pairId: String, myUserId: String) async — fetches both pets via PetRepository
- func subscribeRealtime(pairId: String) async:
  - Subscribes to channel "pair:{pairId}" via SupabaseManager.client.realtimeV2
  - On UPDATE to pets table: update myPet or partnerPet based on owner_id
  - Infer animation trigger from delta: hunger decreased -> .eating, happiness decreased -> .playing,
    track_name changed -> .dancing
  - Set myTrigger / partnerTrigger, clear after 1 second
- func unsubscribe() async

Create notchpets/Storage/KeychainService.swift:
- Static functions: save(token: String, forKey: String), load(forKey: String) -> String?, delete(forKey: String)
- Uses Security framework: SecItemAdd, SecItemCopyMatching, SecItemDelete
- Keys used: "notchpets.session", "notchpets.pairId", "notchpets.userId"

Create notchpets/Auth/AuthManager.swift:
- @MainActor final class AuthManager: ObservableObject
- @Published var session: Session? — loaded from Keychain on init via supabase.auth.session
- @Published var pairId: String? — loaded from Keychain
- func signInWithEmail(_ email: String) async throws — calls supabase.auth.signInWithOTP(email:)
- func signOut() async — calls supabase.auth.signOut(), clears Keychain
- func handleDeepLink(_ url: URL) async — processes magic link callback via supabase.auth.session(from:)
- Saves session token to Keychain on session change using onAuthStateChange

Create notchpets/Auth/AuthGate.swift:
- SwiftUI View that observes AuthManager
- If no session: show LoginView
- If session but no pairId: show PairView
- Otherwise: show PanelView

Create notchpets/Auth/LoginView.swift:
- Email TextField + "Send magic link" Button
- Calls authManager.signInWithEmail on button tap
- Shows confirmation text after send
- Full pixel art styling: dark background (#1a1a2e), pixel border, system monospaced font

Create notchpets/Auth/PairView.swift:
- TabView or segmented control: "Generate code" / "Enter code"
- Generate tab:
  - On appear, call generateInvite(): inserts into invites table with random 6-char code
    (characters: A-Z, 2-9), expires_at = now() + 24 hours. Displays code in large text.
- Enter tab:
  - TextField for 6-char code. On submit:
    1. Fetch invite WHERE code = input AND accepted = false AND expires_at > now()
    2. INSERT into pairs (user_a = invite.creator_id, user_b = currentUserId)
    3. UPDATE invites SET accepted = true WHERE id = invite.id
    4. Save pair_id to Keychain via KeychainService
    5. Set authManager.pairId to trigger AuthGate routing

Update notchpets/Setup/SetupWizard.swift:
- On complete: call PetRepository.insertPet with pairId, ownerId, name, species, background,
  hunger 100, happiness 100. Save petId to UserDefaults. Navigate to main panel.

Update notchpets/Views/PanelView.swift:
- Render two PetSlotViews: myPet and partnerPet with trigger states from PetStore

Update AppDelegate.swift:
- Add @StateObject var authManager = AuthManager() to the app
- Handle deep link URL via application(_:open:) -> call authManager.handleDeepLink(_:)
- Register URL scheme in Info.plist: notchpets://

Use Swift 5.9, async/await throughout. Handle loading and error states in all async calls.
```

---

## Stage 4 — Interactions & messaging
*Feed, play, speech bubbles, and real-time sync*

### Goal

Either user can tap feed or play on either pet. Actions update Supabase, trigger animations on both screens in real time, and update hunger/happiness values. Users can type a message that appears as a pixel art speech bubble above their pet on both screens.

### Files created this stage

```
notchpets/
  Interactions/
    InteractionService.swift  # Feed/play Supabase mutations with optimistic updates
    PetControlsView.swift     # Feed + play buttons + hunger/happiness bars per pet slot
  Messaging/
    MessageBubble.swift       # Pixel art speech bubble overlay
    MessageInput.swift        # Text input + send
    MessageService.swift      # Send message, bubble visibility timer
```

### Interaction logic

| | |
|---|---|
| **Feed** | `UPDATE pets SET hunger = LEAST(100, hunger + 30), last_fed = now()`. Stat update syncs to both clients via Realtime. Animation trigger deferred to v2. |
| **Play** | `UPDATE pets SET happiness = LEAST(100, happiness + 25), last_played = now()`. Stat update syncs to both clients via Realtime. Animation trigger deferred to v2. |
| **Message send** | `UPDATE pets SET current_message = text, message_sent_at = now()` for sender's pet. Realtime broadcasts to partner. |
| **Message display** | Bubble renders above the pet. Fades out after 60 seconds via a client-side timer. New message resets the timer. |
| **Optimistic UI** | Apply stat changes to PetStore locally immediately, then write to Supabase. Roll back on error. |
| **Throw ball** | Deferred to v2 — requires spritesheet animations. |

### Acceptance criteria

- [ ] Feed button on either pet increments hunger and triggers eating animation on both screens
- [ ] Play button on either pet increments happiness and triggers playing animation on both screens
- [ ] Hunger and happiness values update visibly after interaction
- [ ] Animation triggers arrive on the partner's screen within 200ms
- [ ] Typing a message and sending renders a speech bubble above the sender's pet
- [ ] The speech bubble appears on the partner's screen within 200ms
- [ ] Sending a new message replaces the previous bubble immediately
- [ ] Speech bubble fades out after 60 seconds with no new message
- [ ] Optimistic updates are applied immediately, rolled back cleanly on error

### Claude Code prompt

```
Build Stage 4 of notchpets: interactions (feed/play) and messaging.

Stages 1–3 are complete. PetStore has myPet, partnerPet, myTrigger, partnerTrigger.
Realtime subscription is live in PetStore. SupabaseManager.client is available.

Create notchpets/Interactions/InteractionService.swift:
- Actor InteractionService
- func feed(petId: UUID, currentHunger: Int) async throws:
  - Optimistically update PetStore.myPet or partnerPet hunger += 30 (capped 100)
  - UPDATE pets SET hunger = LEAST(100, hunger + 30), last_fed = now() WHERE id = petId
  - On error: roll back local change
- func play(petId: UUID, currentHappiness: Int) async throws:
  - Same pattern for happiness += 25
  - On error: roll back

Create notchpets/Interactions/PetControlsView.swift:
- SwiftUI View, props: pet: Pet, isMine: Bool
- Two pixel art icon buttons: 🦴 feed and ⚽ play (use text emoji as placeholder; swap for Image later)
- Each button is 28x28, disabled while an optimistic update is in flight
- Below buttons: two PixelProgressBar views for hunger and happiness (0–100)
- PixelProgressBar: 60px wide, 6px tall, filled with colour blocks — no rounded corners

Create notchpets/Messaging/MessageService.swift:
- @MainActor final class MessageService: ObservableObject
- @Published var myBubbleVisible: Bool and @Published var partnerBubbleVisible: Bool
- Observes PetStore — when message_sent_at changes, restart a 60-second countdown Timer
- func sendMessage(_ text: String, petId: UUID) async throws:
  - UPDATE pets SET current_message = text, message_sent_at = now() WHERE id = petId

Create notchpets/Messaging/MessageBubble.swift:
- SwiftUI View, props: message: String?, visible: Bool
- Pixel art speech bubble: Rectangle with a small triangle pointer at the bottom
- System monospaced font 8pt, white text on #1a1a2e background
- Max width 160px, text truncated at 48 chars
- .opacity(visible ? 1 : 0).animation(.easeOut(duration: 0.4), value: visible)
- Positioned via .overlay(alignment: .top) above the pet slot

Create notchpets/Messaging/MessageInput.swift:
- SwiftUI View, shown only for the user's own pet slot (isMine == true)
- Small chat icon (💬) button below the pet; tap toggles a TextField overlay
- TextField: max 48 chars, pixel art style, submit on Return or send button
- On send: calls messageService.sendMessage, dismisses keyboard, hides input

Update notchpets/Views/PanelView.swift:
- Compose MessageBubble above each PetSlotView
- Compose PetControlsView below each PetSlotView
- Show MessageInput only for myPet slot

Swift 5.9, @MainActor where needed. No additional packages.
```

---

## Stage 5 — Now playing detection
*MediaRemote native integration + music bubble UI*

### Goal

The app reads the system now-playing info directly via the macOS MediaRemote private framework — no helper binary or child process required. Track data is written to Supabase and broadcast via Realtime so the music bubble appears above the correct pet on both screens. The pet dances briefly when the track changes.

### Files created this stage

```
notchpets/
  NowPlaying/
    NowPlayingService.swift  # MediaRemote @_silgen_name declarations + change handler
    MusicBubble.swift        # Small pixel art now-playing bubble
```

### MediaRemote integration details

| | |
|---|---|
| **Framework** | MediaRemote — private, declared via `@_silgen_name` in Swift |
| **Trigger** | `MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler` — event-driven, no polling |
| **Query** | `MRMediaRemoteGetNowPlayingInfo` — called inside the change handler |
| **Keys** | `kMRMediaRemoteNowPlayingInfoTitle`, `kMRMediaRemoteNowPlayingInfoArtist`, `kMRMediaRemoteNowPlayingInfoPlaybackRate` |
| **Output** | Publishes `(title: String, artist: String, playing: Bool)` via Combine |
| **On nothing playing** | Publishes empty title + artist, playing = false |

### Acceptance criteria

- [ ] App receives track change events when music starts, stops, or changes
- [ ] Track name and artist appear in the music bubble above the correct pet
- [ ] Music bubble is hidden when nothing is playing
- [ ] Partner's screen shows the same track bubble within 200ms
- [ ] Pet dancing animation on track change deferred to v2
- [ ] Works with Spotify, Apple Music, and browser-based audio
- [ ] No polling — CPU usage is negligible when music is not changing

### Claude Code prompt

```
Build Stage 5 of notchpets: native MediaRemote now-playing integration.

Stages 1–4 are complete. PetStore Realtime subscription is live. pets table has
current_track_name and current_track_artist columns. SupabaseManager.client is available.

Create notchpets/NowPlaying/NowPlayingService.swift:
- Use @_silgen_name to declare the following C functions from MediaRemote:
  @_silgen_name("MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler")
  func MRMediaRemoteRegisterNowPlayingInfoDidChangeHandler(_ queue: DispatchQueue, _ handler: @escaping () -> Void)

  @_silgen_name("MRMediaRemoteGetNowPlayingInfo")
  func MRMediaRemoteGetNowPlayingInfo(_ queue: DispatchQueue, _ handler: @escaping ([String: Any]?) -> Void)

- Constants (let, not @_silgen_name — they are string keys):
  let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
  let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
  let kMRMediaRemoteNowPlayingInfoPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"

- @MainActor final class NowPlayingService: ObservableObject
- @Published var currentTrack: TrackInfo? — struct TrackInfo: title, artist (both String)
- func start(pairId: String, userId: String):
  - Register the change handler on DispatchQueue.main
  - Inside handler: call MRMediaRemoteGetNowPlayingInfo on DispatchQueue.main
  - Extract title, artist, playbackRate from the info dict
  - If playbackRate > 0 and title is non-empty: set currentTrack = TrackInfo(title:artist:)
    and write to Supabase: UPDATE pets SET current_track_name = title,
    current_track_artist = artist, updated_at = now()
    WHERE owner_id = userId AND pair_id = pairId
  - Debounce: only write to Supabase if title changed since last write
  - If nothing playing: set currentTrack = nil, clear track columns in Supabase

The Realtime UPDATE handler in PetStore already fires on track changes — add logic there:
- If current_track_name changed in the incoming payload, set myTrigger or partnerTrigger to .dancing

Create notchpets/NowPlaying/MusicBubble.swift:
- SwiftUI View, props: track: TrackInfo?
- Small pixel art bubble: music note "♪" + " title · artist" (truncated to 24 chars total)
- System monospaced font 7pt, white on dark background
- .opacity(track != nil ? 1 : 0).animation(.easeOut(duration: 0.3), value: track != nil)
- Positioned above MessageBubble via stacked .overlay in PanelView

Update notchpets/Views/PanelView.swift:
- Inject NowPlayingService as @EnvironmentObject
- Overlay MusicBubble above each pet's MessageBubble
- My pet shows NowPlayingService.currentTrack; partner's pet shows from petStore.partnerPet track fields

Call nowPlayingService.start(pairId:userId:) in AppDelegate after session and pairId are confirmed.

Swift 5.9. No additional packages. No child process — MediaRemote is called in-process.
```

---

## Stage 6 — Polish, notifications & packaging
*Final UX, alerts, Sparkle updates, and .dmg build*

### Goal

Local notifications alert users when a pet is hungry or sad. The settings panel allows background and name changes. SpriteKit scenes pause when the panel is collapsed. The app packages as a signed .dmg with Sparkle auto-update support.

### Files created this stage

```
notchpets/
  Notifications/
    NotificationService.swift  # UNUserNotificationCenter wrapper
    PetMonitor.swift           # Polls pet stats, triggers notifications
  Settings/
    SettingsView.swift         # Gear icon overlay: name, background, sign out
    SettingsService.swift      # Update pet name / background in Supabase
```

### Polish checklist

| | |
|---|---|
| **SpriteKit pause** | Set `petScene.isPaused = true` when panel collapses, `false` on expand. Reduces CPU/battery to near zero when hidden. |
| **Notification: hungry** | Local macOS notification when own or partner's pet hunger drops below 20. Fire once per threshold crossing. |
| **Notification: sad** | Same pattern for happiness < 20. |
| **Settings panel** | Gear icon in top-right of expanded panel. Opens overlay with: change pet name, change background, sign out. |
| **Name/background sync** | Changes write to Supabase pets table. Realtime broadcasts update to partner's panel immediately. |
| **Offline indicator** | If Realtime connection drops, show a small pixel art disconnected icon. Auto-reconnects via supabase-swift channel reconnect. |
| **App icon** | Pixel art icon in Assets.xcassets — AppIcon image set with all required sizes. |
| **Sparkle** | Add SUFeedURL to Info.plist pointing to an appcast XML hosted wherever you distribute the .dmg. |
| **.dmg packaging** | Xcode Archive → Export with Developer ID → use `create-dmg` to wrap into a distributable .dmg. |

### Acceptance criteria

- [ ] CPU usage drops to <1% when panel is collapsed (verify in Activity Monitor)
- [ ] Local notification fires when pet hunger crosses below 20
- [ ] Local notification fires when pet happiness crosses below 20
- [ ] Notifications do not repeat until stat recovers above 20 then drops again
- [ ] Notification permission is requested on first launch
- [ ] Settings panel opens and closes cleanly
- [ ] Changing pet name updates on both screens within 200ms
- [ ] Changing background updates on both screens within 200ms
- [ ] Sign out clears Keychain session and returns to login screen
- [ ] Xcode Archive produces a valid signed app that installs and runs on macOS
- [ ] Sparkle checks for updates on launch

### Claude Code prompt

```
Build Stage 6 of notchpets: notifications, settings panel, SpriteKit pause, and packaging prep.

Stages 1–5 are complete and working. App renders, syncs, plays animations,
and detects now-playing. This stage is polish and packaging only.

Create notchpets/Notifications/NotificationService.swift:
- @MainActor final class NotificationService
- func requestPermission() async — calls UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
- func send(title: String, body: String) — creates UNMutableNotificationContent, fires immediately
  (UNNotificationRequest with nil trigger)

Create notchpets/Notifications/PetMonitor.swift:
- @MainActor final class PetMonitor
- Observes PetStore.myPet and PetStore.partnerPet via Combine sink
- Tracks last-notified state to avoid repeat notifications (Bool flags: myHungryNotified, etc.)
- On hunger < 20: call NotificationService.send if not already notified
- On hunger >= 30: reset the flag
- Same pattern for happiness < 20

Create notchpets/Settings/SettingsService.swift:
- Actor SettingsService
- func updateName(petId: UUID, name: String) async throws:
  UPDATE pets SET name = name WHERE id = petId
- func updateBackground(petId: UUID, background: String) async throws:
  UPDATE pets SET background = background WHERE id = petId

Create notchpets/Settings/SettingsView.swift:
- SwiftUI View, shown as overlay when gear icon is tapped
- Three sections:
  1. Pet name TextField (pre-filled, 12 char max) + Save button
  2. BackgroundPicker (reuse Stage 3 component) with current background highlighted
  3. Sign out Button — calls authManager.signOut(), clears Keychain, routes back to LoginView
- Pixel art styling: dark background, pixel border, system monospaced font

Update notchpets/Window/NotchWindowController.swift:
- On collapse: set petStore scenes to isPaused = true via a published flag
- On expand: set isPaused = false

Update notchpets/Views/PanelView.swift:
- Add gear icon (⚙) in top-right corner of the pet area, visible when expanded
- Tapping gear shows SettingsView as a .sheet or ZStack overlay

Update notchpets/App/AppDelegate.swift:
- Call notificationService.requestPermission() on first launch (guard with UserDefaults flag)
- Initialise PetMonitor after PetStore loads

For packaging:
- Ensure LSUIElement = YES in Info.plist (hides Dock icon)
- Add SUFeedURL key to Info.plist for Sparkle appcast URL
- Add Hardened Runtime capability in Xcode signing settings (required for notarization)
- In Xcode: Product → Archive → Distribute App → Developer ID → export .app
- Use create-dmg (brew install create-dmg) to wrap:
  create-dmg --volname "notchpets" --app-drop-link 600 185 notchpets.dmg notchpets.app

Swift 5.9 throughout. After this stage the app is fully functional and distributable.
```

---

## Stage 7 — SpriteKit animations (v2)
*Replace static images with animated spritesheets*

### Goal

Replace the static `Image` pet rendering with SpriteKit. Wire animation triggers to feed, play, now-playing, and ball-catch events. All core real-time features must be stable before starting this stage.

### Files created this stage

```
notchpets/
  Pet/
    AnimationState.swift     # AnimationState enum (idle, happy, eating, playing, sleeping, sad, dancing, run, jump, catch, land)
    SpriteManifest.swift     # Frame definitions per species and animation state
    PetScene.swift           # SKScene: draws background + pet sprite, runs animation
    PetSpriteNode.swift      # SKSpriteNode subclass: loads atlas, manages state transitions
  Views/
    PetSlotView.swift        # Updated: SpriteView wrapping PetScene (replaces static Image)
  Assets.xcassets/           # Replace static species PNGs with .spriteatlas folders
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
| **run** | Legs cycling. Plays on loop while pet moves horizontally across panel during ball-catch sequence. Driven by SpriteKit `SKAction.moveBy` in parallel. |
| **jump** | Rise → peak → fall arc. Plays once during ball approach. Non-looping. |
| **catch** | Reach/grab moment. Plays once on successful catch. Non-looping. |
| **land** | Impact squash on landing. Plays once then returns to idle. Non-looping. |

Full ball-catch sequence: `idle → run (looping while moving) → jump → catch → land → idle`. The ball is a separate `SKSpriteNode` with its own spin animation travelling across the panel.

### Asset sourcing note

Each species needs a single spritesheet PNG (11 rows × 6 frames, 32×32px per frame, transparent background) added to `Assets.xcassets` as a `.spriteatlas`. Source from itch.io or generate with the spritesheet prompt. All 8 background images remain as static Image Sets.

### Acceptance criteria

- [ ] All 6 species render via SpriteKit with idle animation playing
- [ ] Feed triggers eating animation on both screens via Realtime
- [ ] Play triggers playing animation on both screens via Realtime
- [ ] Track change triggers dancing animation on both screens
- [ ] Sad state auto-triggers when hunger < 20
- [ ] Sleeping state auto-triggers when happiness < 20
- [ ] Ball-catch sequence plays end-to-end on throw
- [ ] SpriteKit scenes pause when panel is collapsed

---

## Notes for Claude Code sessions

- Always start a new session by telling Claude Code which stage you are on and pasting the full stage prompt.
- If Claude Code produces code that compiles but fails an acceptance criterion, describe the failure precisely — do not just say "it doesn't work".
- MediaRemote (Stage 5) can be tested standalone before integration: create a small Swift command-line tool with just the `@_silgen_name` declarations and `dispatchMain()`, run it in Terminal, and confirm JSON emits when you change tracks.
- Supabase Realtime in Swift can have type inference issues with the generic payload — if you hit compile errors on the change handler, use explicit `[String: AnyJSON]` typing and revisit.
- SpriteKit texture atlases must be added as `.spriteatlas` folders in Assets.xcassets, not individual image sets — this affects how `SKTextureAtlas(named:)` loads them.
- Pixel art asset quality matters more than code quality for the feel of the app. Spend time sourcing good spritesheets before starting Stage 3.
- Do not skip acceptance criteria. Each stage's criteria exist because later stages will silently break if earlier ones are unstable.
- For the notch positioning in Stage 1: if `auxiliaryTopLeftArea` returns `NSZeroRect` (non-notch Mac during dev), fall back to a hardcoded width of ~200px so the panel still renders usably.

---

*notchpets — Implementation Plan v2.0 — March 2026*
