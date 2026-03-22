import SwiftUI
import SpriteKit

struct PetSlotView: View {
    let background: String
    let species: String
    @ObservedObject var sceneHolder: PetSceneHolder
    var interactionDisabled: Bool = false

    var body: some View {
        // TODO: use penguin spritesheet for all species until individual assets are added
        if true {
            Group {
                if interactionDisabled, let snapshot = captureSnapshot() {
                    Image(nsImage: snapshot)
                        .resizable()
                        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
                } else {
                    SpriteView(scene: sceneHolder.scene, options: [.allowsTransparency])
                        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            staticPetView
        }
    }

    private func captureSnapshot() -> NSImage? {
        guard let view = sceneHolder.scene.view,
              let texture = view.texture(from: sceneHolder.scene) else { return nil }
        let cgImage = texture.cgImage()
        let size = NSSize(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
        return NSImage(cgImage: cgImage, size: size)
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
