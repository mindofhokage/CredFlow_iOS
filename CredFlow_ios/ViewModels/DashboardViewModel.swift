
import Foundation

@Observable
class DashboardViewModel {
    var cards: [Card] = []
    var isLoading = false
    var showAddCard = false
    var errorMessage: String?
    var totalMonthlySpending: Double = 0

    func loadCards() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            cards = try await CardService.fetchCards()
        } catch {
            errorMessage = error.localizedDescription
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
