
import Foundation
import Supabase

@Observable
@MainActor
class AuthService {
    var currentUser: User? = nil
    var isLoading        = false
    var errorMessage: String? = nil

    var firstName: String {
        get { UserDefaults.standard.string(forKey: "credflow_first_name") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "credflow_first_name") }
    }

    var lastName: String {
        get { UserDefaults.standard.string(forKey: "credflow_last_name") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "credflow_last_name") }
    }

    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
        // Always persist credentials so Face ID can re-authenticate on session expiry
        KeychainService.shared.save(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        let response = try await client.auth.signUp(email: email, password: password)
        currentUser = response.user
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        KeychainService.shared.delete()
        BiometricService.shared.isEnabled = false
        CacheService.clearAll()
    }

    func restoreSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
        } catch {
            currentUser = nil
        }
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func updatePassword(_ newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    func updateEmail(_ newEmail: String) async throws {
        try await client.auth.update(user: UserAttributes(email: newEmail))
    }
}
