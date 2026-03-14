
import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = AuthViewModel()
    @State private var showSignUp = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 70)

                            // Logo
                            VStack(spacing: 6) {
                                HStack(spacing: 0) {
                                    Text("Cred")
                                        .font(.system(size: 52, weight: .thin))
                                    Text("Flow")
                                        .font(.system(size: 52, weight: .black))
                                }
                                .tracking(-1)

                                Text("Votre gestionnaire de crédit")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.3)
                            }

                            Spacer().frame(height: 60)

                            // Form card
                            VStack(spacing: 14) {
                                // Email
                                PremiumField(icon: "envelope", isFocused: focusedField == .email) {
                                    TextField("Adresse e-mail", text: $vm.email)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                }

                                // Password
                                PremiumField(icon: "lock", isFocused: focusedField == .password) {
                                    SecureField("Mot de passe", text: $vm.password)
                                        .textFieldStyle(.plain)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            Task { await vm.login(authService: authService) }
                                        }
                                }

                                // Error
                                if let err = vm.errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                        Text(err)
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal, 24)

                            Spacer().frame(height: 24)

                            // Se connecter
                            PremiumButton(title: "Se connecter", isLoading: vm.isLoading) {
                                Task { await vm.login(authService: authService) }
                            }
                            .padding(.horizontal, 24)

                            Spacer().frame(height: 32)

                            // Divider with text
                            HStack(spacing: 12) {
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                                Text("ou")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                            }
                            .padding(.horizontal, 24)

                            Spacer().frame(height: 24)

                            // Créer un compte
                            PremiumOutlineButton(title: "Créer un compte") {
                                showSignUp = true
                            }
                            .padding(.horizontal, 24)

                            Spacer().frame(height: 40)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Version
                    Text("CredFlow v\(appVersion)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 12)
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView().environment(authService)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
