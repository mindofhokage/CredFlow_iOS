
import Foundation

@Observable
class CardDetailViewModel {
    var card: Card
    var expenses: [Expense] = []
    var selectedCategory: String? = nil
    var showAddExpense = false
    var showEditCard = false
    var isLoading = false
    var errorMessage: String?

    init(card: Card) {
        self.card = card
    }

    var billingPeriod: (start: Date, end: Date) {
        BillingPeriod.current(startDay: card.billingStartDay)
    }

    var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var filteredExpenses: [Expense] {
        guard let cat = selectedCategory else { return expenses }
        return expenses.filter { $0.category == cat }
    }

    var expensesByDate: [(date: Date, expenses: [Expense])] {
        let calendar = Calendar.current
        var grouped: [Date: [Expense]] = [:]
        for expense in filteredExpenses {
            let day = calendar.startOfDay(for: expense.date)
            grouped[day, default: []].append(expense)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, expenses: $0.value) }
    }

    func loadExpenses() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let period = billingPeriod
        do {
            expenses = try await ExpenseService.fetchExpenses(
                cardId: card.id,
                periodStart: period.start,
                periodEnd: period.end
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteExpense(_ expense: Expense) async {
        do {
            try await ExpenseService.deleteExpense(id: expense.id)
            expenses.removeAll { $0.id == expense.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
