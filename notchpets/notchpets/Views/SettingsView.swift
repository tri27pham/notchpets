import SwiftUI

struct SettingsView: View {
    @ObservedObject var petStore: PetStore
    @ObservedObject var authManager: AuthManager
    let onClose: () -> Void

    @State private var editingName: String = ""
    @State private var editingUserName: String = ""
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var userNameFieldFocused: Bool

    private let labelColor = Color.white.opacity(0.4)
    private let rowFont = Font.system(size: 10, weight: .semibold, design: .monospaced)
    private let labelWidth: CGFloat = 75
    private let rowHeight: CGFloat = 24

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left column — pet settings
            VStack(alignment: .leading, spacing: 6) {
                yourNameSection
                nameSection
                speciesPicker
                backgroundPicker
            }
            .frame(width: 260)

            // Right column — partner / connect
            VStack(alignment: .leading, spacing: 6) {
                connectSection
                #if DEBUG
                debugSection
                #endif
            }
            .frame(width: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            editingName = petStore.myPet?.name ?? ""
            editingUserName = petStore.userName
        }
    }

    // MARK: - Connect / Pair

    private var connectSection: some View {
        HStack(spacing: 8) {
            Text("Partner")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            Group {
                if let partner = petStore.partnerPet {
                    ConnectedView(partnerName: partner.name) {
                        petStore.disconnect()
                        Task { await authManager.signOut() }
                    }
                } else if authManager.isSignedIn {
                    PairInlineView(authManager: authManager, petStore: petStore)
                } else {
                    ProgressView()
                        .scaleEffect(0.4)
                }
            }
            .frame(width: 260 - labelWidth - 8, alignment: .leading)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        HStack(spacing: 8) {
            Text("Debug")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            if petStore.partnerPet != nil {
                Button("Remove mock partner") {
                    petStore.unmockPartner()
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.red.opacity(0.7))
                .buttonStyle(.plain)
            } else {
                Button("Add mock partner") {
                    petStore.mockPartner()
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.blue.opacity(0.8))
                .buttonStyle(.plain)
            }
        }
    }
    #endif

    // MARK: - Your name

    private var yourNameSection: some View {
        HStack(spacing: 8) {
            Text("Your name")
                .font(rowFont)
                .foregroundColor(labelColor)
                .frame(width: labelWidth, alignment: .trailing)

            HStack(spacing: 4) {
                TextField("Your name", text: $editingUserName)
                    .textFieldStyle(.plain)
                    .font(rowFont)
                    .foregroundColor(.white)
                    .focused($userNameFieldFocused)
                    .onChange(of: editingUserName) {
                        editingUserName = String(editingUserName.prefix(16))
                    }
                    .onSubmit {
                        commitUserName()
                    }
                    .padding(.horizontal, 6)
                    .frame(height: rowHeight)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )

                if editingUserName != petStore.userName {
                    Button(action: commitUserName) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                            .background(Color.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.15), value: editingUserName != petStore.userName)
        }
    }

    private func commitUserName() {
        let trimmed = editingUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        petStore.userName = trimmed
        userNameFieldFocused = false
    }

    // MARK: - Pet name

    private var nameSection: some View {
        HStack(spacing: 8) {
            Text("Pet name")
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
                    .frame(height: rowHeight)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )

                if editingName != (petStore.myPet?.name ?? "") {
                    Button(action: commitName) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                            .background(Color.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
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
                spriteAsset: "\(allSpecies[currentIndex].rawValue)_spritesheet",
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
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
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
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
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
        HStack(spacing: 6) {
            switch mode {
            case .choose:
                smallButton("Create code") { mode = .create; generateCode() }
                smallButton("Enter code") { mode = .join }
            case .create:
                backButton
                Spacer()
                if let invite {
                    Text(invite.code)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .textSelection(.enabled)
                    Spacer()
                    CopyButton(text: invite.code)
                } else if isLoading {
                    ProgressView().scaleEffect(0.4)
                    Spacer()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.red.opacity(0.8))
                }
            case .join:
                backButton
                TextField("Code", text: $inputCode)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
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
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .disabled(inputCode.count < 6 || isLoading)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
    }

    @ViewBuilder
    private var backButton: some View {
        HoverIconButton(icon: "chevron.left") {
            mode = .choose; invite = nil; errorMessage = nil
        }
    }

    private func smallButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
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

// MARK: - Connected view

private struct ConnectedView: View {
    let partnerName: String
    let onDisconnect: () -> Void

    @State private var isHovered = false

    private let font = Font.system(size: 9, weight: .medium, design: .monospaced)

    var body: some View {
        Button(action: { if isHovered { onDisconnect() } }) {
            ZStack {
                Text(partnerName.isEmpty ? "Connected" : "Connected with \(partnerName)")
                    .font(font)
                    .foregroundColor(.green.opacity(0.9))
                    .opacity(isHovered ? 0 : 1)

                Text("Disconnect")
                    .font(font)
                    .foregroundColor(.white)
                    .opacity(isHovered ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isHovered ? Color.red.opacity(0.5) : Color.green.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(isHovered ? Color.red.opacity(0.6) : Color.green.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - Hover icon button

private struct HoverIconButton: View {
    let icon: String
    var activeIcon: String? = nil
    var activeColor: Color? = nil
    let action: () -> Void

    @State private var isHovered = false
    @State private var isActive = false

    var body: some View {
        Button {
            action()
            if let activeIcon {
                withAnimation(.easeOut(duration: 0.15)) { isActive = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.15)) { isActive = false }
                }
            }
        } label: {
            Image(systemName: isActive ? (activeIcon ?? icon) : icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isActive ? (activeColor ?? .green) : (isHovered ? .white.opacity(0.8) : .white.opacity(0.4)))
                .frame(width: 22, height: 22)
                .background(isHovered ? Color.white.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Copy button

private struct CopyButton: View {
    let text: String

    var body: some View {
        HoverIconButton(icon: "doc.on.doc", activeIcon: "checkmark", activeColor: .green) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }
}

// MARK: - Sprite frame view

private struct SpriteFrameView: View {
    let asset: String
    let cols: Int
    let rows: Int

    var body: some View {
        if let nsImage = NSImage(named: asset) {
            let frameW = nsImage.size.width / CGFloat(cols)
            let frameH = nsImage.size.height / CGFloat(rows)
            let cropRect = CGRect(x: 0, y: nsImage.size.height - frameH, width: frameW, height: frameH)

            if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
               let cropped = cgImage.cropping(to: cropRect) {
                Image(nsImage: NSImage(cgImage: cropped, size: NSSize(width: frameW, height: frameH)))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

// MARK: - Arrow picker

private struct ArrowPicker: View {
    let label: String
    var icon: String? = nil
    var spriteAsset: String? = nil
    var backgroundAsset: String? = nil
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ArrowButton(direction: .left, action: onPrevious)

            HStack(spacing: 5) {
                if let spriteAsset {
                    SpriteFrameView(asset: spriteAsset, cols: 6, rows: 11)
                        .frame(width: 16, height: 16)
                } else if let icon {
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
        .frame(height: 24)
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
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
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
            Text(direction == .left ? "<" : ">")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isHovered ? .white.opacity(0.8) : .white.opacity(0.4))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
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
