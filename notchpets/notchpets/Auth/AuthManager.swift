import Foundation
import Supabase
import Combine

@MainActor
final class AuthManager: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true

    private var authStateTask: Task<Void, Never>?

    var userId: UUID? { session?.user.id }
    var isSignedIn: Bool { session != nil }

    private var client: SupabaseClient { SupabaseManager.shared.client }

    init() {
        Task { await restoreSession() }
        listenForAuthChanges()
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Session

    private func restoreSession() async {
        do {
            session = try await client.auth.session
        } catch {
            // No existing session — sign in anonymously
            do {
                session = try await client.auth.signInAnonymously()
            } catch {
                print("[AuthManager] Anonymous sign-in failed: \(error.localizedDescription)")
                session = nil
            }
        }
        isLoading = false
    }

    private func listenForAuthChanges() {
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in client.auth.authStateChanges {
                guard !Task.isCancelled else { return }
                switch event {
                case .signedIn, .tokenRefreshed:
                    self.session = session
                case .signedOut:
                    self.session = nil
                default:
                    break
                }
            }
        }
    }

    // MARK: - Magic link

    func sendMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(email: email)
    }

    // MARK: - Sign out

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("[AuthManager] Sign out error: \(error.localizedDescription)")
        }
        session = nil
    }
}
