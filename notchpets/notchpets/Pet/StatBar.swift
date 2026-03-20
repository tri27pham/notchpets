import SwiftUI

struct StatBar: View {
    let icon: String
    let value: Int
    let color: Color

    private var fraction: CGFloat { CGFloat(value) / 100.0 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(color.opacity(0.9))
                .frame(width: 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * fraction)
                        .animation(.easeOut(duration: 0.3), value: value)
                }
            }
            .frame(width: 40, height: 4)
        }
    }
}
