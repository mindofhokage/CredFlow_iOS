
import SwiftUI

struct CategoryBadge: View {
    let category: ExpenseCategory

    var body: some View {
        Image(systemName: category.icon)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )
    }
}
