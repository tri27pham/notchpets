import SwiftUI

struct PetSlotView: View {
    let background: String

    var body: some View {
        GeometryReader { geo in
            Image(background)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
