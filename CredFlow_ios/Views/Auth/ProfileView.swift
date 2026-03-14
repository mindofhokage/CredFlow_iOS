
import SwiftUI
import LocalAuthentication
internal import Auth

// MARK: - ProfileView

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showChangePassword   = false
    @State private var showChangeEmail      = false
    @State private var faceIDEnabled        = BiometricService.shared.isEnabled
    @State private var showPasswordPrompt   = false
    @State private var promptPassword       = ""
    @State private var promptError: String? = nil
    @State private var promptLoading        = false

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    private var initial: String {
        authService.currentUser?.email?.prefix(1).uppercased() ?? "?"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                ScrollView {
                    VStack(spacing: 28) {

                        // ── Hero header ───────────────────────────────
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                // Avatar with initial
                                ZStack {
                                    Circle()
                                        .fill(Color.adaptiveBg(colorScheme))
                                        .frame(width: 56, height: 56)
                                    Text(initial)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(Color.adaptiveFg(colorScheme))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(authService.currentUser?.email ?? "")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(Color.adaptiveBg(colorScheme))
                                            .frame(width: 6, height: 6)
                                        Text("Compte actif")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 12, y: 3)
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 4)

                        // ── Sécurité & Confidentialité ────────────────
                        sectionCard(label: "Sécurité & Confidentialité") {
                            settingsRow(icon: "lock.rotation", iconBg: Color.adaptiveBg(colorScheme),
                                        title: "Changer le mot de passe") {
                                showChangePassword = true
                            }
                            Divider().padding(.leading, 56)
                            settingsRow(icon: "envelope", iconBg: Color.adaptiveBg(colorScheme),
                                        title: "Changer l'adresse e-mail") {
                                showChangeEmail = true
                            }
                            if BiometricService.shared.isAvailable {
                                Divider().padding(.leading, 56)
                                toggleRow(
                                    icon: BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid",
                                    iconBg: Color.adaptiveBg(colorScheme),
                                    title: BiometricService.shared.biometricType == .faceID ? "Face ID" : "Touch ID",
                                    isOn: $faceIDEnabled
                                )
                                .onChange(of: faceIDEnabled) { _, enabled in
                                    if enabled {
                                        if KeychainService.shared.hasCredentials {
                                            BiometricService.shared.isEnabled = true
                                        } else {
                                            // Need credentials — ask for password
                                            showPasswordPrompt = true
                                        }
                                    } else {
                                        BiometricService.shared.isEnabled = false
                                    }
                                }
                            }
                        }

                        // ── Informations ──────────────────────────────
                        sectionCard(label: "Informations") {
                            infoRow(icon: "info.circle", title: "Version",     value: appVersion)
                            Divider().padding(.leading, 56)
                            infoRow(icon: "iphone",      title: "Plateforme",  value: "iOS")
                            Divider().padding(.leading, 56)
                            infoRow(icon: "building.2",  title: "Développeur", value: "CredFlow Inc.")
                        }

                        // ── Déconnexion ───────────────────────────────
                        Button {
                            Task { try? await authService.signOut() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Se déconnecter")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("Mon ").font(.system(size: 18, weight: .thin))
                        Text("Profil").font(.system(size: 18, weight: .black))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .tint(Color.adaptiveBg(colorScheme))
                }
            }
            .navigationDestination(isPresented: $showChangePassword) {
                ChangePasswordView().environment(authService)
            }
            .navigationDestination(isPresented: $showChangeEmail) {
                ChangeEmailView(currentEmail: authService.currentUser?.email ?? "")
                    .environment(authService)
            }
        }
        // ── Password prompt to activate Face ID ───────────────
        .sheet(isPresented: $showPasswordPrompt, onDismiss: {
            // If user dismissed without confirming, revert toggle
            if !BiometricService.shared.isEnabled { faceIDEnabled = false }
            promptPassword = ""; promptError = nil
        }) {
            faceIDPasswordPrompt
        }
    }

    // MARK: - Face ID password prompt

    @ViewBuilder
    private var faceIDPasswordPrompt: some View {
        ZStack {
            PremiumBackground()
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                        .frame(width: 72, height: 72)
                        .shadow(color: .black.opacity(0.07), radius: 12, y: 3)
                    Image(systemName: BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 32)

                VStack(spacing: 6) {
                    Text("Activer Face ID")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Entrez votre mot de passe pour sauvegarder vos identifiants de façon sécurisée.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                PremiumField(icon: "lock", isFocused: false) {
                    SecureField("Mot de passe", text: $promptPassword)
                        .textContentType(.password)
                        .submitLabel(.done)
                }
                .padding(.horizontal, 24)

                if let err = promptError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill").font(.caption)
                        Text(err).font(.caption)
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 28)
                }

                PremiumButton(title: "Confirmer", isLoading: promptLoading) {
                    Task { await confirmFaceIDSetup() }
                }
                .padding(.horizontal, 24)

                Button("Annuler") { showPasswordPrompt = false }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium])
    }

    private func confirmFaceIDSetup() async {
        guard !promptPassword.isEmpty else {
            promptError = "Veuillez entrer votre mot de passe."; return
        }
        promptLoading = true; promptError = nil
        defer { promptLoading = false }
        do {
            let email = authService.currentUser?.email ?? ""
            // Verify credentials by signing in
            try await authService.signIn(email: email, password: promptPassword)
            // signIn already saves to Keychain — now enable biometrics
            BiometricService.shared.isEnabled = true
            showPasswordPrompt = false
        } catch {
            promptError = "Mot de passe incorrect."
            faceIDEnabled = false
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func sectionCard(label: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumSectionLabel(title: label)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { rows() }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBg)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                )
                .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func settingsRow(icon: String, iconBg: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBg)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.adaptiveFg(colorScheme))
                }
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func toggleRow(icon: String, iconBg: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBg)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.adaptiveFg(colorScheme))
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.adaptiveBg(colorScheme))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - ChangePasswordView

