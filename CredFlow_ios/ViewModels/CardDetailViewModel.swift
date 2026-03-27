
import Foundation

@Observable
class CardDetailViewModel {
    var card: Card
    var expenses: [Expense] = []
    var selectedCategory: String? = nil
    var searchText: String = ""
    var periodOffset: Int = 0
    var showAddExpense = false
    var showEditCard = false
    var isLoading = false
    var errorMessage: String?

    init(card: Card) {
        self.card = card
    }

    var billingPeriod: (start: Date, end: Date) {
        BillingPeriod.period(startDay: card.billingStartDay, monthOffset: periodOffset)
    }

    var isCurrentPeriod: Bool { periodOffset == 0 }

    /// Dépenses non payées — ce qu'on doit encore à la carte
    var solde: Double {
        expenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    /// Crédit encore disponible
    var available: Double {
        max(card.creditLimit - solde, 0)
    }

    var filteredExpenses: [Expense] {
        var result = expenses

        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { expense in
                expense.merchant.lowercased().contains(query)
                || (expense.note ?? "").lowercased().contains(query)
                || String(format: "%.2f", expense.amount).contains(query)
            }
        }

        return result
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
        let period = billingPeriod
        // Afficher le cache immédiatement, spinner seulement si aucune donnée
        if let cached = CacheService.loadExpenses(cardId: card.id, periodStart: period.start) {
            expenses = cached
        }
        isLoading = expenses.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fresh = try await ExpenseService.fetchExpenses(
                cardId: card.id,
                periodStart: period.start,
                periodEnd: period.end
            )
            expenses = fresh
            CacheService.saveExpenses(fresh, cardId: card.id, periodStart: period.start)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePaid(_ expense: Expense) async {
        let newValue = !expense.isPaid
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[idx].isPaid = newValue
        }
        do {
            try await ExpenseService.togglePaid(id: expense.id, isPaid: newValue)
            CacheService.saveExpenses(expenses, cardId: card.id, periodStart: billingPeriod.start)
        } catch {
            // Rollback
            if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses[idx].isPaid = !newValue
            }
            errorMessage = error.localizedDescription
        }
    }

    func deleteExpense(_ expense: Expense) async {
        do {
            try await ExpenseService.deleteExpense(id: expense.id)
            expenses.removeAll { $0.id == expense.id }
            CacheService.saveExpenses(expenses, cardId: card.id, periodStart: billingPeriod.start)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goToPreviousPeriod() async {
        guard periodOffset > -12 else { return }
        periodOffset -= 1
        await loadExpenses()
    }

    func goToNextPeriod() async {
        guard periodOffset < 0 else { return }
        periodOffset += 1
        await loadExpenses()
    }
}
