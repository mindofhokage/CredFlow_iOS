
import SwiftUI

struct AppRootView: View {
    @State private var authService = AuthService()

    var body: some View {
        Group {
            if authService.currentUser != nil {
                DashboardView()
                    .environment(authService)
            } else {
                LoginView()
                    .environment(authService)
            }
        }
        .task {
            await authService.restoreSession()
        }
    }
}
