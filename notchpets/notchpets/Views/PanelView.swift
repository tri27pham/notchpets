import SwiftUI

struct PanelView: View {
    @ObservedObject var state: PanelState
    let metrics: NotchMetrics

    private let openAnimation  = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

    @State private var hoverTask: Task<Void, Never>?

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
            .contentShape(Rectangle())
            .onHover(perform: handleHover)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: – Notch content

    private var notchContent: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: metrics.notchHeight)

            if state.isExpanded {
                HStack(spacing: 10) {
                    PetSlotView(background: "japan_background")
                        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
                    PetSlotView(background: "bedroom_background")
                        .frame(width: Constants.PET_SLOT_WIDTH, height: Constants.PET_SLOT_HEIGHT)
                }
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

    // MARK: – Hover handling

    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        hoverTask = nil

        if hovering {
            // Small delay prevents accidental expansion while passing through the area.
            hoverTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                state.isExpanded = true
            }
        } else {
            hoverTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(Constants.COLLAPSE_DEBOUNCE_SECONDS))
                guard !Task.isCancelled else { return }
                state.isExpanded = false
            }
        }
    }
}
