
import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @Environment(\.colorScheme) private var colorScheme

    var onUnlocked: () -> Void

    @State private var isAuthenticating = false
    @State private var failed           = false

    private var iconName: String {
        BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid"
    }
    private var buttonTitle: String {
        BiometricService.shared.biometricType == .faceID
            ? "Déverrouiller avec Face ID"
            : "Déverrouiller avec Touch ID"
    }

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Cred").font(.system(size: 38, weight: .thin))
                        Text("Flow").font(.system(size: 38, weight: .black))
                    }
                    Text("Votre gestionnaire de crédit")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .tracking(0.3)
                }

                Spacer()

                // Icon + labels
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                            .frame(width: 88, height: 88)
                            .shadow(color: .black.opacity(0.07), radius: 16, y: 4)
                        Image(systemName: iconName)
                            .font(.system(size: 38, weight: .ultraLight))
                            .foregroundStyle(.primary)
                    }

                    VStack(spacing: 6) {
                        Text("Accès sécurisé")
                            .font(.system(size: 18, weight: .semibold))
                        Text(failed
                             ? "Authentification échouée. Réessayez."
                             : "Utilisez \(BiometricService.shared.biometricType == .faceID ? "Face ID" : "Touch ID") pour accéder à CredFlow")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                PremiumButton(title: buttonTitle, isLoading: isAuthenticating) {
                    Task { await tryUnlock() }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .task { await tryUnlock() }         // auto-prompt on appear
    }

    // MARK: - Logic

    private func tryUnlock() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        failed = false
        let ok = await BiometricService.shared.authenticate(reason: "Déverrouillez CredFlow")
        isAuthenticating = false
        if ok { onUnlocked() } else { failed = true }
    }
}
