
import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    @State private var vm = AuthViewModel()
    @State private var signUpSucceeded = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password, confirm }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                VStack(spacing: 0) {
                    if signUpSucceeded {
                        successView
                    } else {
                        formView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                        .tint(Color.adaptiveBg(colorScheme))
                }
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 48)

                    // Title
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("Cred")
                                .font(.system(size: 40, weight: .thin))
                            Text("Flow")
                                .font(.system(size: 40, weight: .black))
                        }
                        .tracking(-1)
                        Text(loc.t("signup.subtitle"))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Spacer().frame(height: 48)

                    VStack(spacing: 14) {
                        PremiumField(icon: "envelope", isFocused: focusedField == .email) {
                            TextField(loc.t("common.email"), text: $vm.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }

                        PremiumField(icon: "lock", isFocused: focusedField == .password) {
                            SecureField(loc.t("common.password"), text: $vm.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .confirm }
                        }

                        PremiumField(icon: "lock.fill", isFocused: focusedField == .confirm) {
                            SecureField(loc.t("signup.confirmPassword"), text: $vm.confirmPassword)
                                .focused($focusedField, equals: .confirm)
                                .submitLabel(.done)
                        }

                        if let err = vm.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(err).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Buttons pinned at bottom
            VStack(spacing: 12) {
                PremiumButton(title: loc.t("signup.createAccount"), isLoading: vm.isLoading) {
                    Task {
                        await vm.signUp(authService: authService)
                        if authService.currentUser != nil {
                            dismiss()
                        } else if vm.errorMessage == nil {
                            signUpSucceeded = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)
            .background(
                colorScheme == .dark
                    ? Color(white: 0.08).opacity(0.95)
                    : Color.white.opacity(0.95)
            )
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "envelope.badge.checkmark.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.adaptiveBg(colorScheme))
            Text(loc.t("signup.checkEmail"))
                .font(.title2).fontWeight(.bold)
            Text("\(loc.t("signup.confirmationSent")) **\(vm.email)**.\n\(loc.t("signup.clickAndReturn"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            PremiumButton(title: loc.t("signup.backToLogin")) { dismiss() }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}
