
import Foundation

@Observable
class AddExpenseViewModel {
    var amountText = ""
    var merchant = ""
    var selectedCategory: ExpenseCategory = .autre
    var date: Date = .now
    var note = ""
    var isLoading = false
    var errorMessage: String?

    var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    func addExpense(cardId: UUID, userId: String) async throws {
        guard let amt = amount, amt > 0 else {
            throw NSError(domain: "AddExpense", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Montant invalide."])
        }
        guard !merchant.isEmpty else {
            throw NSError(domain: "AddExpense", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Veuillez entrer un marchand."])
        }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let input = ExpenseInput(
            cardId: cardId.uuidString,
            userId: userId,
            amount: amt,
            merchant: merchant,
            category: selectedCategory.rawValue,
            date: fmt.string(from: date),
            note: note.isEmpty ? nil : note
        )
        _ = try await ExpenseService.addExpense(input)
    }
}
