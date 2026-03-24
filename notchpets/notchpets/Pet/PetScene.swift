import SpriteKit

class PetScene: SKScene {

    private var petNode: PetSpriteNode?
    private var backgroundNode: SKSpriteNode?
    private var tintNode: SKSpriteNode?
    private var backgroundName: String
    private var speciesName: String
    private(set) var currentAnimState: AnimationState = .idle {
        didSet { onAnimationStateChanged?(currentAnimState) }
    }

    /// Called when the scene needs to modify pet stats (e.g. double-tap → +happiness)
    var onInteraction: ((AnimationState) -> Void)?
    /// Called whenever the animation state changes (used to disable buttons during animations)
    var onAnimationStateChanged: ((AnimationState) -> Void)?

    private var lastClickTime: TimeInterval = 0
    private let doubleClickThreshold: TimeInterval = 0.35

    init(size: CGSize, species: String, background: String) {
        self.speciesName = species
        self.backgroundName = background
        super.init(size: size)
        scaleMode = .resizeFill
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
        backgroundNode = bgNode

        // Dark tint overlay to make the pet stand out
        let tint = SKSpriteNode(color: NSColor(white: 0, alpha: 0.5), size: size)
        tint.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tint.zPosition = 0
        addChild(tint)
        tintNode = tint

        // Pet sprite
        let node = PetSpriteNode(species: speciesName)
        node.position = CGPoint(x: size.width / 2, y: size.height / 3)
        node.setScale(1.5)
        node.zPosition = 1
        addChild(node)
        petNode = node

        node.setState(.idle)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode?.size = size
        backgroundNode?.position = center
        tintNode?.size = size
        tintNode?.position = center
        petNode?.position = CGPoint(x: size.width / 2, y: size.height / 3)
    }

    // MARK: - Click handling

