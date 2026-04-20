
import SwiftUI

enum CardProvider {
    static let presetProviders = [
        "Chase", "American Express", "Capital One", "Citi",
        "Wells Fargo", "Bank of America", "Discover", "USAA",
        "BNC", "RBC", "TD", "Desjardins",
        "Barclays", "US Bank", "Apple Card", "PayPal"
    ]

    // 3 tons neutres : sombre, moyen, clair
    static let colorVariants: [(top: Color, bottom: Color)] = [
        (Color(white: 0.38), Color(white: 0.24)),  // 0 — Sombre
        (Color(white: 0.54), Color(white: 0.40)),  // 1 — Moyen
        (Color(white: 0.70), Color(white: 0.56))   // 2 — Clair
    ]

    static func cardGradient(for index: Int) -> LinearGradient {
        let variant = colorVariants[min(index, colorVariants.count - 1)]
        return LinearGradient(
            colors: [variant.top, variant.bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CreditCardWidget: View {
    @Environment(LocalizationManager.self) private var loc
    let card: Card

    var body: some View {
        ZStack(alignment: .topLeading) {

            // ── Fond mat uniforme
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    CardProvider.cardGradient(for: card.colorIndex)
                )

            // ── Contenu
            VStack(alignment: .leading, spacing: 0) {

                // Provider (haut gauche)
                Text(card.provider.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.55))
                    .tracking(2.5)
                    .lineLimit(1)

                Spacer()

                // Puce EMV
                chipView

                Spacer()

                // Numéro de carte (centré verticalement)
                Text("••••  ••••  ••••  \(card.lastFour)")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.80))
                    .tracking(2)

                Spacer()

                // Ligne bas
                HStack(alignment: .bottom) {
                    Text(card.name.uppercased())
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(2.5)
                        .lineLimit(1)
                    Spacer()
                    networkBadge
                }
            }
            .padding(24)

            // ── Edge bevel (bordure métal) ──────────────────────
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.20), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .frame(width: 343, height: 216)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.20), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.30), radius: 28, x: 0, y: 14)
    }

    // MARK: - Puce EMV

    private var chipView: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.72), Color(white: 0.52)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 26)
            .overlay(
                ZStack {
                    VStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.12))
                                .frame(height: 0.6)
                        }
                    }
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(width: 0.6)
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.black.opacity(0.10), lineWidth: 0.6)
                        .frame(width: 12, height: 14)
                }
                .padding(5)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    // MARK: - Logo réseau

    @ViewBuilder
    private var networkBadge: some View {
        switch card.network {
        case .visa:
            Image("visa_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 32)

        case .mastercard:
            Image("mastercard_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 32)

        case .amex:
            Image("amex_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Formatter

    private func formatLimit(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = loc.locale
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
