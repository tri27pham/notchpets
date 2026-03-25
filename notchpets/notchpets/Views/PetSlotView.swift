import SwiftUI
import SpriteKit

struct PetSlotView: View {
    let background: String
    let species: String
    @ObservedObject var sceneHolder: PetSceneHolder
    var interactionDisabled: Bool = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if interactionDisabled, let snapshot = captureSnapshot(size: geo.size) {
                    Image(nsImage: snapshot)
                        .resizable()
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    SpriteView(scene: sceneHolder.scene, options: [.allowsTransparency])
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func captureSnapshot(size: CGSize) -> NSImage? {
        guard let view = sceneHolder.scene.view,
              let texture = view.texture(from: sceneHolder.scene) else { return nil }
        let cgImage = texture.cgImage()
        return NSImage(cgImage: cgImage, size: NSSize(width: size.width, height: size.height))
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
