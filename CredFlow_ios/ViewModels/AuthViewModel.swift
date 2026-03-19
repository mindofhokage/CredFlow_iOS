
import Foundation

@Observable
class AuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?

    func login(authService: AuthService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(authService: AuthService) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = LocalizationManager.shared.t("auth.fillAllFields")
            return
        }
        guard password == confirmPassword else {
            errorMessage = LocalizationManager.shared.t("auth.passwordsMismatch")
            return
        }
        guard password.count >= 6 else {
            errorMessage = LocalizationManager.shared.t("auth.passwordMinLength")
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
