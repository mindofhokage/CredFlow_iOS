
import SwiftUI

struct SpendingProgressBar: View {
    let spent: Double
    let limit: Double

    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(spent / limit, 1.0)
    }

    private var barColor: Color {
        switch progress {
        case ..<0.7:  return .green
        case ..<0.9:  return .orange
        default:       return .red
        }
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = Locale(identifier: "fr_CA")
        return f
    }

    private func fmt(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 10)

            HStack {
                Text(fmt(spent))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(barColor)
                Text("/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(fmt(limit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