struct ChangePasswordView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme

    @State private var newPassword     = ""
    @State private var confirmPassword = ""
    @State private var isLoading       = false
    @State private var errorMessage: String?
    @State private var success         = false
    @FocusState private var focusedField: Field?

    enum Field { case new, confirm }

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.92))
                                .frame(width: 72, height: 72)
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: "Nouveau mot de passe")
                                .padding(.horizontal, 20)
                            VStack(spacing: 12) {
                                PremiumField(icon: "lock", isFocused: focusedField == .new) {
                                    SecureField("Nouveau mot de passe", text: $newPassword)
                                        .focused($focusedField, equals: .new)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .confirm }
                                }
                                PremiumField(icon: "lock.fill", isFocused: focusedField == .confirm) {
                                    SecureField("Confirmer le mot de passe", text: $confirmPassword)
                                        .focused($focusedField, equals: .confirm)
                                        .submitLabel(.done)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if let err = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                Text(err).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }

                        if success {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").font(.caption)
                                Text("Mot de passe mis à jour avec succès.").font(.caption)
                            }
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack(spacing: 0) {
                    Divider()
                    PremiumButton(title: "Enregistrer", isLoading: isLoading) {
                        Task { await changePassword() }
                    }
                    .padding(20)
                }
                .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
            }
        }
        .navigationTitle("Mot de passe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changePassword() async {
        guard !newPassword.isEmpty else {
            errorMessage = "Veuillez entrer un nouveau mot de passe."; return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas."; return
        }
        guard newPassword.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères."; return
        }
        isLoading = true; errorMessage = nil; success = false
        defer { isLoading = false }
        do {
            try await authService.updatePassword(newPassword)
            success = true
            newPassword = ""; confirmPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ChangeEmailView

struct ChangeEmailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme

    let currentEmail: String

    @State private var newEmail     = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var success      = false
    @FocusState private var focused: Bool

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.92))
                                .frame(width: 72, height: 72)
                            Image(systemName: "envelope.badge")
                                .font(.system(size: 26, weight: .thin))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 16)

                        // Adresse actuelle
                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: "Adresse actuelle")
                                .padding(.horizontal, 20)
                            HStack(spacing: 14) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22)
                                Text(currentEmail)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 8, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Nouvelle adresse
                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: "Nouvelle adresse")
                                .padding(.horizontal, 20)
                            PremiumField(icon: "envelope.badge", isFocused: focused) {
                                TextField("Nouvelle adresse e-mail", text: $newEmail)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focused)
                                    .submitLabel(.done)
                            }
                            .padding(.horizontal, 20)
                        }

                        if let err = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                Text(err).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }

                        if success {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").font(.caption)
                                Text("Un lien de confirmation a été envoyé à votre nouvelle adresse.")
                                    .font(.caption)
                                    .lineSpacing(2)
                            }
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack(spacing: 0) {
                    Divider()
                    PremiumButton(title: "Mettre à jour", isLoading: isLoading) {
                        Task { await changeEmail() }
                    }
                    .padding(20)
                }
                .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
            }
        }
        .navigationTitle("Adresse e-mail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeEmail() async {
        guard !newEmail.isEmpty else {
            errorMessage = "Veuillez entrer une nouvelle adresse e-mail."; return
        }
        guard newEmail.contains("@"), newEmail.contains(".") else {
            errorMessage = "Adresse e-mail invalide."; return
        }
        isLoading = true; errorMessage = nil; success = false
        defer { isLoading = false }
        do {
            try await authService.updateEmail(newEmail)
            success = true
            newEmail = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
