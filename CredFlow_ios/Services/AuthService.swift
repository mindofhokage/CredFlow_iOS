
import Foundation
import Supabase

@Observable
class AuthService {
    var currentUser: User? = nil
    var isLoading = false
    var errorMessage: String? = nil

    private var client: SupabaseClient { SupabaseManager.shared.client }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let response = try await client.auth.signUp(email: email, password: password)
        currentUser = response.user
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
    }

    func restoreSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
        } catch {
            currentUser = nil
        }
    }
}
