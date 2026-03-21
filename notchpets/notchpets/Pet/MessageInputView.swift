import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    let onCancel: () -> Void

    private let charLimit = 48

    var body: some View {
        HStack(spacing: 4) {
            TextField("Type a message...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .onChange(of: text) {
                    if text.count > charLimit {
                        text = String(text.prefix(charLimit))
                    }
                }
                .onSubmit {
                    if !text.isEmpty {
                        onSend()
                    }
                }

            Text("\(text.count)/\(charLimit)")
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
