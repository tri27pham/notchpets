import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {
    let metrics: NotchMetrics
    let panelState = PanelState()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hoverTask: Task<Void, Never>?
    private var closedScreenRect: NSRect = .zero
    private var expandedScreenRect: NSRect = .zero

    var notchPanel: NotchPanel { window as! NotchPanel }

    init() {
        metrics = NotchMetrics.current()
        let panel = NotchPanel()
        super.init(window: panel)

        let hostingView = NSHostingView(
            rootView: PanelView(state: panelState, metrics: metrics)
        )
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        panel.orderFrontRegardless()

        if let screen = NSScreen.screens.first {
            let totalHeight = Constants.OPEN_HEIGHT + Constants.SHADOW_PADDING
            let x = screen.frame.midX - Constants.OPEN_WIDTH / 2
            let y = screen.frame.maxY - totalHeight
            panel.setFrame(
                NSRect(x: x, y: y, width: Constants.OPEN_WIDTH, height: totalHeight),
                display: false
            )

            closedScreenRect = NSRect(
                x: screen.frame.midX - metrics.notchWidth / 2,
                y: screen.frame.maxY - metrics.notchHeight,
                width: metrics.notchWidth,
                height: metrics.notchHeight
            )

            expandedScreenRect = NSRect(
                x: screen.frame.midX - Constants.OPEN_WIDTH / 2,
                y: screen.frame.maxY - Constants.OPEN_HEIGHT,
                width: Constants.OPEN_WIDTH,
                height: Constants.OPEN_HEIGHT
            )
        }

        startMouseMonitoring()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        hoverTask?.cancel()
    }

    // MARK: – Mouse monitoring

    // When collapsed, ignoresMouseEvents is true so events go to apps behind the panel;
    // the global monitor detects when the cursor enters the notch zone. When expanded,
    // ignoresMouseEvents is false so the local monitor detects when the cursor leaves.
    private func startMouseMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.evaluateMousePosition()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.evaluateMousePosition()
            return event
        }
    }

    private func evaluateMousePosition() {
        let mouse = NSEvent.mouseLocation

        if panelState.isExpanded {
            if expandedScreenRect.contains(mouse) {
                hoverTask?.cancel()
                hoverTask = nil
            } else {
                scheduleCollapse()
            }
        } else {
            if closedScreenRect.contains(mouse) {
                scheduleExpand()
            } else {
                hoverTask?.cancel()
                hoverTask = nil
            }
        }
    }

    private func scheduleExpand() {
        guard hoverTask == nil else { return }
        hoverTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled, let self else { return }
            self.panelState.isExpanded = true
            self.notchPanel.ignoresMouseEvents = false
            self.hoverTask = nil
        }
    }

    private func scheduleCollapse() {
        guard hoverTask == nil else { return }
        hoverTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.COLLAPSE_DEBOUNCE_SECONDS))
            guard !Task.isCancelled, let self else { return }
            self.panelState.isExpanded = false
            self.notchPanel.ignoresMouseEvents = true
            self.hoverTask = nil
        }
    }
}
