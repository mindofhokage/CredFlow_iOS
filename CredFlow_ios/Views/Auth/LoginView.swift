
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    @State private var vm           = AuthViewModel()
    @State private var showSignUp   = false
    @State private var isBioLoading = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    private var canUseBiometrics: Bool {
        BiometricService.shared.isAvailable && KeychainService.shared.hasCredentials
    }
    private var biometricLabel: String {
        BiometricService.shared.biometricType == .faceID ? loc.t("login.continueFaceID") : loc.t("login.continueTouchID")
    }
    private var biometricIcon: String {
        BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid"
    }
    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {

                        // ── Logo ─────────────────────────────────────────
                        VStack(spacing: 6) {
                            HStack(spacing: 0) {
                                Text("Cred").font(.system(size: 48, weight: .thin))
                                Text("Flow").font(.system(size: 48, weight: .black))
                            }
                            .tracking(-0.5)
                            Text(loc.t("app.tagline"))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.tertiary)
                                .tracking(0.4)
                        }
                        .padding(.top, 72)

                        // ── Face ID ───────────────────────────────────────
                        if canUseBiometrics {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(cardBg)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.07),
                                                radius: 14, y: 4)
                                    Image(systemName: biometricIcon)
                                        .font(.system(size: 32, weight: .ultraLight))
                                        .foregroundStyle(.primary)
                                }

                                VStack(spacing: 4) {
                                    Text(loc.t("login.quickAccess"))
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(BiometricService.shared.biometricType == .faceID ? loc.t("login.useFaceIDInstant") : loc.t("login.useTouchIDInstant"))
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }

                                PremiumButton(title: biometricLabel, isLoading: isBioLoading) {
                                    Task { await biometricLogin() }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                            radius: 12, y: 3)
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 44)

                            // Divider
                            HStack(spacing: 14) {
                                Rectangle().fill(Color.secondary.opacity(0.18)).frame(height: 1)
                                Text(loc.t("common.or"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.tertiary)
                                    .tracking(0.5)
                                Rectangle().fill(Color.secondary.opacity(0.18)).frame(height: 1)
                            }
                            .padding(.horizontal, 36)
                            .padding(.top, 28)
                            .padding(.bottom, 20)

                        } else {
                            Spacer().frame(height: 52)
                        }

                        // ── Form ─────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: loc.t("login.section"))
                                .padding(.horizontal, 4)

                            VStack(spacing: 1) {
                                // Email field
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    TextField(loc.t("common.email"), text: $vm.email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(cardBg)

                                Divider().padding(.leading, 52)

                                // Password field
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    SecureField(loc.t("common.password"), text: $vm.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit { Task { await vm.login(authService: authService) } }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(cardBg)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        focusedField != nil
                                            ? Color.adaptiveBg(colorScheme).opacity(0.25)
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                    radius: 10, y: 2)
                        }
                        .padding(.horizontal, 24)

                        // Error
                        if let err = vm.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                Text(err).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                            .padding(.top, 10)
                        }

                        // Se connecter
                        PremiumButton(title: loc.t("login.signIn"), isLoading: vm.isLoading) {
                            Task { await vm.login(authService: authService) }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // Créer un compte
                        PremiumOutlineButton(title: loc.t("login.createAccount")) { showSignUp = true }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)

                        Spacer().frame(height: 48)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                // Version
                Text("CredFlow v\(appVersion)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 14)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView().environment(authService)
        }
        .task {
            if canUseBiometrics { await biometricLogin() }
        }
    }

    // MARK: - Biometric login

    private func biometricLogin() async {
        guard !isBioLoading else { return }
        isBioLoading = true
        defer { isBioLoading = false }
        let ok = await BiometricService.shared.authenticate(reason: loc.t("biometric.accessReason"))
        guard ok, let creds = KeychainService.shared.load() else { return }
        try? await authService.signIn(email: creds.email, password: creds.password)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
