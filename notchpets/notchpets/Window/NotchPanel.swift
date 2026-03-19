import AppKit

/// The window that hosts the notch UI.
///
/// Mirrors boring.notch's BoringNotchWindow setup:
/// - Always sized to the maximum open dimensions (OPEN_WIDTH × (OPEN_HEIGHT + SHADOW_PADDING)).
///   Expand/collapse is handled entirely by SwiftUI animations inside PanelView — the window
///   frame never changes after initial placement.
/// - Level .mainMenu + 3, clear background, no shadow, non-activating panel.
final class NotchPanel: NSPanel {
    init() {
        // Start at origin zero; NotchWindowController repositions after orderFrontRegardless.
        let totalHeight = Constants.OPEN_HEIGHT + Constants.SHADOW_PADDING
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Constants.OPEN_WIDTH, height: totalHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true

        // Same level as boring.notch (CGWindowLevelForKey(.mainMenuWindow) + 3)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)

        // Same collection behaviour as boring.notch
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Bypass macOS safe-area clamping so the panel can sit above the menu bar.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
