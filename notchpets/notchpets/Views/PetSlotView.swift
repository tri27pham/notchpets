import SwiftUI

struct PetSlotView: View {
    let background: String
    let species: String

    var body: some View {
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
