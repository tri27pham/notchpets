import SwiftUI

struct SettingsView: View {
    @ObservedObject var petStore: PetStore
    @ObservedObject var authManager: AuthManager
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
            Spacer().frame(height: 2)
            connectSection
        }
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            editingName = petStore.myPet?.name ?? ""
        }
    }

    // MARK: - Connect / Pair

    private var connectSection: some View {
        HStack(spacing: 8) {
            Text("Partner")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            if petStore.partnerPet != nil {
                HStack(spacing: 6) {
                    Text("Connected")
                        .font(rowFont)
                        .foregroundColor(.green.opacity(0.8))

                    Button {
                        petStore.disconnect()
                        Task { await authManager.signOut() }
                    } label: {
                        Text("Disconnect")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            } else if !authManager.isSignedIn {
                ConnectButton(authManager: authManager)
            } else {
                PairInlineView(authManager: authManager, petStore: petStore)
            }
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

// MARK: - Connect button (triggers magic link sign-in)

private struct ConnectButton: View {
    @ObservedObject var authManager: AuthManager
    @State private var email = ""
    @State private var isSending = false
    @State private var linkSent = false
    @State private var errorMessage: String?

    private let rowFont = Font.system(size: 10, weight: .medium, design: .monospaced)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if linkSent {
                Text("Check your email for a magic link!")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.green.opacity(0.9))

                Button("Resend") { linkSent = false }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .buttonStyle(.plain)
            } else {
                HStack(spacing: 4) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .font(rowFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .onSubmit { sendLink() }

                    Button(action: sendLink) {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.4)
                                .frame(width: 36, height: 22)
                        } else {
                            Text("Connect")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(height: 22)
                                .padding(.horizontal, 6)
                        }
                    }
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .disabled(email.isEmpty || isSending)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    private func sendLink() {
        guard !email.isEmpty else { return }
        isSending = true
        errorMessage = nil
        Task {
            do {
                try await authManager.sendMagicLink(email: email)
                linkSent = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

// MARK: - Pair inline view (generate or enter code)

private struct PairInlineView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var petStore: PetStore
    @State private var mode: Mode = .choose
    @State private var invite: Invite?
    @State private var inputCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum Mode { case choose, create, join }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch mode {
            case .choose:
                HStack(spacing: 6) {
                    smallButton("Create code") { mode = .create; generateCode() }
                    smallButton("Enter code") { mode = .join }
                }
            case .create:
                if let invite {
                    HStack(spacing: 4) {
                        Text(invite.code)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .textSelection(.enabled)

                        Text("share this")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else if isLoading {
                    ProgressView().scaleEffect(0.4)
                }
                backButton
            case .join:
                HStack(spacing: 4) {
                    TextField("Code", text: $inputCode)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .frame(maxWidth: 80)
                        .onChange(of: inputCode) {
                            inputCode = String(inputCode.prefix(6)).uppercased()
                        }
                        .onSubmit { acceptCode() }

                    Button(action: acceptCode) {
                        if isLoading {
                            ProgressView().scaleEffect(0.4).frame(width: 30, height: 22)
                        } else {
                            Text("Join")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(height: 22)
                                .padding(.horizontal, 6)
                        }
                    }
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .disabled(inputCode.count < 6 || isLoading)
                }
                backButton
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    private var backButton: some View {
        Button("Back") { mode = .choose; invite = nil; errorMessage = nil }
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(.white.opacity(0.4))
            .buttonStyle(.plain)
    }

    private func smallButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func generateCode() {
        guard let userId = authManager.userId else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                invite = try await PetRepository.createInvite(creatorId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func acceptCode() {
        guard let userId = authManager.userId, inputCode.count == 6 else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let pair = try await PetRepository.acceptInvite(code: inputCode, acceptorId: userId)
                petStore.connect(userId: userId, pairId: pair.id)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
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
