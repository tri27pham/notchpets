import SwiftUI

struct StatBarsOverlay: View {
    let hunger: Int
    let happiness: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            StatBar(type: .health, value: happiness)
            StatBar(type: .food, value: hunger)
        }
        .padding(.leading, 6)
        .padding(.top, 5)
    }
}

struct ActionButtonsOverlay: View {
    let onFeed: () -> Void
    let onPlay: () -> Void
    let onThrowBall: () -> Void
    let onMessage: () -> Void
    var isAnimating: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ActionButton(icon: "fork.knife", help: "Feed your pet (+30 hunger)", action: onFeed, disabled: isAnimating)
            ActionButton(icon: "gamecontroller", help: "Play with your pet (+25 happiness)", action: onPlay, disabled: isAnimating)
            ActionButton(icon: "tennisball.fill", help: "Throw ball", action: onThrowBall, disabled: isAnimating)
            ActionButton(icon: "bubble.left.fill", help: "Send a message", action: onMessage)
        }
        .padding(.trailing, 6)
        .padding(.vertical, 6)
    }
}

private struct ActionButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    var disabled: Bool = false

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHovered ? .white.opacity(0.8) : .white.opacity(0.6))
                .frame(width: 24, height: 24)
                .background(isHovered ? Color.white.opacity(0.15) : Color.black.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
    }
}
