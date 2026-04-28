
import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

    @State private var logoScale:      CGFloat = 0.75
    @State private var logoOpacity:    CGFloat = 0
    @State private var taglineOpacity: CGFloat = 0
    @State private var dotOpacity:     [CGFloat] = [0, 0, 0]

    var body: some View {
        ZStack {
            PremiumBackground()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ─────────────────────────────────────────
                VStack(spacing: 10) {
                    Image("credflow_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    HStack(spacing: 0) {
                        Text("Cred").font(.system(size: 20, weight: .thin))
                        Text("Flow").font(.system(size: 20, weight: .black))
                    }
                    .tracking(-0.3)
                    .foregroundStyle(.tertiary)
                    .opacity(taglineOpacity)
                }

                Spacer()

                // ── Loading dots ──────────────────────────────────
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.adaptiveBg(colorScheme))
                            .frame(width: 5, height: 5)
                            .opacity(dotOpacity[i])
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Logo pop in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        // Tagline fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            taglineOpacity = 1.0
        }
        // Dots cascade
        for i in 0..<3 {
            withAnimation(.easeInOut(duration: 0.4).delay(0.7 + Double(i) * 0.15)) {
                dotOpacity[i] = 1.0
            }
        }
        // Dots pulse loop
        pulseDots(delay: 1.3)
    }

    private func pulseDots(delay: Double) {
        for i in 0..<3 {
            withAnimation(.easeInOut(duration: 0.5).delay(delay + Double(i) * 0.15)) {
                dotOpacity[i] = dotOpacity[i] > 0.4 ? 0.2 : 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.9) {
            pulseDots(delay: 0)
        }
    }
}
