
import SwiftUI

struct AppRootView: View {
    @State private var authService = AuthService()
    @State private var appState: AppState = .loading

    enum AppState { case loading, locked, transitioning, unlocked, unauthenticated }

    var body: some View {
        Group {
            switch appState {
            case .loading:
                SplashView()

            case .locked:
                BiometricLockView {
                    appState = .transitioning
                    Task {
                        try? await Task.sleep(for: .milliseconds(900))
                        withAnimation(.easeInOut(duration: 0.35)) { appState = .unlocked }
                    }
                }

            case .transitioning:
                TransitionView()

            case .unlocked:
                DashboardView()
                    .environment(authService)

            case .unauthenticated:
                LoginView()
                    .environment(authService)
            }
        }
        .onChange(of: authService.currentUser) { _, user in
            if user != nil, appState == .unauthenticated {
                // Coming from LoginView (session expired + biometric re-login)
                appState = .transitioning
                Task {
                    try? await Task.sleep(for: .milliseconds(900))
                    withAnimation(.easeInOut(duration: 0.35)) { appState = .unlocked }
                }
            } else if user == nil, appState != .loading {
                appState = .unauthenticated
            }
        }
        .task { await bootstrap() }
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        await authService.restoreSession()

        withAnimation(.easeInOut(duration: 0.4)) {
            if authService.currentUser != nil {
                appState = BiometricService.shared.isEnabled ? .locked : .unlocked
            } else {
                appState = .unauthenticated
            }
        }
    }
}
