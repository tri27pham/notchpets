import SwiftUI
import SpriteKit
import Combine

class PetSceneHolder: ObservableObject {
    let scene: PetScene

    init(species: String, background: String) {
        scene = PetScene(
            size: CGSize(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT),
            species: species,
            background: background
        )
    }
}

struct PetSlotView: View {
    let background: String
    let species: String

    @StateObject private var holder: PetSceneHolder

    init(background: String, species: String) {
        self.background = background
        self.species = species
        _holder = StateObject(wrappedValue: PetSceneHolder(species: species, background: background))
    }

    var body: some View {
        if species == "penguin" {
            SpriteView(scene: holder.scene, options: [.allowsTransparency])
                .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            staticPetView
        }
    }

    private var staticPetView: some View {
        GeometryReader { geo in
            ZStack {
                Image(background)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                Image(species)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.5, height: geo.size.height * 0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func trigger(_ state: AnimationState) {
        holder.scene.trigger(state)
    }
}
