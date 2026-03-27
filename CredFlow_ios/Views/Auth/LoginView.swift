
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    @State private var vm            = AuthViewModel()
    @State private var showSignUp    = false
    @State private var isBioLoading  = false
    @State private var emailError    = false
    @State private var passwordError = false
    @State private var resetSent     = false
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
                GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

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
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                            radius: 16, y: 4)
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
                            Spacer().frame(height: 28)
                        }

                        // ── Form ─────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: loc.t("login.section"))
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                // Email field
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 15))
                                        .foregroundStyle(emailError ? .red : .secondary)
                                        .frame(width: 20)
                                    TextField(loc.t("common.email"), text: $vm.email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                        .onChange(of: vm.email) { emailError = false }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(cardBg)
                                .overlay(alignment: .bottom) {
                                    if emailError {
                                        Rectangle()
                                            .fill(Color.red.opacity(0.35))
                                            .frame(height: 1)
                                    } else {
                                        Divider().padding(.leading, 52)
                                    }
                                }

                                // Email inline error
                                if emailError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 10))
                                        Text(loc.t("common.email") + " " + loc.t("auth.fieldRequired"))
                                            .font(.system(size: 11))
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.05))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                // Password field
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 15))
                                        .foregroundStyle(passwordError ? .red : .secondary)
                                        .frame(width: 20)
                                    SecureField(loc.t("common.password"), text: $vm.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit { submitLogin() }
                                        .onChange(of: vm.password) { passwordError = false }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(cardBg)

                                // Password inline error
                                if passwordError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 10))
                                        Text(loc.t("common.password") + " " + loc.t("auth.fieldRequired"))
                                            .font(.system(size: 11))
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.05))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(
                                        emailError || passwordError
                                            ? Color.red.opacity(0.3)
                                            : (focusedField != nil ? Color.adaptiveBg(colorScheme).opacity(0.25) : Color.clear),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                    radius: 10, y: 2)
                            .animation(.easeInOut(duration: 0.2), value: emailError)
                            .animation(.easeInOut(duration: 0.2), value: passwordError)
                        }
                        .padding(.horizontal, 24)

                        // C — Mot de passe oublié
                        Button { handleForgotPassword() } label: {
                            Text(loc.t("login.forgotPassword"))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 28)
                        .padding(.top, 4)

                        // D — Bannière reset envoyé
                        if resetSent {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loc.t("login.resetSent"))
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(loc.t("login.resetSentSub"))
                                        .font(.system(size: 12))
                                        .opacity(0.85)
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.75)))
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                        }

                        // D — Bannière erreur Supabase
                        if let err = vm.errorMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 15))
                                Text(err)
                                    .font(.system(size: 13))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.88)))
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                        }

                        // Se connecter
                        PremiumButton(title: loc.t("login.signIn"), isLoading: vm.isLoading) {
                            submitLogin()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // A — Lien texte "Pas encore de compte?"
                        HStack(spacing: 4) {
                            Text(loc.t("login.noAccount"))
                                .foregroundStyle(.secondary)
                            Button { showSignUp = true } label: {
                                Text(loc.t("login.createAccountLink"))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.system(size: 14))
                        .padding(.top, 18)

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
                } // GeometryReader

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

    // MARK: - Forgot password

    private func handleForgotPassword() {
        let email = vm.email.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else {
            withAnimation { emailError = true }
            focusedField = .email
            return
        }
        Task {
            try? await authService.resetPassword(email: email)
            withAnimation { resetSent = true }
            try? await Task.sleep(for: .seconds(5))
            withAnimation { resetSent = false }
        }
    }

    // MARK: - Login

    private func submitLogin() {
        focusedField = nil
        withAnimation {
            emailError    = vm.email.trimmingCharacters(in: .whitespaces).isEmpty
            passwordError = vm.password.isEmpty
        }
        guard !emailError, !passwordError else { return }
        Task { await vm.login(authService: authService) }
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
