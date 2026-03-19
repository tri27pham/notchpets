# CLAUDE.md

notchpets is a native macOS notch companion app for two paired users with real-time shared pixel art pets. See @docs/PRD.md for requirements and @docs/IMPLEMENTATION.md for the staged build plan.

**Stack:** SwiftUI + AppKit, SpriteKit, supabase-swift, MediaRemote (private framework), Keychain, Sparkle. Minimum macOS 13. No Electron, no web stack.

## Commands

```bash
xcodebuild -scheme notchpets -configuration Debug build
xcodebuild -scheme notchpets -configuration Debug test
npx supabase db push
npx supabase functions deploy
```

## Architecture decisions

- **Single process — no IPC.** All components communicate via async/await, Combine, and `@Published`. Do not introduce message passing or helper binaries.
- **`@MainActor`** on all `ObservableObject` service classes. **Actors** for all Supabase mutation services (`PetRepository`, `InteractionService`, `SettingsService`).
- **No Dock icon.** `LSUIElement = YES` in Info.plist — do not add an `NSStatusItem` or show a regular app window.

## Non-obvious conventions

- **Sprite atlases:** Must be `.spriteatlas` folders inside `Assets.xcassets` — not individual image sets. `SKTextureAtlas(named:)` only finds `.spriteatlas` format.
- **MediaRemote keys** (`kMRMediaRemoteNowPlayingInfoTitle` etc.) are plain `let` string constants — not `@_silgen_name`. Only the C functions use `@_silgen_name`.
- **Notch dimensions fallback:** If `auxiliaryTopLeftArea` returns `NSZeroRect` (non-notch Mac or pre-macOS 12), fall back to 200px notch width.
- **Credentials:** `SUPABASE_URL` and `SUPABASE_ANON_KEY` live in `Config.plist` (gitignored). Never hardcode them.
- **SpriteKit pause:** Always set `petScene.isPaused = !isExpanded` when the panel collapses — this is required for acceptable CPU usage.
- **Pixel art:** `.interpolation(.none)` on all `Image` and `SpriteView`. No corner radius, shadow, or blur in the pet panel.
- **All Supabase tables must have RLS enabled.**
