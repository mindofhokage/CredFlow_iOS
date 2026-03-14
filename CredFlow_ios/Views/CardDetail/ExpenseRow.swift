
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
                .opacity(expense.isPaid ? 0.35 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(expense.isPaid)
                    .foregroundStyle(expense.isPaid ? .secondary : .primary)
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                if expense.isPaid {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(expense.isPaid)
                    .foregroundStyle(expense.isPaid ? .secondary : .primary)
            }
        }
        .padding(.vertical, 2)
    }
}
