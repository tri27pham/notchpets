import SwiftUI
import SpriteKit

struct PetSlotView: View {
    let background: String
    let species: String
    @ObservedObject var sceneHolder: PetSceneHolder

    var body: some View {
        if species == "penguin" {
            SpriteView(scene: sceneHolder.scene, options: [.allowsTransparency])
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
}
