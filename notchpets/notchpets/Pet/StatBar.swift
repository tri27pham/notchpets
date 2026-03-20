import SwiftUI

// MARK: - Stat Type

enum StatType {
    case health
    case food
}

// MARK: - Stat Bar

struct StatBar: View {
    let type: StatType
    let value: Int

    private let totalIcons = 8

    private var filledIcons: Int {
        if value <= 0 { return 0 }
        if value >= 100 { return totalIcons }
        return max(0, Int(round(Double(value) * Double(totalIcons) / 100.0)))
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<totalIcons, id: \.self) { index in
                let filled = index < filledIcons
                switch type {
                case .health:
                    PixelHeart(filled: filled)
                case .food:
                    PixelCarrot(filled: filled)
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: value)
    }
}

// MARK: - Pixel Art Renderer

private struct PixelArtView: View {
    let pixels: [[Color?]]
    let pixelSize: CGFloat

    var body: some View {
        Canvas { context, _ in
            for (row, rowPixels) in pixels.enumerated() {
                for (col, color) in rowPixels.enumerated() {
                    guard let color else { continue }
                    let rect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(
            width: CGFloat(pixels.first?.count ?? 0) * pixelSize,
            height: CGFloat(pixels.count) * pixelSize
        )
    }
}

// MARK: - Pixel color palette

private let clr: Color? = nil
private let blk: Color? = .black

// Heart colors (filled)
private let hRd: Color? = Color(red: 0.85, green: 0.15, blue: 0.15)
private let hHi: Color? = Color(red: 1.00, green: 0.55, blue: 0.55)
private let hDk: Color? = Color(red: 0.55, green: 0.08, blue: 0.08)

// Heart colors (empty)
private let eDk: Color? = Color(red: 0.18, green: 0.18, blue: 0.22)
private let eLt: Color? = Color(red: 0.25, green: 0.25, blue: 0.30)

// Carrot colors (filled)
private let cOr: Color? = Color(red: 0.95, green: 0.55, blue: 0.10)
private let cHi: Color? = Color(red: 1.00, green: 0.75, blue: 0.35)
private let cDk: Color? = Color(red: 0.70, green: 0.35, blue: 0.05)
private let cGr: Color? = Color(red: 0.30, green: 0.70, blue: 0.15)
private let cGd: Color? = Color(red: 0.20, green: 0.50, blue: 0.10)

// MARK: - Pixel Heart

private struct PixelHeart: View {
    let filled: Bool

    // 9x8 pixel heart
    private var pattern: [[Color?]] {
        if filled {
            return [
                [clr, clr, blk, blk, clr, blk, blk, clr, clr],
                [clr, blk, hHi, hHi, blk, hRd, hRd, blk, clr],
                [blk, hHi, hHi, hRd, hRd, hRd, hRd, hRd, blk],
                [blk, hHi, hRd, hRd, hRd, hRd, hRd, hDk, blk],
                [blk, hRd, hRd, hRd, hRd, hRd, hDk, hDk, blk],
                [clr, blk, hRd, hRd, hRd, hDk, hDk, blk, clr],
                [clr, clr, blk, hRd, hDk, hDk, blk, clr, clr],
                [clr, clr, clr, blk, hDk, blk, clr, clr, clr],
                [clr, clr, clr, clr, blk, clr, clr, clr, clr],
            ]
        } else {
            return [
                [clr, clr, blk, blk, clr, blk, blk, clr, clr],
                [clr, blk, eLt, eLt, blk, eDk, eDk, blk, clr],
                [blk, eLt, eLt, eDk, eDk, eDk, eDk, eDk, blk],
                [blk, eLt, eDk, eDk, eDk, eDk, eDk, eDk, blk],
                [blk, eDk, eDk, eDk, eDk, eDk, eDk, eDk, blk],
                [clr, blk, eDk, eDk, eDk, eDk, eDk, blk, clr],
                [clr, clr, blk, eDk, eDk, eDk, blk, clr, clr],
                [clr, clr, clr, blk, eDk, blk, clr, clr, clr],
                [clr, clr, clr, clr, blk, clr, clr, clr, clr],
            ]
        }
    }

    var body: some View {
        PixelArtView(pixels: pattern, pixelSize: 1.5)
    }
}

// MARK: - Pixel Carrot

private struct PixelCarrot: View {
    let filled: Bool

    // 9x9 pixel carrot (same size as heart)
    private var pattern: [[Color?]] {
        if filled {
            return [
                [clr, clr, clr, cGr, cGr, cGr, clr, clr, clr],
                [clr, clr, cGd, cGr, cGr, cGr, cGd, clr, clr],
                [clr, clr, clr, cGd, cGr, cGd, clr, clr, clr],
                [clr, clr, clr, blk, blk, blk, clr, clr, clr],
                [clr, clr, blk, cHi, cOr, cOr, blk, clr, clr],
                [clr, clr, blk, cOr, cOr, cDk, blk, clr, clr],
                [clr, clr, clr, blk, cOr, blk, clr, clr, clr],
                [clr, clr, clr, blk, cDk, blk, clr, clr, clr],
                [clr, clr, clr, clr, blk, clr, clr, clr, clr],
            ]
        } else {
            return [
                [clr, clr, clr, eLt, eLt, eLt, clr, clr, clr],
                [clr, clr, eDk, eLt, eLt, eLt, eDk, clr, clr],
                [clr, clr, clr, eDk, eLt, eDk, clr, clr, clr],
                [clr, clr, clr, blk, blk, blk, clr, clr, clr],
                [clr, clr, blk, eLt, eDk, eDk, blk, clr, clr],
                [clr, clr, blk, eDk, eDk, eDk, blk, clr, clr],
                [clr, clr, clr, blk, eDk, blk, clr, clr, clr],
                [clr, clr, clr, blk, eDk, blk, clr, clr, clr],
                [clr, clr, clr, clr, blk, clr, clr, clr, clr],
            ]
        }
    }

    var body: some View {
        PixelArtView(pixels: pattern, pixelSize: 1.5)
    }
}
