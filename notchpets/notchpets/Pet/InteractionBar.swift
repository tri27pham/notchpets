import SwiftUI

struct InteractionBar: View {
    let onFeed: () -> Void
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onFeed) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Feed your pet (+30 hunger)")

            Button(action: onPlay) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Play with your pet (+25 happiness)")
        }
    }
}
