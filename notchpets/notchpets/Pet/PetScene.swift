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

        // Pet sprite
        petNode = PetSpriteNode(species: speciesName)
        petNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        petNode.xScale = 2.0
        petNode.yScale = -2.0  // Negative to correct flipped texture from SKTexture(rect:in:)
        petNode.zPosition = 1
        addChild(petNode)

        petNode.setState(.idle)
    }

    func trigger(_ state: AnimationState) {
        petNode.setState(state)
    }
}
