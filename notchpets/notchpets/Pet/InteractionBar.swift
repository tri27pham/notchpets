import SwiftUI

struct StatBarsOverlay: View {
    let hunger: Int
    let happiness: Int

    var body: some View {
        HStack(spacing: 8) {
            StatBar(type: .health, value: happiness)
            StatBar(type: .food, value: hunger)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }
}

struct ActionButtonsOverlay: View {
    let onFeed: () -> Void
    let onPlay: () -> Void
    let onThrowBall: () -> Void
    let onMessage: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ActionButton(icon: "fork.knife", help: "Feed your pet (+30 hunger)", action: onFeed)
            ActionButton(icon: "gamecontroller", help: "Play with your pet (+25 happiness)", action: onPlay)
            ActionButton(icon: "tennisball.fill", help: "Throw ball", action: onThrowBall)
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

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHovered ? .white.opacity(0.6) : .white.opacity(0.8))
                .frame(width: 24, height: 24)
                .background(isHovered ? Color.black.opacity(0.4) : Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
