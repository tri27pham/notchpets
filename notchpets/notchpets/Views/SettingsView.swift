import SwiftUI

struct SettingsView: View {
    @ObservedObject var petStore: PetStore
    let onClose: () -> Void

    @State private var editingName: String = ""
    @FocusState private var nameFieldFocused: Bool

    private let labelColor = Color.white.opacity(0.5)
    private let rowFont = Font.system(size: 10, weight: .medium, design: .monospaced)
    private let labelWidth: CGFloat = 75

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            nameSection
            speciesPicker
            backgroundPicker
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            editingName = petStore.myPet?.name ?? ""
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        HStack(spacing: 8) {
            Text("Name")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            HStack(spacing: 4) {
                TextField("Pet name", text: $editingName)
                    .textFieldStyle(.plain)
                    .font(rowFont)
                    .foregroundColor(.white)
                    .focused($nameFieldFocused)
                    .onChange(of: editingName) {
                        editingName = String(editingName.prefix(12))
                    }
                    .onSubmit {
                        commitName()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if editingName != (petStore.myPet?.name ?? "") {
                    Button(action: commitName) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                            .background(Color.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.15), value: editingName != (petStore.myPet?.name ?? ""))
        }
    }

    private func commitName() {
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        petStore.updateName(trimmed)
        nameFieldFocused = false
    }

    // MARK: - Species picker

    private var speciesPicker: some View {
        let allSpecies = Pet.Species.allCases
        let currentIndex = allSpecies.firstIndex(where: { $0.rawValue == petStore.myPet?.species }) ?? 0

        return HStack(spacing: 8) {
            Text("Species")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            ArrowPicker(
                label: allSpecies[currentIndex].rawValue.capitalized,
                icon: allSpecies[currentIndex].emoji,
                onPrevious: {
                    let prev = (currentIndex - 1 + allSpecies.count) % allSpecies.count
                    petStore.updateSpecies(allSpecies[prev].rawValue)
                },
                onNext: {
                    let next = (currentIndex + 1) % allSpecies.count
                    petStore.updateSpecies(allSpecies[next].rawValue)
                }
            )
        }
    }

    // MARK: - Background picker

    private var backgroundPicker: some View {
        let allBgs = Pet.Background.allCases
        let currentIndex = allBgs.firstIndex(where: { $0.assetName == petStore.myPet?.background }) ?? 0

        return HStack(spacing: 8) {
            Text("Background")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            ArrowPicker(
                label: allBgs[currentIndex].displayName,
                backgroundAsset: allBgs[currentIndex].assetName,
                onPrevious: {
                    let prev = (currentIndex - 1 + allBgs.count) % allBgs.count
                    petStore.updateBackground(allBgs[prev].assetName)
                },
                onNext: {
                    let next = (currentIndex + 1) % allBgs.count
                    petStore.updateBackground(allBgs[next].assetName)
                }
            )


        }
    }
}

// MARK: - Arrow picker

private struct ArrowPicker: View {
    let label: String
    var icon: String? = nil
    var backgroundAsset: String? = nil
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ArrowButton(direction: .left, action: onPrevious)

            HStack(spacing: 5) {
                if let icon {
                    Text(icon)
                        .font(.system(size: 12))
                }

                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            ArrowButton(direction: .right, action: onNext)
        }
        .padding(.vertical, 4)
        .background {
            if let asset = backgroundAsset {
                Image(asset)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.5))
                    .clipped()
                    .allowsHitTesting(false)
            } else {
                Color.white.opacity(0.08)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct ArrowButton: View {
    enum Direction { case left, right }
    let direction: Direction
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isHovered ? .white.opacity(0.8) : .white.opacity(0.4))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Model helpers

extension Pet.Species {
    var emoji: String {
        switch self {
        case .cat: "🐱"
        case .dog: "🐶"
        case .frog: "🐸"
        case .panda: "🐼"
        case .penguin: "🐧"
        case .rabbit: "🐰"
        }
    }
}

extension Pet.Background {
    var assetName: String {
        rawValue + "_background"
    }

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
