
import SwiftUI
import LocalAuthentication
internal import Auth

// MARK: - ProfileView

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Namespace private var langNS

    @State private var showChangePassword   = false
    @State private var showChangeEmail      = false
    @State private var faceIDEnabled        = BiometricService.shared.isEnabled
    @State private var showPasswordPrompt   = false
    @State private var promptPassword       = ""
    @State private var promptError: String? = nil
    @State private var promptLoading        = false
    @State private var appeared             = false
    @State private var editFirstName       = ""
    @State private var editLastName        = ""

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    private var initial: String {
        if !authService.firstName.isEmpty {
            return String(authService.firstName.prefix(1)).uppercased()
        }
        return authService.currentUser?.email?.prefix(1).uppercased() ?? "?"
    }

    private var displayName: String {
        let full = [authService.firstName, authService.lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return full.isEmpty ? (authService.currentUser?.email ?? "") : full
    }

    private var memberSince: String {
        guard let created = authService.currentUser?.createdAt else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        fmt.locale = loc.locale
        return fmt.string(from: created)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                ScrollView {
                    VStack(spacing: 28) {

                        // ── Hero Profile Card ────────────────────────
                        heroProfileSection
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)

                        // ── Personal Info ────────────────────────────
                        sectionCard(label: loc.t("profile.personalInfo")) {
                            nameRow(icon: "person", placeholder: loc.t("profile.firstName"), text: $editFirstName) {
                                authService.firstName = editFirstName
                            }
                            Divider().padding(.leading, 56)
                            nameRow(icon: "person.fill", placeholder: loc.t("profile.lastName"), text: $editLastName) {
                                authService.lastName = editLastName
                            }
                        }
                        .offset(y: appeared ? 0 : 25)
                        .opacity(appeared ? 1 : 0)

                        // ── Security ─────────────────────────────────
                        sectionCard(label: loc.t("profile.securityPrivacy")) {
                            settingsRow(icon: "lock.rotation", title: loc.t("profile.changePassword")) {
                                showChangePassword = true
                            }
                            Divider().padding(.leading, 56)
                            settingsRow(icon: "envelope", title: loc.t("profile.changeEmail")) {
                                showChangeEmail = true
                            }
                            if BiometricService.shared.isAvailable {
                                Divider().padding(.leading, 56)
                                toggleRow(
                                    icon: BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid",
                                    title: BiometricService.shared.biometricType == .faceID ? "Face ID" : "Touch ID",
                                    isOn: $faceIDEnabled
                                )
                                .onChange(of: faceIDEnabled) { _, enabled in
                                    if enabled {
                                        if KeychainService.shared.hasCredentials {
                                            BiometricService.shared.isEnabled = true
                                        } else {
                                            showPasswordPrompt = true
                                        }
                                    } else {
                                        BiometricService.shared.isEnabled = false
                                    }
                                }
                            }
                        }
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)

                        // ── Language ─────────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: loc.t("profile.language"))
                                .padding(.horizontal, 24)

                            HStack(spacing: 0) {
                                ForEach(AppLanguage.allCases) { lang in
                                    let isSelected = loc.currentLanguage == lang
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            loc.currentLanguage = lang
                                        }
                                    } label: {
                                        Text(lang.displayName)
                                            .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                                            .foregroundStyle(isSelected ? Color.adaptiveFg(colorScheme) : Color.adaptiveBg(colorScheme))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background {
                                                if isSelected {
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.adaptiveBg(colorScheme))
                                                        .padding(3)
                                                        .matchedGeometryEffect(id: "langPill", in: langNS)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 12, y: 3)
                            .padding(.horizontal, 24)
                        }
                        .offset(y: appeared ? 0 : 35)
                        .opacity(appeared ? 1 : 0)

                        // ── Information ──────────────────────────────
                        sectionCard(label: loc.t("profile.information")) {
                            infoRow(icon: "info.circle", title: loc.t("profile.version"),   value: appVersion)
                            Divider().padding(.leading, 56)
                            infoRow(icon: "iphone",      title: loc.t("profile.platform"),  value: "iOS")
                            Divider().padding(.leading, 56)
                            infoRow(icon: "building.2",  title: loc.t("profile.developer"), value: "CredFlow Inc.")
                        }
                        .offset(y: appeared ? 0 : 40)
                        .opacity(appeared ? 1 : 0)

                        // ── Sign out ─────────────────────────────────
                        Button {
                            Task { try? await authService.signOut() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                                Text(loc.t("profile.signOut"))
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .offset(y: appeared ? 0 : 45)
                        .opacity(appeared ? 1 : 0)
                    }
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text(loc.t("profile.my")).font(.system(size: 18, weight: .thin))
                        Text(loc.t("profile.profile")).font(.system(size: 18, weight: .black))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.close")) { dismiss() }
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
            if !BiometricService.shared.isEnabled { faceIDEnabled = false }
            promptPassword = ""; promptError = nil
        }) {
            faceIDPasswordPrompt
        }
        .task {
            editFirstName = authService.firstName
            editLastName = authService.lastName
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onChange(of: editFirstName) { _, val in authService.firstName = val }
        .onChange(of: editLastName)  { _, val in authService.lastName = val }
    }

    // MARK: - Hero Profile Card

    @ViewBuilder
    private var heroProfileSection: some View {
        VStack(spacing: 0) {
            // Avatar + name
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.adaptiveBg(colorScheme))
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.18), radius: 10, y: 4)
                    Text(initial)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.adaptiveFg(colorScheme))
                }

                VStack(spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if !authService.firstName.isEmpty {
                        Text(authService.currentUser?.email ?? "")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(loc.t("profile.activeAccount"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Stats row
            HStack(spacing: 0) {
                miniStat(
                    icon: "shield.checkered",
                    value: loc.t("profile.secured"),
                    label: loc.t("profile.account")
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 1, height: 36)

                miniStat(
                    icon: "calendar",
                    value: memberSince,
                    label: loc.t("profile.member")
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 1, height: 36)

                miniStat(
                    icon: "globe",
                    value: loc.currentLanguage.displayName,
                    label: loc.t("profile.language")
                )
            }
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark
                      ? Color(white: 0.13).opacity(0.7)
                      : Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.6),
                                    Color.white.opacity(colorScheme == .dark ? 0.04 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 20, y: 6)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 4, y: 2)
        )
    }

    @ViewBuilder
    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.adaptiveBg(colorScheme).opacity(0.08))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.adaptiveBg(colorScheme))
            }
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Face ID password prompt

    @ViewBuilder
    private var faceIDPasswordPrompt: some View {
        ZStack {
            PremiumBackground()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(cardBg)
                        .frame(width: 72, height: 72)
                        .shadow(color: .black.opacity(0.07), radius: 12, y: 3)
                    Image(systemName: BiometricService.shared.biometricType == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 32)

                VStack(spacing: 6) {
                    Text(loc.t(BiometricService.shared.biometricType == .faceID ? "profile.enableFaceID" : "profile.enableTouchID"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(loc.t("profile.faceIDPrompt"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                PremiumField(icon: "lock", isFocused: false) {
                    SecureField(loc.t("common.password"), text: $promptPassword)
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

                PremiumButton(title: loc.t("common.confirm"), isLoading: promptLoading) {
                    Task { await confirmFaceIDSetup() }
                }
                .padding(.horizontal, 24)

                Button(loc.t("common.cancel")) { showPasswordPrompt = false }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium])
    }

    private func confirmFaceIDSetup() async {
        guard !promptPassword.isEmpty else {
            promptError = loc.t("profile.enterPasswordError"); return
        }
        promptLoading = true; promptError = nil
        defer { promptLoading = false }
        do {
            let email = authService.currentUser?.email ?? ""
            try await authService.signIn(email: email, password: promptPassword)
            BiometricService.shared.isEnabled = true
            showPasswordPrompt = false
        } catch {
            promptError = loc.t("profile.wrongPassword")
            faceIDEnabled = false
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func sectionCard(label: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumSectionLabel(title: label)
                .padding(.horizontal, 24)
            VStack(spacing: 0) { rows() }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardBg)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 12, y: 3)
                )
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.adaptiveBg(colorScheme))
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
    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.adaptiveBg(colorScheme))
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
    private func nameRow(icon: String, placeholder: String, text: Binding<String>, onCommit: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.adaptiveBg(colorScheme).opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.adaptiveBg(colorScheme))
            }
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .submitLabel(.done)
                .onSubmit { onCommit() }
            if !text.wrappedValue.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.adaptiveBg(colorScheme).opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
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
    @Environment(LocalizationManager.self) private var loc
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
                            PremiumSectionLabel(title: loc.t("changePassword.newSection"))
                                .padding(.horizontal, 24)
                            VStack(spacing: 12) {
                                PremiumField(icon: "lock", isFocused: focusedField == .new) {
                                    SecureField(loc.t("changePassword.newPlaceholder"), text: $newPassword)
                                        .focused($focusedField, equals: .new)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .confirm }
                                }
                                PremiumField(icon: "lock.fill", isFocused: focusedField == .confirm) {
                                    SecureField(loc.t("changePassword.confirmPlaceholder"), text: $confirmPassword)
                                        .focused($focusedField, equals: .confirm)
                                        .submitLabel(.done)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        if let err = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                Text(err).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                        }

                        if success {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").font(.caption)
                                Text(loc.t("changePassword.success")).font(.caption)
                            }
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack(spacing: 0) {
                    Divider()
                    PremiumButton(title: loc.t("common.save"), isLoading: isLoading) {
                        Task { await changePassword() }
                    }
                    .padding(24)
                }
                .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
            }
        }
        .navigationTitle(loc.t("changePassword.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changePassword() async {
        guard !newPassword.isEmpty else {
            errorMessage = loc.t("changePassword.errorEmpty"); return
        }
        guard newPassword == confirmPassword else {
            errorMessage = loc.t("changePassword.errorMismatch"); return
        }
        guard newPassword.count >= 6 else {
            errorMessage = loc.t("changePassword.errorMinLength"); return
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
    @Environment(LocalizationManager.self) private var loc
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
                            PremiumSectionLabel(title: loc.t("changeEmail.currentSection"))
                                .padding(.horizontal, 24)
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
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                            )
                            .padding(.horizontal, 24)
                        }

                        // Nouvelle adresse
                        VStack(alignment: .leading, spacing: 10) {
                            PremiumSectionLabel(title: loc.t("changeEmail.newSection"))
                                .padding(.horizontal, 24)
                            PremiumField(icon: "envelope.badge", isFocused: focused) {
                                TextField(loc.t("changeEmail.newPlaceholder"), text: $newEmail)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focused)
                                    .submitLabel(.done)
                            }
                            .padding(.horizontal, 24)
                        }

                        if let err = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                Text(err).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                        }

                        if success {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").font(.caption)
                                Text(loc.t("changeEmail.success"))
                                    .font(.caption)
                                    .lineSpacing(2)
                            }
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack(spacing: 0) {
                    Divider()
                    PremiumButton(title: loc.t("changeEmail.updateButton"), isLoading: isLoading) {
                        Task { await changeEmail() }
                    }
                    .padding(24)
                }
                .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
            }
        }
        .navigationTitle(loc.t("changeEmail.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeEmail() async {
        guard !newEmail.isEmpty else {
            errorMessage = loc.t("changeEmail.errorEmpty"); return
        }
        guard newEmail.contains("@"), newEmail.contains(".") else {
            errorMessage = loc.t("changeEmail.errorInvalid"); return
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
