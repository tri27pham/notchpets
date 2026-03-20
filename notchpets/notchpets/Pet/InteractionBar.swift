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

    var body: some View {
        HStack {
            Button(action: onFeed) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Feed your pet (+30 hunger)")

            Spacer()

            Button(action: onPlay) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Play with your pet (+25 happiness)")
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
    }
}
