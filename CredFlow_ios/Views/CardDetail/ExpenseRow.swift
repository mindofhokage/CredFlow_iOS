
import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    private var category: ExpenseCategory {
        ExpenseCategory(rawValue: expense.category) ?? .autre
    }

    private var formattedAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = Locale(identifier: "fr_CA")
        return f.string(from: NSNumber(value: expense.amount)) ?? "\(expense.amount)"
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(category: category)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}
