import Foundation
import Combine

/// Observes PetStore stats and triggers animations when thresholds are crossed.
/// - hunger < 20 → sad
/// - happiness < 20 → sleeping
/// - idle > 5 minutes → sleeping
/// - Recovery above 20 while in sad/sleeping → idle
@MainActor
final class PetStatMonitor: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var idleTimer: Timer?
    private let idleTimeout: TimeInterval = 5 * 60 // 5 minutes

    @Published private(set) var triggeredState: AnimationState?

    private weak var petStore: PetStore?

    init(petStore: PetStore) {
        self.petStore = petStore

        petStore.$myPet
            .compactMap { $0 }
            .sink { [weak self] pet in
                self?.evaluateStats(pet)
            }
            .store(in: &cancellables)

        resetIdleTimer()
    }

    private func evaluateStats(_ pet: Pet) {
        if pet.hunger < 20 {
            triggeredState = .sad
        } else if pet.happiness < 20 {
            triggeredState = .sleeping
        } else if triggeredState == .sad || triggeredState == .sleeping {
            // Stats recovered — clear the triggered state
            triggeredState = nil
        }
    }

    /// Call this whenever the user interacts with the pet to reset the idle timer.
    func recordInteraction() {
        resetIdleTimer()
        // If we were in idle-triggered sleep, clear it
        if triggeredState == .sleeping {
            if let pet = petStore?.myPet, pet.hunger >= 20 && pet.happiness >= 20 {
                triggeredState = nil
            }
        }
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.triggeredState = .sleeping
            }
        }
    }
}
