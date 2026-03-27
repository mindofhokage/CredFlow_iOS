
import SwiftUI

struct SpendingProgressBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    let spent: Double
    let limit: Double

    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(spent / limit, 1.0)
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = loc.locale
        return f
    }

    private func fmt(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.10))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.adaptiveBg(colorScheme))
                        .frame(width: max(geo.size.width * progress, 6), height: 6)
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(fmt(spent))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("\(loc.t("spending.outOf")) \(fmt(limit))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
