import CoreGraphics

enum Constants {
    // Open-state window dimensions — mirrors boring.notch's openNotchSize / shadowPadding
    static let OPEN_WIDTH: CGFloat = 640
    static let OPEN_HEIGHT: CGFloat = 190   // content area including the notch cap
    static let SHADOW_PADDING: CGFloat = 20 // extra window height for shadow, below content

    // Corner radii — mirrors boring.notch's cornerRadiusInsets
    static let cornerRadiusInsets = (
        opened: (top: CGFloat(19), bottom: CGFloat(24)),
        closed:  (top: CGFloat(6),  bottom: CGFloat(14))
    )

    static let PET_SLOT_WIDTH: CGFloat = 180
    static let PET_SLOT_HEIGHT: CGFloat = 150
    static let COLLAPSE_DEBOUNCE_SECONDS: Double = 0.3
}

// Global alias so NotchShape.swift can reference it the same way boring.notch does.
let cornerRadiusInsets = Constants.cornerRadiusInsets
