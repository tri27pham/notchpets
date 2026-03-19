import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {
    let metrics: NotchMetrics
    let panelState = PanelState()

    var notchPanel: NotchPanel { window as! NotchPanel }

    init() {
        metrics = NotchMetrics.current()
        let panel = NotchPanel()
        super.init(window: panel)

        // SwiftUI handles all expand/collapse — no NSTrackingView needed.
        let hostingView = NSHostingView(
            rootView: PanelView(state: panelState, metrics: metrics)
        )
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        panel.orderFrontRegardless()

        // Reposition after ordering to front (mirrors boring.notch's positionWindow call).
        // The window is fixed at open size; SwiftUI animates the visible content within it.
        if let screen = NSScreen.screens.first {
            let totalHeight = Constants.OPEN_HEIGHT + Constants.SHADOW_PADDING
            let x = screen.frame.midX - Constants.OPEN_WIDTH / 2
            let y = screen.frame.maxY - totalHeight
            panel.setFrame(
                NSRect(x: x, y: y, width: Constants.OPEN_WIDTH, height: totalHeight),
                display: false
            )
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
