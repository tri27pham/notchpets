import SwiftUI
import SpriteKit
import Combine

struct PanelView: View {
    @ObservedObject var state: PanelState
    let metrics: NotchMetrics

    @StateObject private var petStore = PetStore()
    @StateObject private var authManager = AuthManager()
    @StateObject private var mySceneHolder = PetSceneHolder(species: "penguin", background: "japan_background")
    @StateObject private var partnerSceneHolder = PetSceneHolder(species: "penguin", background: "bedroom_background")
    @StateObject private var musicDetector = MusicDetector()
    @State private var statMonitor: PetStatMonitor?
    @State private var statCancellable: AnyCancellable?
    @State private var musicCancellable: AnyCancellable?
    @State private var musicTrackCancellable: AnyCancellable?
    @State private var isComposingMessage = false
    @State private var messageText = ""
    @State private var showSettings = false

    private let openAnimation  = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

    private var isPaired: Bool { petStore.partnerPet != nil }
    private var petSlotWidth: CGFloat { isPaired ? Constants.PET_SLOT_WIDTH : Constants.PET_SLOT_SOLO_WIDTH }

    // MARK: – Corner radii (animate with the shape)

    private var topCornerRadius: CGFloat {
        state.isExpanded
            ? Constants.cornerRadiusInsets.opened.top
            : Constants.cornerRadiusInsets.closed.top
    }

