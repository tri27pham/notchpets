import SwiftUI

struct PetSlotView: View {
    var body: some View {
        ZStack {
            Color(red: 0, green: 0, blue: 0)

            Rectangle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
        }
        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
    }
}
