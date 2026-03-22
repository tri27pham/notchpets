import Foundation
import Supabase

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
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}
