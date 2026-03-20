import SwiftUI

struct PanelView: View {
    @ObservedObject var state: PanelState
    let metrics: NotchMetrics
    @StateObject private var petStore = PetStore()

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
    }

    // MARK: – Notch content

    private var notchContent: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: metrics.notchHeight)

            if state.isExpanded {
                expandedContent
                    .padding(.top, 20)
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
    }

    // MARK: – Expanded content

    private var expandedContent: some View {
        HStack(spacing: 10) {
            myPetSlot
            partnerPetSlot
        }
    }

    private var myPetSlot: PetSlotView {
        PetSlotView(
            background: petStore.myPet?.background ?? "japan_background",
            species: petStore.myPet?.species ?? "penguin"
        )
    }

    private var partnerPetSlot: some View {
        PetSlotView(
            background: petStore.partnerPet?.background ?? "bedroom_background",
            species: petStore.partnerPet?.species ?? "penguin"
        )
        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
    }
}
