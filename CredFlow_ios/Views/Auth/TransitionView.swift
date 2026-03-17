
import SwiftUI

struct TransitionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    @State private var checkScale:   CGFloat = 0.4
    @State private var checkOpacity: CGFloat = 0
    @State private var ringScale:    CGFloat = 0.6
    @State private var ringOpacity:  CGFloat = 0

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Cred").font(.system(size: 38, weight: .thin))
                        Text("Flow").font(.system(size: 38, weight: .black))
                    }
                    Text(loc.t("app.tagline"))
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .tracking(0.3)
                }

                Spacer()

                // Animated checkmark
                ZStack {
                    // Expanding ring
                    Circle()
                        .stroke(Color.adaptiveBg(colorScheme).opacity(0.15), lineWidth: 1.5)
                        .frame(width: 80, height: 80)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Checkmark circle
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                            .frame(width: 72, height: 72)
                            .shadow(color: .black.opacity(0.07), radius: 16, y: 4)
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .thin))
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                    }
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            checkScale   = 1.0
            checkOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8)) {
            ringScale   = 1.4
            ringOpacity = 0
        }
    }
}
