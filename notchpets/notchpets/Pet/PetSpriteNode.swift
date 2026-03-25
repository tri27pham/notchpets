import SpriteKit

class PetSpriteNode: SKSpriteNode {

    private let totalCols = 6
    private let totalRows = 11
    private var framesByState: [AnimationState: [SKTexture]] = [:]
    private var currentState: AnimationState = .idle
    private var manifest: [AnimationState: AnimationDef] = [:]

    init(species: String) {
        // Load as a plain texture — NOT an atlas, which would repack and break UV slicing
        let sheetTexture = SKTexture(imageNamed: "\(species)_spritesheet")
        sheetTexture.filteringMode = .nearest

        let frameW = 1.0 / CGFloat(totalCols)
        let frameH = 1.0 / CGFloat(totalRows)

        // Slice frames for each animation state
        self.manifest = getManifest(for: species)
        for state in AnimationState.allCases {
            guard let def = manifest[state] else { continue }
            var frames: [SKTexture] = []
            let rowFromBottom = (totalRows - 1) - def.row
            for col in 0..<def.frameCount {
                let rect = CGRect(
                    x: CGFloat(col) * frameW,
                    y: CGFloat(rowFromBottom) * frameH,
                    width: frameW,
                    height: frameH
                )
                let tex = SKTexture(rect: rect, in: sheetTexture)
                tex.filteringMode = .nearest
                frames.append(tex)
            }
            framesByState[state] = frames
        }

        // Init with the first idle frame
        let firstFrame = framesByState[.idle]?.first ?? sheetTexture
        super.init(texture: firstFrame, color: .clear, size: firstFrame.size())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setState(_ state: AnimationState, fallback: AnimationState = .idle, onComplete: (() -> Void)? = nil) {
        guard let frames = framesByState[state],
              let def = manifest[state] else { return }

        currentState = state
        removeAllActions()

        let timePerFrame = 1.0 / Double(def.fps)
        let animateAction = SKAction.animate(with: frames, timePerFrame: timePerFrame)

        if def.loops {
            run(SKAction.repeatForever(animateAction), withKey: "animation")
        } else {
            var sequence: [SKAction] = [animateAction]
            if def.holdLastFrame > 0 {
                sequence.append(SKAction.wait(forDuration: def.holdLastFrame))
            }
            run(SKAction.sequence(sequence)) { [weak self] in
                onComplete?()
                if self?.currentState == state {
                    self?.setState(fallback)
                }
            }
        }
    }
}
