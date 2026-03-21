import Foundation
import Combine
import AppKit

/// Detects Spotify playback state via distributed notifications and AppleScript.
/// When music is playing, publishes track info so the pet can dance along.
@MainActor
final class MusicDetector: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var trackName: String?
    @Published private(set) var artistName: String?
    @Published private(set) var albumArt: NSImage?

    private var notificationTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var lastArtworkURL: String?

    init() {
        setupNotificationObserver()
        // Initial check in case Spotify is already playing
        Task { await updatePlaybackInfo() }
    }

    deinit {
        notificationTask?.cancel()
        artworkTask?.cancel()
    }

    // MARK: - Notification observer

    private func setupNotificationObserver() {
        notificationTask = Task { [weak self] in
            let notifications = DistributedNotificationCenter.default().notifications(
                named: NSNotification.Name("com.spotify.client.PlaybackStateChanged")
            )
            for await _ in notifications {
                await self?.updatePlaybackInfo()
            }
        }
    }

    // MARK: - AppleScript queries

    private func isSpotifyRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.spotify.client"
        }
    }

    func updatePlaybackInfo() async {
        guard isSpotifyRunning() else {
            if isPlaying {
                print("[MusicDetector] Spotify not running")
            }
            isPlaying = false
            trackName = nil
            artistName = nil
            return
        }

        let script = """
        tell application "Spotify"
            try
                set playerState to player state is playing
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set artworkURL to artwork url of current track
                return {playerState, currentTrackName, currentTrackArtist, artworkURL}
            on error
                return {false, "", "", ""}
            end try
        end tell
        """

        let result = runAppleScript(script)

        guard let result else {
            print("[MusicDetector] AppleScript returned nil")
            isPlaying = false
            return
        }

        guard result.numberOfItems >= 4 else {
            print("[MusicDetector] Unexpected result count: \(result.numberOfItems)")
            isPlaying = false
            return
        }

        let playing = result.atIndex(1)?.booleanValue ?? false
        let track = result.atIndex(2)?.stringValue
        let artist = result.atIndex(3)?.stringValue
        let artworkURLString = result.atIndex(4)?.stringValue

        print("[MusicDetector] playing=\(playing) track=\(track ?? "nil") artist=\(artist ?? "nil")")

        isPlaying = playing
        trackName = (track?.isEmpty == false) ? track : nil
        artistName = (artist?.isEmpty == false) ? artist : nil

        // Fetch album art if URL changed
        if let urlString = artworkURLString, !urlString.isEmpty, urlString != lastArtworkURL {
            lastArtworkURL = urlString
            artworkTask?.cancel()
            artworkTask = Task {
                guard let url = URL(string: urlString),
                      let (data, _) = try? await URLSession.shared.data(from: url),
                      let image = NSImage(data: data) else { return }
                if !Task.isCancelled {
                    self.albumArt = image
                }
            }
        } else if artworkURLString?.isEmpty != false {
            albumArt = nil
            lastArtworkURL = nil
        }
    }

    /// NSAppleScript must be created and executed on the same thread.
    /// Since MusicDetector is @MainActor, we run it synchronously here.
    private func runAppleScript(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: source) else {
            print("[MusicDetector] Failed to create NSAppleScript")
            return nil
        }
        let result = appleScript.executeAndReturnError(&error)
        if let error {
            print("[MusicDetector] AppleScript error: \(error)")
            return nil
        }
        return result
    }
}
