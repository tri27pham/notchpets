import SpriteKit

class PetScene: SKScene {

    private var petNode: PetSpriteNode?
    private let backgroundName: String
    private let speciesName: String
    private(set) var currentAnimState: AnimationState = .idle

    /// Called when the scene needs to modify pet stats (e.g. double-tap → +happiness)
    var onInteraction: ((AnimationState) -> Void)?

    private var lastClickTime: TimeInterval = 0
    private let doubleClickThreshold: TimeInterval = 0.35

    init(size: CGSize, species: String, background: String) {
        self.speciesName = species
        self.backgroundName = background
        super.init(size: size)
        scaleMode = .aspectFill
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true

        // Guard against re-entry — SpriteView is recreated each expand cycle
        // but the scene persists in the @StateObject holder
        guard petNode == nil else { return }

        // Background image
        let bgTexture = SKTexture(imageNamed: backgroundName)
        bgTexture.filteringMode = .nearest
        let bgNode = SKSpriteNode(texture: bgTexture)
        bgNode.size = size
        bgNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bgNode.zPosition = -1
        addChild(bgNode)

        // Dark tint overlay to make the pet stand out
        let tint = SKSpriteNode(color: NSColor(white: 0, alpha: 0.4), size: size)
        tint.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tint.zPosition = 0
        addChild(tint)

        // Pet sprite
        let node = PetSpriteNode(species: speciesName)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2.5)
        node.setScale(1.5)
        node.zPosition = 1
        addChild(node)
        petNode = node

        node.setState(.idle)
    }

    // MARK: - Click handling

    override func mouseDown(with event: NSEvent) {
        let now = event.timestamp

        // Tap sleeping/sad pet → wake to idle
        if currentAnimState == .sleeping || currentAnimState == .sad {
            trigger(.idle)
            lastClickTime = now
            return
        }

        // Double-click detection
        if now - lastClickTime < doubleClickThreshold {
            trigger(.playing)
            onInteraction?(.playing)
            lastClickTime = 0 // reset so triple-click doesn't re-trigger
        } else {
            // Delay single-tap to allow double-click detection
            lastClickTime = now
            let capturedTime = now
            DispatchQueue.main.asyncAfter(deadline: .now() + doubleClickThreshold) { [weak self] in
                guard let self, self.lastClickTime == capturedTime else { return }
                self.trigger(.happy)
            }
        }
    }

    // MARK: - Animation triggers

    func trigger(_ state: AnimationState) {
        currentAnimState = state
        guard let petNode else { return }
        petNode.setState(state) { [weak self] in
            if self?.currentAnimState == state {
                self?.currentAnimState = .idle
            }
        }
    }
}
