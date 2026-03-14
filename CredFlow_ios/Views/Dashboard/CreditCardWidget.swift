
import SwiftUI

enum CardProvider {
    static func gradient(for provider: String) -> LinearGradient {
        let p = provider.lowercased()
        let colors: [Color]
        if p.contains("chase") {
            colors = [Color(red: 0.07, green: 0.36, blue: 0.73), Color(red: 0.02, green: 0.14, blue: 0.41)]
        } else if p.contains("amex") || p.contains("american express") {
            colors = [Color(red: 0.1, green: 0.55, blue: 0.35), Color(red: 0.02, green: 0.28, blue: 0.15)]
        } else if p.contains("capital") {
            colors = [Color(red: 0.75, green: 0.1, blue: 0.1), Color(red: 0.4, green: 0.02, blue: 0.02)]
        } else if p.contains("citi") {
            colors = [Color(red: 0.07, green: 0.36, blue: 0.73), Color(red: 0.05, green: 0.5, blue: 0.6)]
        } else if p.contains("wells") {
            colors = [Color(red: 0.75, green: 0.1, blue: 0.1), Color(red: 0.85, green: 0.4, blue: 0.05)]
        } else if p.contains("bank of") {
            colors = [Color(red: 0.02, green: 0.14, blue: 0.41), Color(red: 0.01, green: 0.05, blue: 0.25)]
        } else if p.contains("discover") {
            colors = [Color(red: 0.95, green: 0.5, blue: 0.0), Color(red: 0.8, green: 0.65, blue: 0.0)]
        } else if p.contains("usaa") {
            colors = [Color(red: 0.07, green: 0.36, blue: 0.73), Color(red: 0.3, green: 0.6, blue: 0.9)]
        } else if p.contains("apple") {
            colors = [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.05)]
        } else {
            colors = [Color(red: 0.35, green: 0.35, blue: 0.35), Color(red: 0.1, green: 0.1, blue: 0.1)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let presetProviders = [
        "Chase", "American Express", "Capital One", "Citi",
        "Wells Fargo", "Bank of America", "Discover", "USAA",
        "Barclays", "US Bank", "Navy Federal", "PNC",
        "TD Bank", "Synchrony", "Apple Card", "PayPal"
    ]
}

struct CreditCardWidget: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(CardProvider.gradient(for: card.provider))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 180)
                .offset(x: 90, y: -60)
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 140)
                .offset(x: -80, y: 70)

            VStack(alignment: .leading, spacing: 0) {
                // Top row: provider name + network
                HStack {
                    Text(card.provider)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    networkBadge
                }

                Spacer()

                // Card number
                Text("•••• •••• •••• \(card.lastFour)")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(2)

                Spacer()

                // Bottom row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TITULAIRE")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(card.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("LIMITE")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(formatLimit(card.creditLimit))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 343, height: 216)
    }

    @ViewBuilder
    private var networkBadge: some View {
        switch card.network {
        case .visa:
            Text("VISA")
                .font(.system(size: 18, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .italic()
        case .mastercard:
            HStack(spacing: -8) {
                Circle().fill(Color.red.opacity(0.85)).frame(width: 26, height: 26)
                Circle().fill(Color.orange.opacity(0.85)).frame(width: 26, height: 26)
            }
        case .amex:
            Text("AMEX")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.7), lineWidth: 1))
        }
    }

    private func formatLimit(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = Locale(identifier: "fr_CA")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
