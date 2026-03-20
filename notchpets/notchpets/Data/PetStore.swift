import Foundation
import Combine

@MainActor
final class PetStore: ObservableObject {
    @Published var myPet: Pet?
    @Published var partnerPet: Pet?

    private let myPetKey = "notchpets.myPet"

    init() {
        load()
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
}