    private var currentShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: state.isExpanded
                ? Constants.cornerRadiusInsets.opened.bottom
                : Constants.cornerRadiusInsets.closed.bottom
        )
    }

    // MARK: – Body

    var body: some View {
        notchContent
            .animation(
                state.isExpanded ? openAnimation : closeAnimation,
                value: state.isExpanded
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                let monitor = PetStatMonitor(petStore: petStore)
                statMonitor = monitor

                // Wire stat monitor → pet scene animations
                statCancellable = monitor.$triggeredState
                    .sink { triggered in
                        guard let triggered else { return }
                        mySceneHolder.scene.trigger(triggered)
                    }

                // Wire music detector → pet listening (headphones)
                musicCancellable = musicDetector.$isPlaying
                    .removeDuplicates()
                    .sink { playing in
                        if playing {
                            mySceneHolder.scene.startListening()
                        } else {
                            mySceneHolder.scene.stopListening()
                        }
                    }

                // Wire music detector → Supabase track sync
                musicTrackCancellable = Publishers.CombineLatest(
                    musicDetector.$trackName,
                    musicDetector.$artistName
                )
                .debounce(for: .seconds(1), scheduler: RunLoop.main)
                .sink { track, artist in
                    petStore.updateNowPlaying(track: track, artist: artist)
                }

                // Wire pet scene interactions → stat changes
                mySceneHolder.scene.onInteraction = { [weak petStore] animState in
                    guard let petStore else { return }
                    switch animState {
                    case .playing:
                        petStore.play()
                    case .catchBall:
                        petStore.catchBall()
                    default:
                        break
                    }
                    statMonitor?.recordInteraction()
                }
            }
            .onDisappear {
                petStore.disconnect()
            }
            .onChange(of: petStore.myPet?.species) { _, newSpecies in
                if let newSpecies {
                    mySceneHolder.scene.updateSpecies(newSpecies)
                }
            }
            .onChange(of: petStore.myPet?.background) { _, newBackground in
                if let newBackground {
                    mySceneHolder.scene.updateBackground(newBackground)
                }
            }
            .onChange(of: petStore.partnerPet?.species) { _, newSpecies in
                if let newSpecies {
                    partnerSceneHolder.scene.updateSpecies(newSpecies)
                }
            }
            .onChange(of: petStore.partnerPet?.background) { _, newBackground in
                if let newBackground {
                    partnerSceneHolder.scene.updateBackground(newBackground)
                }
            }
            .onChange(of: petStore.partnerPet?.currentTrackName) { _, newTrack in
                if newTrack != nil {
                    partnerSceneHolder.scene.startListening()
                } else {
                    partnerSceneHolder.scene.stopListening()
                }
            }
            .onChange(of: petStore.partnerPet?.id) { oldId, newId in
                // Pairing status changed — cancel animations and reset positioning
                let wasPaired = oldId != nil
                let nowPaired = newId != nil
                guard wasPaired != nowPaired else { return }
                mySceneHolder.scene.resetToIdle()
                partnerSceneHolder.scene.resetToIdle()

                // Re-apply listening state after reset if partner has a track playing
                if nowPaired, petStore.partnerPet?.currentTrackName != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        partnerSceneHolder.scene.startListening()
                    }
                }
            }
            .onChange(of: showSettings) { _, isShowing in
                state.needsKeyFocus = isShowing
                mySceneHolder.scene.isUserInteractionEnabled = !isShowing
                partnerSceneHolder.scene.isUserInteractionEnabled = !isShowing
            }
    }

    // MARK: – Notch content

    private var notchContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear
                    .frame(maxWidth: .infinity)

                Color.clear
                    .frame(width: metrics.notchWidth)

                HStack {
                    if state.isExpanded {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showSettings.toggle()
                            }
                        } label: {
                            Image(systemName: showSettings ? "xmark" : "gearshape.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 22, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .help(showSettings ? "Close settings" : "Settings")
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
            }
            .frame(height: metrics.notchHeight)

            if state.isExpanded {
                expandedContent
                    .padding(.top, 30)
                    .padding(.bottom, 30)
                    .frame(height: Constants.OPEN_HEIGHT - metrics.notchHeight)
                    .transition(
                        .scale(scale: 0.7, anchor: .top)
                        .combined(with: .opacity)
                    )
            }
        }
        .padding(
            .horizontal,
            state.isExpanded ? 0 : Constants.cornerRadiusInsets.closed.bottom
        )
        .frame(width: state.isExpanded ? Constants.OPEN_WIDTH : metrics.notchWidth)
        .background(.black)
        .clipShape(currentShape)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black)
                .frame(height: 1)
                .padding(.horizontal, topCornerRadius)
        }
        .shadow(
            color: state.isExpanded ? .black.opacity(0.7) : .clear,
            radius: 6
        )
        .background {
            if isComposingMessage {
                Color.black.opacity(0.01)
                    .onTapGesture {
                        finishComposing()
                    }
            }
        }
    }

    // MARK: – Expanded content

    private var expandedContent: some View {
        Group {
            if showSettings {
                SettingsView(petStore: petStore, authManager: authManager) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSettings = false
                    }
                }
            } else {
                HStack(spacing: 10) {
                    myPetColumn
                    if isPaired {
                        partnerPetSlot
                    }
                }
            }
        }
    }

    private var myPetColumn: some View {
        PetSlotView(
            background: petStore.myPet?.background ?? "japan_background",
            species: petStore.myPet?.species ?? "penguin",
            sceneHolder: mySceneHolder,
            interactionDisabled: isComposingMessage
        )
        .frame(width: petSlotWidth, height: Constants.PET_SLOT_HEIGHT)
        .overlay(alignment: isPaired ? .topLeading : .top) {
            StatBarsOverlay(
                hunger: petStore.myPet?.hunger ?? 100,
                happiness: petStore.myPet?.happiness ?? 100,
                horizontal: !isPaired
            )
        }
        .overlay(alignment: isPaired ? .top : .topLeading) {
            if musicDetector.isPlaying, let track = musicDetector.trackName {
                if isPaired {
                    HStack {
                        Spacer()
                            .frame(width: 90)
                        Spacer()
                        NowPlayingOverlay(track: track, artist: musicDetector.artistName, albumArt: musicDetector.albumArt)
                        Spacer()
                        Spacer()
                            .frame(width: 30)
                    }
                    .padding(.top, 5)
                    .transition(.opacity)
                } else {
                    NowPlayingOverlay(track: track, artist: musicDetector.artistName, albumArt: musicDetector.albumArt)
                        .padding(.top, 5)
                        .padding(.leading, 6)
                        .transition(.opacity)
                }
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 2) {

                if isComposingMessage {
                    EditableSpeechBubbleView(
                        text: $messageText,
                        onSend: {
                            finishComposing()
                        },
                        onCancel: {
                            finishComposing()
                        }
                    )
                    .frame(maxWidth: petSlotWidth / 3)
                    .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
                } else if !mySceneHolder.isThrowingBall,
                          let message = petStore.myPet?.currentMessage,
                          let sentAt = petStore.myPet?.messageSentAt {
                    SpeechBubbleView(message: message, sentAt: sentAt)
                        .frame(maxWidth: petSlotWidth / 3)
                        .transition(.opacity)
                }
            }
            .padding(.top, 30)
        }
        .overlay(alignment: .trailing) {
            ActionButtonsOverlay(
                onFeed: {
                    mySceneHolder.isAnimating = true
                    petStore.feed()
                    mySceneHolder.scene.trigger(.eating)
                    statMonitor?.recordInteraction()
                },
                onPlay: {
                    mySceneHolder.isAnimating = true
                    petStore.play()
                    let playAnim: AnimationState = Bool.random() ? .playing : .dancing
                    mySceneHolder.scene.trigger(playAnim)
                    statMonitor?.recordInteraction()
                },
                onThrowBall: {
                    mySceneHolder.isAnimating = true
                    mySceneHolder.scene.throwBall()
                    statMonitor?.recordInteraction()
                },
                onMessage: {
                    startComposing()
                },
                isAnimating: mySceneHolder.isAnimating
            )
        }
    }

    // MARK: – Message composing

    private func startComposing() {
        messageText = petStore.myPet?.currentMessage ?? ""
        isComposingMessage = true
        mySceneHolder.scene.isUserInteractionEnabled = false
        state.needsKeyFocus = true
    }

    private func finishComposing() {
        isComposingMessage = false
        mySceneHolder.scene.isUserInteractionEnabled = true
        state.needsKeyFocus = false

        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            petStore.sendMessage("")
        } else {
            petStore.sendMessage(trimmed)
        }
    }

    private var partnerPetSlot: some View {
        ZStack {
            PetSlotView(
                background: petStore.partnerPet?.background ?? "bedroom_background",
                species: petStore.partnerPet?.species ?? "penguin",
                sceneHolder: partnerSceneHolder
            )
            .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)

            // Partner's speech bubble
            if let message = petStore.partnerPet?.currentMessage,
               let sentAt = petStore.partnerPet?.messageSentAt {
                VStack {
                    SpeechBubbleView(message: message, sentAt: sentAt)
                        .frame(maxWidth: Constants.PET_SLOT_WIDTH / 3)
                    Spacer()
                }
                .padding(.top, 30)
            }

            // Partner's now-playing bubble
            if let track = petStore.partnerPet?.currentTrackName {
                VStack {
                    HStack {
                        Spacer()
                        NowPlayingOverlay(
                            track: track,
                            artist: petStore.partnerPet?.currentTrackArtist,
                            albumArt: nil
                        )
                        Spacer()
                    }
                    .padding(.top, 5)
                    Spacer()
                }
            }

            // Partner stat bars
            VStack {
                HStack {
                    StatBarsOverlay(
                        hunger: petStore.partnerPet?.hunger ?? 100,
                        happiness: petStore.partnerPet?.happiness ?? 100
                    )
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
    }
}

// MARK: - Now Playing overlay

private struct NowPlayingOverlay: View {
    let track: String
    let artist: String?
    let albumArt: NSImage?

    var body: some View {
        HStack(spacing: 4) {
            if let albumArt {
                Image(nsImage: albumArt)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
                    .cornerRadius(2)
            }

            Text(displayText)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(.black.opacity(0.7))
        )
    }

    private var displayText: String {
        if let artist, !artist.isEmpty {
            return "\(track) – \(artist)"
        }
        return track
    }
}
