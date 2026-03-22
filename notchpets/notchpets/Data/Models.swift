import Foundation

struct Pet: Codable, Identifiable {
    var id: UUID
    var pairId: UUID?
    var ownerId: UUID?
    var name: String
    var species: String
    var background: String
    var hunger: Int
    var happiness: Int
    var lastFed: Date?
    var lastPlayed: Date?
    var currentMessage: String?
    var messageSentAt: Date?
    var currentTrackName: String?
    var currentTrackArtist: String?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pairId = "pair_id"
        case ownerId = "owner_id"
        case name, species, background, hunger, happiness
        case lastFed = "last_fed"
        case lastPlayed = "last_played"
        case currentMessage = "current_message"
        case messageSentAt = "message_sent_at"
        case currentTrackName = "current_track_name"
        case currentTrackArtist = "current_track_artist"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        pairId: UUID? = nil,
        ownerId: UUID? = nil,
        name: String,
        species: String,
        background: String,
        hunger: Int = 100,
        happiness: Int = 100,
        lastFed: Date? = nil,
        lastPlayed: Date? = nil,
        currentMessage: String? = nil,
        messageSentAt: Date? = nil,
        currentTrackName: String? = nil,
        currentTrackArtist: String? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.pairId = pairId
        self.ownerId = ownerId
        self.name = name
        self.species = species
        self.background = background
        self.hunger = hunger
        self.happiness = happiness
        self.lastFed = lastFed
        self.lastPlayed = lastPlayed
        self.currentMessage = currentMessage
        self.messageSentAt = messageSentAt
        self.currentTrackName = currentTrackName
        self.currentTrackArtist = currentTrackArtist
        self.updatedAt = updatedAt
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

// MARK: - Pair

struct Pair: Codable, Identifiable {
    let id: UUID
    let userA: UUID
    let userB: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userA = "user_a"
        case userB = "user_b"
        case createdAt = "created_at"
    }
}

// MARK: - Invite

struct Invite: Codable, Identifiable {
    let id: UUID
    var code: String
    let creatorId: UUID
    let createdAt: Date?
    let expiresAt: Date?
    var accepted: Bool

    enum CodingKeys: String, CodingKey {
        case id, code, accepted
        case creatorId = "creator_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}
