import Foundation
import Supabase

enum PetRepository {
    private static var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Pets

    static func fetchPets(pairId: UUID) async throws -> [Pet] {
        try await client
            .from("pets")
            .select()
            .eq("pair_id", value: pairId.uuidString)
            .execute()
            .value
    }

    static func insertPet(_ pet: Pet) async throws -> Pet {
        try await client
            .from("pets")
            .insert(pet)
            .select()
            .single()
            .execute()
            .value
    }

    static func updatePet(id: UUID, fields: [String: AnyJSON]) async throws {
        try await client
            .from("pets")
            .update(fields)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Pairs

    static func fetchPair(userId: UUID) async throws -> Pair? {
        let pairs: [Pair] = try await client
            .from("pairs")
            .select()
            .or("user_a.eq.\(userId.uuidString),user_b.eq.\(userId.uuidString)")
            .limit(1)
            .execute()
            .value
        return pairs.first
    }

    // MARK: - Invites

    static func createInvite(creatorId: UUID) async throws -> Invite {
        let code = generateInviteCode()
        let invite = Invite(
            id: UUID(),
            code: code,
            creatorId: creatorId,
            createdAt: nil,
            expiresAt: nil,
            accepted: false
        )
        return try await client
            .from("invites")
            .insert(invite)
            .select()
            .single()
            .execute()
            .value
    }

    static func acceptInvite(code: String, acceptorId: UUID) async throws -> Pair {
        // Fetch the invite
        let invites: [Invite] = try await client
            .from("invites")
            .select()
            .eq("code", value: code.uppercased())
            .eq("accepted", value: false)
            .execute()
            .value

        guard let invite = invites.first else {
            throw PairError.invalidCode
        }

        guard invite.creatorId != acceptorId else {
            throw PairError.cannotPairWithSelf
        }

        // Mark invite as accepted
        try await client
            .from("invites")
            .update(["accepted": AnyJSON.bool(true)])
            .eq("id", value: invite.id.uuidString)
            .execute()

        // Create the pair
        let pair: Pair = try await client
            .from("pairs")
            .insert([
                "user_a": AnyJSON.string(invite.creatorId.uuidString),
                "user_b": AnyJSON.string(acceptorId.uuidString),
            ])
            .select()
            .single()
            .execute()
            .value

        return pair
    }

    private static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

enum PairError: LocalizedError {
    case invalidCode
    case cannotPairWithSelf

    var errorDescription: String? {
        switch self {
        case .invalidCode: "Invalid or expired invite code"
        case .cannotPairWithSelf: "You can't pair with yourself"
        }
    }
}
