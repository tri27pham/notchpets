import SpriteKit

class PetScene: SKScene {

    private var petNode: PetSpriteNode!
    private let backgroundName: String
    private let speciesName: String

    init(size: CGSize, species: String, background: String) {
        self.speciesName = species
        self.backgroundName = background
        super.init(size: size)
        scaleMode = .aspectFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true

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
        petNode = PetSpriteNode(species: speciesName)
        petNode.position = CGPoint(x: size.width / 2, y: size.height / 2.5)
        petNode.setScale(1.5)
        petNode.zPosition = 1
        addChild(petNode)

        petNode.setState(.idle)
    }

    func trigger(_ state: AnimationState) {
        petNode.setState(state)
    }
}
