
import SwiftUI

struct CategoryBadge: View {
    let category: ExpenseCategory
    var showLabel: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                    .font(.system(size: 18, weight: .semibold))
            }
            if showLabel {
                Text(category.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
