import AppKit

struct NotchMetrics {
    let notchHeight: CGFloat
    let notchWidth: CGFloat
    let leftAux: CGFloat
    let rightAux: CGFloat
    let hasNotch: Bool

    /// Reads the physical notch dimensions from NSScreen APIs.
    /// Falls back to a 200px notch width on non-notch Macs or pre-macOS 12.
    static func current() -> NotchMetrics {
        guard let screen = NSScreen.screens.first else { return .fallback }

        if #available(macOS 12.0, *) {
            let notchHeight = screen.safeAreaInsets.top
            guard notchHeight > 0 else { return .fallback }

            if let leftRect = screen.auxiliaryTopLeftArea,
               let rightRect = screen.auxiliaryTopRightArea,
               leftRect.width > 0, rightRect.width > 0 {
                let notchWidth = screen.frame.width - leftRect.width - rightRect.width + 4
                return NotchMetrics(
                    notchHeight: notchHeight,
                    notchWidth: notchWidth,
                    leftAux: leftRect.width,
                    rightAux: rightRect.width,
                    hasNotch: true
                )
            }
            return NotchMetrics(notchHeight: notchHeight, notchWidth: 500, leftAux: 0, rightAux: 0, hasNotch: true)
        }

        return .fallback
    }

    private static let fallback = NotchMetrics(
        notchHeight: 0, notchWidth: 200, leftAux: 0, rightAux: 0, hasNotch: false
    )
}
