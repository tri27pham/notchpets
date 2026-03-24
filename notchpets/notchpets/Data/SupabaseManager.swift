import Foundation
import Supabase
import Auth

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let plistURL = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: plistURL),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let urlString = dict["SUPABASE_URL"],
              let anonKey = dict["SUPABASE_ANON_KEY"],
              let url = URL(string: urlString)
        else {
            fatalError("Missing or invalid Config.plist — ensure SUPABASE_URL and SUPABASE_ANON_KEY are set")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    storage: UserDefaultsLocalStorage(),
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}

// MARK: - UserDefaults-based auth storage (avoids Keychain prompts)

private struct UserDefaultsLocalStorage: AuthLocalStorage {
    private let key = "supabase_session"

    func store(key: String, value: Data) throws {
        UserDefaults.standard.set(value, forKey: key)
    }

    func retrieve(key: String) throws -> Data? {
        UserDefaults.standard.data(forKey: key)
    }

    func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
