import SwiftUI

struct PanelView: View {
    @ObservedObject var state: PanelState
    let metrics: NotchMetrics

    // Springs mirror boring.notch's ContentView exactly
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
            // Animate all property changes (shape morph, padding, shadow) with the
            // appropriate spring — mirrors boring.notch's conditionalModifier block.
            .animation(
                state.isExpanded ? openAnimation : closeAnimation,
                value: state.isExpanded
            )
            .contentShape(Rectangle())
            .onHover(perform: handleHover)
            // Centre horizontally within the fixed-size window; pin to top.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: – Notch content

    private var notchContent: some View {
        VStack(spacing: 0) {
            // Notch cap — sits over the physical notch hardware, visually extending it.
            // Height matches the physical notch (safeAreaInsets.top).
            Color.clear
                .frame(height: metrics.notchHeight)

            // Pet area — only present when expanded, transitions with scale + fade
            // identical to boring.notch's content transition.
            if state.isExpanded {
                HStack(spacing: 0) {
                    PetSlotView()
                    PetSlotView()
                }
                .frame(height: Constants.OPEN_HEIGHT - metrics.notchHeight)
                .transition(
                    .scale(scale: 0.8, anchor: .top)
                    .combined(with: .opacity)
                )
            }
        }
        // Horizontal padding mirrors boring.notch:
        //   open  → cornerRadiusInsets.opened.top   (19 pt)
        //   closed → cornerRadiusInsets.closed.bottom (14 pt)
        .padding(
            .horizontal,
            state.isExpanded
                ? Constants.cornerRadiusInsets.opened.top
                : Constants.cornerRadiusInsets.closed.bottom
        )
        // Extra horizontal + bottom padding when open (12 pt) — same as boring.notch.
        .padding([.horizontal, .bottom], state.isExpanded ? 12 : 0)
        // Width animates between the physical notch width (closed) and the full open
        // width (640) — mirrors how boring.notch's content naturally changes width
        // between vm.closedNotchSize.width and openNotchSize.width.
        .frame(width: state.isExpanded ? Constants.OPEN_WIDTH : metrics.notchWidth)
        .background(.black)
        .clipShape(currentShape)
        // 1-pixel black bar at the very top fills the gap between the shape's inner
        // corner curves and the screen edge — identical overlay to boring.notch.
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black)
                .frame(height: 1)
                .padding(.horizontal, topCornerRadius)
        }
        // Shadow appears when open — mirrors boring.notch's .enableShadow behaviour
        // but always on (no user setting yet).
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
            // Small delay before opening prevents accidental expansion while passing
            // through the area — mirrors boring.notch's minimumHoverDuration.
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