    override func mouseDown(with event: NSEvent) {
        guard !isThrowingBall else { return }

        let now = event.timestamp

        // Tap sleeping/sad pet → wake to idle
        if currentAnimState == .sleeping || currentAnimState == .sad {
            trigger(.idle)
            lastClickTime = now
            return
        }

        // Double-click detection
        if now - lastClickTime < doubleClickThreshold {
            let playAnim: AnimationState = Bool.random() ? .playing : .dancing
            trigger(playAnim)
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

    /// The state to return to after a one-shot animation finishes.
    var defaultState: AnimationState = .idle

    func trigger(_ state: AnimationState) {
        let wasListening = isListening
        if isListening {
            isListening = false
            petNode?.removeAllActions()
        }

        currentAnimState = state
        guard let petNode else { return }
        petNode.setState(state, fallback: defaultState) { [weak self] in
            guard let self, self.currentAnimState == state else { return }
            self.currentAnimState = self.defaultState
            if wasListening {
                self.startListening()
            }
        }
    }

    // MARK: - Music-driven listening

    private(set) var isListening = false {
        didSet { onListeningChanged?(isListening) }
    }
    var onListeningChanged: ((Bool) -> Void)?

    func startListening() {
        guard !isThrowingBall else { return }
        guard !isListening else { return }
        isListening = true
        defaultState = .headphones
        // Only switch immediately if idle; otherwise let the current animation
        // finish and it will return to defaultState (.headphones) on completion.
        if currentAnimState == .idle {
            currentAnimState = .headphones
            petNode?.setState(.headphones)
        }
    }

    func stopListening() {
        guard isListening else { return }
        isListening = false
        defaultState = .idle
        currentAnimState = .idle
        petNode?.setState(.idle)
    }

    // MARK: - Reset (cancel all animations, reposition)

    func resetToIdle() {
        // Remove extra nodes (ball, etc.) — iterate a snapshot of children
        for node in children where node !== petNode && node !== backgroundNode && node !== tintNode {
            node.removeAllActions()
            node.removeFromParent()
        }

        // Cancel all pet actions (walk, throw sequence, etc.)
        petNode?.removeAllActions()

        // Reset state flags
        isThrowingBall = false
        isListening = false
        defaultState = .idle
        currentAnimState = .idle

        // Reposition pet to center
        petNode?.position = CGPoint(x: size.width / 2, y: size.height / 3)
        petNode?.xScale = abs(petNode?.xScale ?? 1.5)

        // Restart idle animation
        petNode?.setState(.idle)
    }

    // MARK: - Update species / background

    func updateSpecies(_ newSpecies: String) {
        guard newSpecies != speciesName else { return }
        speciesName = newSpecies
        guard let oldNode = petNode else { return }
        let pos = oldNode.position
        let scale = oldNode.xScale
        let zPos = oldNode.zPosition
        oldNode.removeFromParent()

        let node = PetSpriteNode(species: newSpecies)
        node.position = pos
        node.setScale(abs(scale))
        node.zPosition = zPos
        addChild(node)
        petNode = node
        currentAnimState = .idle
        node.setState(.idle)
    }

    func updateBackground(_ newBackground: String) {
        guard newBackground != backgroundName else { return }
        backgroundName = newBackground
        guard let oldBg = backgroundNode else { return }
        let bgTexture = SKTexture(imageNamed: newBackground)
        bgTexture.filteringMode = .nearest
        oldBg.texture = bgTexture
    }

    // MARK: - Throw ball sequence

    private(set) var isThrowingBall = false {
        didSet { onThrowingBallChanged?(isThrowingBall) }
    }
    var onThrowingBallChanged: ((Bool) -> Void)?

    func throwBall() {
        guard let petNode, !isThrowingBall else { return }
        let wasListening = isListening
        if isListening {
            isListening = false
        }
        isThrowingBall = true
        currentAnimState = .idle
        petNode.setState(.idle)

        let restPosition = petNode.position
        let ballSize: CGFloat = 20
        let groundY = restPosition.y - 25

        // Randomize: ball comes from left or right
        let fromLeft = Bool.random()
        let margin: CGFloat = 0.15
        let landX = CGFloat.random(in: size.width * margin ... size.width * (1 - margin))

        // Ball starts off-screen on the chosen side
        let startX = fromLeft ? -ballSize : size.width + ballSize
        let startY = CGFloat.random(in: size.height * 0.5 ... size.height * 0.8)

        // Create animated ball from spritesheet (256x64, 4 frames of 64x64)
        // Same UV-slicing approach as PetSpriteNode
        let sheetTexture = SKTexture(imageNamed: "ball_spritesheet")
        sheetTexture.filteringMode = .nearest
        let totalCols = 4
        let frameW: CGFloat = 1.0 / CGFloat(totalCols)
        var ballFrames: [SKTexture] = []
        for col in 0..<totalCols {
            let rect = CGRect(
                x: CGFloat(col) * frameW,
                y: 0,
                width: frameW,
                height: 1.0
            )
            let tex = SKTexture(rect: rect, in: sheetTexture)
            tex.filteringMode = .nearest
            ballFrames.append(tex)
        }
        let firstFrame = ballFrames[0]
        let ball = SKSpriteNode(texture: firstFrame, size: CGSize(width: ballSize, height: ballSize))
        ball.zPosition = 2
        ball.position = CGPoint(x: startX, y: startY)
        addChild(ball)

        // Animate ball frames in a loop
        let ballAnimate = SKAction.animate(with: ballFrames, timePerFrame: 0.1, resize: false, restore: false)
        ball.run(SKAction.repeatForever(ballAnimate), withKey: "ballSpin")

        // Arc control point — high above, between start and land
        let controlX = (startX + landX) / 2
        let controlY = size.height + CGFloat.random(in: 10 ... 40)

        // 1. Ball arcs in from off-screen to ground
        let ballPath = CGMutablePath()
        ballPath.move(to: ball.position)
        ballPath.addQuadCurve(
            to: CGPoint(x: landX, y: groundY),
            control: CGPoint(x: controlX, y: controlY)
        )
        let ballArc = SKAction.follow(ballPath, asOffset: false, orientToPath: false, duration: 0.6)
        ballArc.timingMode = .easeIn

        let ballFly = ballArc

        // 2. Bouncing sequence — each bounce is smaller and shorter
        var bounceActions: [SKAction] = []
        let bounceHeights: [CGFloat] = [18, 9, 4]
        let bounceDurations: [Double] = [0.25, 0.18, 0.12]
        let driftPerBounce: CGFloat = (fromLeft ? 1 : -1) * 3

        for i in 0..<bounceHeights.count {
            let up = SKAction.moveBy(x: driftPerBounce, y: bounceHeights[i], duration: bounceDurations[i])
            up.timingMode = .easeOut
            let down = SKAction.moveBy(x: driftPerBounce, y: -bounceHeights[i], duration: bounceDurations[i])
            down.timingMode = .easeIn
            bounceActions.append(SKAction.sequence([up, down]))
        }
        let bounceSequence = SKAction.sequence(bounceActions)

        // Ball: fly in, then bounce
        let fullBallAction = SKAction.sequence([ballFly, bounceSequence])

        // Final ball resting position after bounces
        let totalDrift = driftPerBounce * 2 * CGFloat(bounceHeights.count)
        let ballRestX = landX + totalDrift

        // Pet walks slowly to ball after it stops
        let petSpeed: CGFloat = 40 // points per second
        let runDistance = abs(ballRestX - restPosition.x)
        let walkDuration = Double(runDistance / petSpeed)

        // Flip pet to face the ball
        let petFacesLeft = ballRestX < restPosition.x
        if petFacesLeft {
            petNode.xScale = -abs(petNode.xScale)
        } else {
            petNode.xScale = abs(petNode.xScale)
        }

        // Execute: ball flies + bounces, then pet walks over
        ball.run(fullBallAction) { [weak self] in
            guard let self, self.isThrowingBall, let petNode = self.petNode else { return }

            // Pet walks to ball
            self.currentAnimState = .run
            petNode.setState(.run)
            let walkTo = SKAction.move(to: CGPoint(x: ballRestX, y: restPosition.y), duration: walkDuration)
            walkTo.timingMode = .easeInEaseOut

            petNode.run(walkTo) { [weak self] in
                guard let self, self.isThrowingBall, let petNode = self.petNode else { return }

                // Pick up ball
                ball.removeAllActions()
                ball.removeFromParent()
                self.currentAnimState = .catchBall
                petNode.setState(.catchBall) { [weak self] in
                    guard let self, self.isThrowingBall, let petNode = self.petNode else { return }

                    // Flip to face back toward center
                    let goingLeft = restPosition.x < ballRestX
                    if goingLeft {
                        petNode.xScale = -abs(petNode.xScale)
                    } else {
                        petNode.xScale = abs(petNode.xScale)
                    }

                    // Walk back to center
                    self.currentAnimState = .run
                    petNode.setState(.run)
                    let walkBackDuration = Double(runDistance / petSpeed)
                    let walkBack = SKAction.move(to: restPosition, duration: walkBackDuration)
                    walkBack.timingMode = .easeInEaseOut

                    petNode.run(walkBack) { [weak self] in
                        guard let self, self.isThrowingBall, let petNode = self.petNode else { return }
                        petNode.xScale = abs(petNode.xScale)
                        self.currentAnimState = .idle
                        petNode.setState(.idle)
                        self.isThrowingBall = false
                        self.onInteraction?(.catchBall)
                        if wasListening {
                            self.startListening()
                        }
                    }
                }
            }
        }
    }
}
