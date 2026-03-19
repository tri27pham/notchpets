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
}
