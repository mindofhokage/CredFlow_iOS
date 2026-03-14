
import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = AuthViewModel()
    @State private var showSignUp = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    private var buttonFg: Color { colorScheme == .dark ? .black : .white }
    private var buttonBg: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle background gradient
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(white: 0.08), Color(white: 0.04)]
                        : [Color(white: 0.97), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Decorative blurred circles
                GeometryReader { geo in
                    Circle()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.04)
                              : Color.black.opacity(0.04))
                        .frame(width: 300)
                        .offset(x: geo.size.width * 0.5, y: -60)
                        .blur(radius: 40)
                    Circle()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.03)
                              : Color.black.opacity(0.03))
                        .frame(width: 250)
                        .offset(x: -60, y: geo.size.height * 0.6)
                        .blur(radius: 40)
                }
                .allowsHitTesting(false)

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
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    TextField("Adresse e-mail", text: $vm.email)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .password }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(colorScheme == .dark
                                              ? Color(white: 0.14)
                                              : Color.white)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                                radius: 8, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(focusedField == .email
                                                ? buttonBg.opacity(0.4)
                                                : Color.clear, lineWidth: 1.5)
                                )

                                // Password
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    SecureField("Mot de passe", text: $vm.password)
                                        .textFieldStyle(.plain)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            Task { await vm.login(authService: authService) }
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(colorScheme == .dark
                                              ? Color(white: 0.14)
                                              : Color.white)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                                radius: 8, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(focusedField == .password
                                                ? buttonBg.opacity(0.4)
                                                : Color.clear, lineWidth: 1.5)
                                )

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
                            Button {
                                Task { await vm.login(authService: authService) }
                            } label: {
                                ZStack {
                                    if vm.isLoading {
                                        ProgressView().tint(buttonFg)
                                    } else {
                                        Text("Se connecter")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(buttonFg)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(buttonBg)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: buttonBg.opacity(0.3), radius: 12, x: 0, y: 6)
                            }
                            .disabled(vm.isLoading)
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
                            Button {
                                showSignUp = true
                            } label: {
                                Text("Créer un compte")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(buttonBg)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(buttonBg.opacity(0.3), lineWidth: 1.5)
                                    )
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
