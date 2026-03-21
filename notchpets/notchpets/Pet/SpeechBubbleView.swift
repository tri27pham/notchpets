import SwiftUI

struct SpeechBubbleView: View {
    let message: String
    let sentAt: Date

    @State private var opacity: Double = 1.0
    private let fadeAfter: TimeInterval = 60

    private let parchment = Color(red: 0.96, green: 0.93, blue: 0.85)
    private let borderColor = Color.black
    private let shadowColor = Color.black.opacity(0.25)

    private let borderWidth: CGFloat = 2
    private let tailSize: CGFloat = 6

    var body: some View {
        Text(message)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                PixelBubble(
                    borderWidth: borderWidth,
                    tailSize: tailSize,
                    fillColor: parchment,
                    borderColor: borderColor,
                    shadowColor: shadowColor
                )
            )
            .padding(.bottom, tailSize + borderWidth)
            .opacity(opacity)
            .onAppear {
                let elapsed = Date().timeIntervalSince(sentAt)
                if elapsed >= fadeAfter {
                    opacity = 0
                } else {
                    opacity = 1.0
                    let remaining = fadeAfter - elapsed
                    withAnimation(.easeOut(duration: 2).delay(remaining)) {
                        opacity = 0
                    }
                }
            }
            .onChange(of: message) {
                opacity = 1.0
                withAnimation(.easeOut(duration: 2).delay(fadeAfter)) {
                    opacity = 0
                }
            }
    }
}

struct EditableSpeechBubbleView: View {
    @Binding var text: String
    let onSend: () -> Void
    let onCancel: () -> Void

    private let charLimit = 48
    private let parchment = Color(red: 0.96, green: 0.93, blue: 0.85)
    private let borderColor = Color.black
    private let shadowColor = Color.black.opacity(0.25)

    private let borderWidth: CGFloat = 2
    private let tailSize: CGFloat = 6

    var body: some View {
        WrappingTextField(
            text: $text,
            placeholder: "Type a message...",
            charLimit: charLimit,
            onSubmit: onSend
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            PixelBubble(
                borderWidth: borderWidth,
                tailSize: tailSize,
                fillColor: parchment,
                borderColor: borderColor,
                shadowColor: shadowColor
            )
        )
        .padding(.bottom, tailSize + borderWidth)
    }
}

private class AutoSizingTextView: NSTextView {
    var onHeightChange: (() -> Void)?

    override var intrinsicContentSize: NSSize {
        guard let container = textContainer, let manager = layoutManager else {
            return super.intrinsicContentSize
        }
        manager.ensureLayout(for: container)
        let rect = manager.usedRect(for: container)
        return NSSize(width: NSView.noIntrinsicMetric, height: rect.height + textContainerInset.height * 2)
    }

    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
        onHeightChange?()
    }
}

private struct WrappingTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let charLimit: Int
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> AutoSizingTextView {
        let textView = AutoSizingTextView()
        textView.font = NSFont.monospacedSystemFont(ofSize: 8, weight: .medium)
        textView.textColor = .black
        textView.backgroundColor = .clear
        textView.isRichText = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.delegate = context.coordinator
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)

        textView.onHeightChange = {
            textView.invalidateIntrinsicContentSize()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textView.window?.makeFirstResponder(textView)
        }

        return textView
    }

    func updateNSView(_ nsView: AutoSizingTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
            nsView.invalidateIntrinsicContentSize()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: WrappingTextField

        init(_ parent: WrappingTextField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            var value = textView.string
            if value.count > parent.charLimit {
                value = String(value.prefix(parent.charLimit))
                textView.string = value
            }
            parent.text = value
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

private struct PixelBubble: View {
    let borderWidth: CGFloat
    let tailSize: CGFloat
    let fillColor: Color
    let borderColor: Color
    let shadowColor: Color

    var body: some View {
        Canvas { context, size in
            let b = borderWidth
            let t = tailSize

            // Shadow offset
            let sx: CGFloat = 2
            let sy: CGFloat = 2

            // --- Drop shadow (main box + tail) ---
            let shadowBody = CGRect(x: sx, y: sy, width: size.width, height: size.height)
            context.fill(Path(shadowBody), with: .color(shadowColor))

            // Shadow tail
            var shadowTail = Path()
            let stx = size.width - b * 4 + sx
            let sty = size.height + sy
            shadowTail.move(to: CGPoint(x: stx, y: sty - b))
            shadowTail.addLine(to: CGPoint(x: stx + t / 2, y: sty + t))
            shadowTail.addLine(to: CGPoint(x: stx + t, y: sty - b))
            shadowTail.closeSubpath()
            context.fill(shadowTail, with: .color(shadowColor))

            // --- Black border (outer rect) ---
            let outerRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            context.fill(Path(outerRect), with: .color(borderColor))

            // --- Parchment fill (inner rect) ---
            let innerRect = CGRect(x: b, y: b, width: size.width - b * 2, height: size.height - b * 2)
            context.fill(Path(innerRect), with: .color(fillColor))

            // --- Pixel corner cutouts (make it look pixelated) ---
            context.fill(Path(CGRect(x: 0, y: 0, width: b, height: b)), with: .color(.clear))
            context.fill(Path(CGRect(x: size.width - b, y: 0, width: b, height: b)), with: .color(.clear))
            context.fill(Path(CGRect(x: 0, y: size.height - b, width: b, height: b)), with: .color(.clear))
            context.fill(Path(CGRect(x: size.width - b, y: size.height - b, width: b, height: b)), with: .color(.clear))

            // --- Tail (bottom-right, pixel art style) ---
            let tx = size.width - b * 5
            let ty = size.height

            // Tail border (black)
            var tailBorder = Path()
            tailBorder.move(to: CGPoint(x: tx, y: ty - b))
            tailBorder.addLine(to: CGPoint(x: tx + t / 2, y: ty + t))
            tailBorder.addLine(to: CGPoint(x: tx + t + b, y: ty - b))
            tailBorder.closeSubpath()
            context.fill(tailBorder, with: .color(borderColor))

            // Tail fill (parchment)
            var tailFill = Path()
            tailFill.move(to: CGPoint(x: tx + b / 2, y: ty - b))
            tailFill.addLine(to: CGPoint(x: tx + t / 2, y: ty + t - b))
            tailFill.addLine(to: CGPoint(x: tx + t, y: ty - b))
            tailFill.closeSubpath()
            context.fill(tailFill, with: .color(fillColor))
        }
        .frame(width: nil, height: nil)
    }
}
