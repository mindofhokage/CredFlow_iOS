
import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = "io.credflow.app"
    private let account = "user_credentials"

    struct Credentials: Codable {
        let email: String
        let password: String
    }

    // MARK: - Public API

    var hasCredentials: Bool {
        SecItemCopyMatching([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary, nil) == errSecSuccess
    }

    func save(email: String, password: String) {
        guard let data = try? JSONEncoder().encode(Credentials(email: email, password: password)) else { return }
        // Remove any existing item first
        SecItemDelete([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
        // Add new item — accessible when device is unlocked, not backed up to iCloud
        SecItemAdd([
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as CFDictionary, nil)
    }

    func load() -> Credentials? {
        var result: AnyObject?
        guard SecItemCopyMatching([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ] as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    func delete() {
        SecItemDelete([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
    }
}
