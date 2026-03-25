import SwiftUI
import SpriteKit
import Combine

class PetSceneHolder: ObservableObject {
    let scene: PetScene
    @Published var isAnimating = false
    @Published var isThrowingBall = false
    @Published var isListening = false

    init(species: String, background: String) {
        scene = PetScene(
            size: CGSize(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT),
            species: species,
            background: background
        )
        scene.onAnimationStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.isAnimating = state != .idle && state != .headphones
            }
        }
        scene.onThrowingBallChanged = { [weak self] throwing in
            DispatchQueue.main.async {
                self?.isThrowingBall = throwing
            }
        }
        scene.onListeningChanged = { [weak self] listening in
            DispatchQueue.main.async {
                self?.isListening = listening
            }
        }
    }
}
