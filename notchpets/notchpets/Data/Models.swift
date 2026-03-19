import Foundation

struct Pet: Codable, Identifiable {
    var id: UUID
    var name: String
    var species: String
    var background: String
    var hunger: Int
    var happiness: Int

    init(id: UUID = UUID(), name: String, species: String, background: String, hunger: Int = 100, happiness: Int = 100) {
        self.id = id
        self.name = name
        self.species = species
        self.background = background
        self.hunger = hunger
        self.happiness = happiness
    }
}

extension Pet {
    enum Species: String, CaseIterable {
        case cat, dog, frog, panda, penguin, rabbit
    }

    enum Background: String, CaseIterable {
        case bedroom
        case rainy_window
        case forest
        case mount_fuji
        case cafe
        case beach
        case library
        case snowy_field
        case japan
    }
}
