import Foundation
import Combine
import Supabase

@MainActor
final class PetStore: ObservableObject {
    @Published var myPet: Pet?
    @Published var partnerPet: Pet?

    private let myPetKey = "notchpets.myPet"
    private let decayInterval: TimeInterval = 30 * 60
    private var decayTimer: Timer?
    private var realtimeChannel: RealtimeChannelV2?
    private var syncTask: Task<Void, Never>?

    private var pairId: UUID?
    private var userId: UUID?

    // MARK: - Init

    init() {
        loadLocal()
        startDecayTimer()
    }

    deinit {
        decayTimer?.invalidate()
        syncTask?.cancel()
    }

    // MARK: - Connect to Supabase

    func connect(userId: UUID, pairId: UUID) {
        self.userId = userId
        self.pairId = pairId

        Task {
            await fetchRemotePets()
            subscribeToRealtime()
        }
    }

    func disconnect() {
        syncTask?.cancel()
        syncTask = nil

        Task {
            if let channel = realtimeChannel {
                await SupabaseManager.shared.client.realtimeV2.removeChannel(channel)
            }
        }

        realtimeChannel = nil
        userId = nil
        pairId = nil
        partnerPet = nil
    }

    // MARK: - Remote fetch

    private func fetchRemotePets() async {
        guard let pairId, let userId else { return }

        do {
            let pets = try await PetRepository.fetchPets(pairId: pairId)

            if let mine = pets.first(where: { $0.ownerId == userId }) {
                myPet = mine
                saveLocal(mine)
            } else if let local = myPet {
                // No remote pet yet — push local pet to Supabase
                var petToInsert = local
                petToInsert.pairId = pairId
                petToInsert.ownerId = userId
                let inserted = try await PetRepository.insertPet(petToInsert)
                myPet = inserted
                saveLocal(inserted)
            }

            partnerPet = pets.first(where: { $0.ownerId != userId })
        } catch {
            print("[PetStore] Failed to fetch remote pets: \(error)")
        }
    }

    // MARK: - Realtime

    private func subscribeToRealtime() {
        guard let pairId else { return }

        let channel = SupabaseManager.shared.client.realtimeV2.channel("pair:\(pairId.uuidString)")

        let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "pets", filter: "pair_id=eq.\(pairId.uuidString)")

        syncTask = Task { [weak self] in
            await channel.subscribe()

            for await change in changes {
                guard let self, !Task.isCancelled else { return }

                switch change {
                case .update(let action):
                    if let pet = try? action.decodeRecord(as: Pet.self, decoder: JSONDecoder.supabase) {
                        self.handleRemotePetUpdate(pet)
                    }
                case .insert(let action):
                    if let pet = try? action.decodeRecord(as: Pet.self, decoder: JSONDecoder.supabase) {
                        self.handleRemotePetUpdate(pet)
                    }
                default:
                    break
                }
            }
        }

        realtimeChannel = channel
    }

    private func handleRemotePetUpdate(_ pet: Pet) {
        if pet.ownerId == userId {
            myPet = pet
            saveLocal(pet)
        } else {
            partnerPet = pet
        }
    }

    // MARK: - Local persistence (offline fallback)

    private func loadLocal() {
        if let data = UserDefaults.standard.data(forKey: myPetKey),
           let pet = try? JSONDecoder().decode(Pet.self, from: data) {
            myPet = pet
        } else {
            let defaultPet = Pet(name: "Pingu", species: "penguin", background: "japan_background")
            saveLocal(defaultPet)
            myPet = defaultPet
        }
    }

    private func saveLocal(_ pet: Pet) {
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: myPetKey)
        }
    }

    // MARK: - Mutations

    func save(_ pet: Pet) {
        myPet = pet
        saveLocal(pet)
        pushUpdate(pet)
    }

    func feed() {
        guard var pet = myPet else { return }
        pet.hunger = min(100, pet.hunger + 30)
        pet.lastFed = Date()
        save(pet)
    }

    func play() {
        guard var pet = myPet else { return }
        pet.happiness = min(100, pet.happiness + 25)
        pet.lastPlayed = Date()
        save(pet)
    }

    func catchBall() {
        guard var pet = myPet else { return }
        pet.happiness = min(100, pet.happiness + 10)
        pet.lastPlayed = Date()
        save(pet)
    }

    func sendMessage(_ text: String) {
        guard var pet = myPet else { return }
        let trimmed = String(text.prefix(48))
        pet.currentMessage = trimmed.isEmpty ? nil : trimmed
        pet.messageSentAt = trimmed.isEmpty ? nil : Date()
        save(pet)
    }

    func updateName(_ name: String) {
        guard var pet = myPet else { return }
        pet.name = String(name.prefix(12))
        save(pet)
    }

    func updateSpecies(_ species: String) {
        guard var pet = myPet else { return }
        pet.species = species
        save(pet)
    }

    func updateBackground(_ background: String) {
        guard var pet = myPet else { return }
        pet.background = background
        save(pet)
    }

    func updateNowPlaying(track: String?, artist: String?) {
        guard var pet = myPet else { return }
        let changed = pet.currentTrackName != track || pet.currentTrackArtist != artist
        guard changed else { return }
        pet.currentTrackName = track
        pet.currentTrackArtist = artist
        save(pet)
    }

    // MARK: - Debug mock

    #if DEBUG
    func mockPartner() {
        partnerPet = Pet(
            name: "Mochi",
            species: "cat",
            background: "cafe_background",
            hunger: 72,
            happiness: 85,
            currentMessage: "miss u",
            messageSentAt: Date(),
            currentTrackName: "Glimpse of Us",
            currentTrackArtist: "Joji"
        )
    }

    func unmockPartner() {
        partnerPet = nil
    }
    #endif

    // MARK: - Push to Supabase

    private func pushUpdate(_ pet: Pet) {
        guard userId != nil else { return }

        Task {
            do {
                try await PetRepository.updatePet(id: pet.id, fields: [
                    "name": .string(pet.name),
                    "species": .string(pet.species),
                    "background": .string(pet.background),
                    "hunger": .double(Double(pet.hunger)),
                    "happiness": .double(Double(pet.happiness)),
                    "current_message": pet.currentMessage.map { .string($0) } ?? .null,
                    "message_sent_at": pet.messageSentAt.map { .string(ISO8601DateFormatter().string(from: $0)) } ?? .null,
                    "current_track_name": pet.currentTrackName.map { .string($0) } ?? .null,
                    "current_track_artist": pet.currentTrackArtist.map { .string($0) } ?? .null,
                    "last_fed": pet.lastFed.map { .string(ISO8601DateFormatter().string(from: $0)) } ?? .null,
                    "last_played": pet.lastPlayed.map { .string(ISO8601DateFormatter().string(from: $0)) } ?? .null,
                ])
            } catch {
                print("[PetStore] Failed to push update: \(error)")
            }
        }
    }

    // MARK: - Stat decay (local fallback when offline)

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: decayInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.decay()
            }
        }
    }

    private func decay() {
        // When connected, server-side cron handles decay
        guard userId == nil else { return }
        guard var pet = myPet else { return }
        pet.hunger = max(0, pet.hunger - 5)
        pet.happiness = max(0, pet.happiness - 3)
        myPet = pet
        saveLocal(pet)
    }
}

// MARK: - JSONDecoder extension for Supabase date handling

private extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = formatter.date(from: string) {
                return date
            }
            // Fallback without fractional seconds
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            if let date = basic.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(string)")
        }
        return decoder
    }()
}
