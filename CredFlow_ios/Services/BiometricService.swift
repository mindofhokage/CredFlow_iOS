
import LocalAuthentication
import Foundation

final class BiometricService {
    static let shared = BiometricService()
    private init() {}

    private let enabledKey = "credflow_biometric_enabled"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var biometricType: LABiometryType {
        let ctx = LAContext()
        ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    /// Presents the system biometric prompt. Returns true on success.
    func authenticate(reason: String = "Accédez à CredFlow") async -> Bool {
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return false
        }
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                localizedReason: reason)
        } catch {
            return false
        }
    }
}
