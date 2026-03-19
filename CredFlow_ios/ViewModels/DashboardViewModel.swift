
import Foundation

@Observable
class DashboardViewModel {
    var cards: [Card] = []
    var isLoading = false
    var showAddCard = false
    var errorMessage: String?
    var totalMonthlySpending: Double = 0

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
