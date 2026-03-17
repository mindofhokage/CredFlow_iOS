
import Foundation

@Observable
class AddExpenseViewModel {
    var amountText = ""
    var merchant = ""
    var selectedCategory: ExpenseCategory = .autre
    var date: Date = .now
    var note = ""
    var isPaid = false
    var isLoading = false
    var errorMessage: String?
    var showDeleteConfirm = false

    private(set) var editingExpense: Expense?
    var isEditing: Bool { editingExpense != nil }

    init(expense: Expense? = nil) {
        if let expense {
            editingExpense = expense
            amountText = expense.amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(expense.amount))
                : String(expense.amount)
            merchant = expense.merchant
            selectedCategory = ExpenseCategory(rawValue: expense.category) ?? .autre
            date = expense.date
            note = expense.note ?? ""
            isPaid = expense.isPaid
        }
    }

    var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    func save(cardId: UUID, userId: String) async throws {
        guard let amt = amount, amt > 0 else {
            throw NSError(domain: "AddExpense", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: LocalizationManager.shared.t("addExpense.errorAmount")])
        }
        guard !merchant.isEmpty else {
            throw NSError(domain: "AddExpense", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: LocalizationManager.shared.t("addExpense.errorMerchant")])
        }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let dateString = fmt.string(from: date)

        if let expense = editingExpense {
            try await ExpenseService.updateExpense(
                id: expense.id,
                amount: amt,
                merchant: merchant,
                category: selectedCategory.rawValue,
                date: dateString,
                note: note.isEmpty ? nil : note,
                isPaid: isPaid
            )
        } else {
            let input = ExpenseInput(
                cardId: cardId.uuidString,
                userId: userId,
                amount: amt,
                merchant: merchant,
                category: selectedCategory.rawValue,
                date: dateString,
                note: note.isEmpty ? nil : note
            )
            _ = try await ExpenseService.addExpense(input)
        }
    }

    func deleteExpense() async throws {
        guard let expense = editingExpense else { return }
        try await ExpenseService.deleteExpense(id: expense.id)
    }
}
