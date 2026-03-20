import SwiftUI
import SpriteKit
import Combine

class PetSceneHolder: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    let scene: PetScene

    init(species: String, background: String) {
        scene = PetScene(
            size: CGSize(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT),
            species: species,
            background: background
        )
    }
}
