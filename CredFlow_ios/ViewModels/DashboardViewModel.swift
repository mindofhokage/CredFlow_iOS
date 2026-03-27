
import Foundation

@Observable
class DashboardViewModel {
    var cards: [Card] = []
    var isLoading = false
    var showAddCard = false
    var errorMessage: String?

    /// Solde impayé total (toutes cartes, période courante)
    var totalSpent: Double = 0
    /// Crédit disponible total
    var totalAvailable: Double = 0

    var totalLimit: Double {
        cards.reduce(0) { $0 + $1.creditLimit }
    }

    func loadCards() async {
        // Afficher le cache immédiatement, spinner seulement si aucune donnée
        if let cached = CacheService.loadCards() {
            cards = cached
        }
        isLoading = cards.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fresh = try await CardService.fetchCards()
            cards = fresh
            CacheService.saveCards(fresh)
            await loadGlobalBalances()
        } catch is CancellationError {
            // Pull-to-refresh can cancel the previous load — ignore it
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession reports cancellation as URLError — ignore it too
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Charge les dépenses impayées de chaque carte pour la période courante
    func loadGlobalBalances() async {
        var spent: Double = 0
        for card in cards {
            let period = BillingPeriod.current(startDay: card.billingStartDay)
            // Cache d'abord, puis réseau
            let expenses: [Expense]
            if let cached = CacheService.loadExpenses(cardId: card.id, periodStart: period.start) {
                expenses = cached
            } else {
                expenses = (try? await ExpenseService.fetchExpenses(
                    cardId: card.id, periodStart: period.start, periodEnd: period.end
                )) ?? []
            }
            spent += expenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
        }
        totalSpent = spent
        totalAvailable = max(totalLimit - spent, 0)
    }

    func updateCard(_ card: Card) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx] = card
        }
    }

    func deleteCard(_ card: Card) async {
        do {
            try await CardService.deleteCard(id: card.id)
            cards.removeAll { $0.id == card.id }
            CacheService.saveCards(cards)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
