import Foundation
import Combine

@MainActor
final class PetStore: ObservableObject {
    @Published var myPet: Pet?
    @Published var partnerPet: Pet?

    private let myPetKey = "notchpets.myPet"
    private let decayInterval: TimeInterval = 30 * 60 // 30 minutes
    private var decayTimer: Timer?

    init() {
        load()
        startDecayTimer()
    }

    deinit {
        decayTimer?.invalidate()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: myPetKey),
           let pet = try? JSONDecoder().decode(Pet.self, from: data) {
            myPet = pet
        } else {
            let defaultPet = Pet(name: "Pingu", species: "penguin", background: "japan_background")
            save(defaultPet)
        }
    }

    func save(_ pet: Pet) {
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: myPetKey)
            myPet = pet
        }
    }

    func feed() {
        guard var pet = myPet else { return }
        pet.hunger = min(100, pet.hunger + 30)
        save(pet)
    }

    func play() {
        guard var pet = myPet else { return }
        pet.happiness = min(100, pet.happiness + 25)
        save(pet)
    }

    func catchBall() {
        guard var pet = myPet else { return }
        pet.happiness = min(100, pet.happiness + 10)
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

    // MARK: - Stat decay

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: decayInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.decay()
            }
        }
    }

    private func decay() {
        guard var pet = myPet else { return }
        pet.hunger = max(0, pet.hunger - 5)
        pet.happiness = max(0, pet.happiness - 3)
        save(pet)
    }
}
