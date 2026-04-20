
import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

    var onUnlocked: () -> Void

    @State private var isAuthenticating = false
    @State private var failed           = false

    private var iconName: String {
        BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid"
    }
    private var buttonTitle: String {
        BiometricService.shared.biometricType == .faceID
            ? loc.t("biometric.unlockFaceID")
            : loc.t("biometric.unlockTouchID")
    }

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Image("credflow_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    HStack(spacing: 0) {
                        Text("Cred").font(.system(size: 22, weight: .thin))
                        Text("Flow").font(.system(size: 22, weight: .black))
                    }
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
                        Text(loc.t("biometric.secureAccess"))
                            .font(.system(size: 18, weight: .semibold))
                        Text(failed
                             ? loc.t("biometric.authFailed")
                             : (BiometricService.shared.biometricType == .faceID ? loc.t("biometric.useFaceIDAccess") : loc.t("biometric.useTouchIDAccess")))
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
        let ok = await BiometricService.shared.authenticate(reason: loc.t("biometric.unlockReason"))
        isAuthenticating = false
        if ok { onUnlocked() } else { failed = true }
    }
}
