import SwiftUI
import SpriteKit
import Combine

struct PanelView: View {
    @ObservedObject var state: PanelState
    let metrics: NotchMetrics
    @StateObject private var petStore = PetStore()
    @StateObject private var mySceneHolder = PetSceneHolder(species: "penguin", background: "japan_background")
    @StateObject private var partnerSceneHolder = PetSceneHolder(species: "penguin", background: "bedroom_background")
    @State private var statMonitor: PetStatMonitor?
    @State private var statCancellable: AnyCancellable?
    @State private var isComposingMessage = false
    @State private var messageText = ""

    private let openAnimation  = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

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
    }

    // MARK: – Notch content

    private var notchContent: some View {
        VStack(spacing: 0) {
            Color.clear
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
        // 1-pixel black bar fills the gap between the shape's inner corner curves and the screen edge.
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
        .onTapGesture {
            if isComposingMessage {
                finishComposing()
            }
        }
    }

    // MARK: – Expanded content

    private var expandedContent: some View {
        HStack(spacing: 10) {
            myPetColumn
            partnerPetSlot
        }
    }

    private var myPetColumn: some View {
        PetSlotView(
            background: petStore.myPet?.background ?? "japan_background",
            species: petStore.myPet?.species ?? "penguin",
            sceneHolder: mySceneHolder,
            interactionDisabled: isComposingMessage
        )
        .overlay(alignment: .top) {
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
                .frame(maxWidth: Constants.PET_SLOT_WIDTH / 3)
                .frame(width: Constants.PET_SLOT_WIDTH / 2, alignment: .center)
                .padding(.top, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
            } else if !mySceneHolder.isThrowingBall,
                      let message = petStore.myPet?.currentMessage,
                      let sentAt = petStore.myPet?.messageSentAt {
                SpeechBubbleView(message: message, sentAt: sentAt)
                    .frame(maxWidth: Constants.PET_SLOT_WIDTH / 3)
                    .frame(width: Constants.PET_SLOT_WIDTH / 2, alignment: .center)
                    .padding(.top, 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            StatBarsOverlay(
                hunger: petStore.myPet?.hunger ?? 100,
                happiness: petStore.myPet?.happiness ?? 100
            )
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
                    mySceneHolder.scene.trigger(.playing)
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
        PetSlotView(
            background: petStore.partnerPet?.background ?? "bedroom_background",
            species: petStore.partnerPet?.species ?? "penguin",
            sceneHolder: partnerSceneHolder
        )
        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
    }
}
