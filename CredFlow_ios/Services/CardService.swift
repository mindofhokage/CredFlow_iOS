
import Foundation
import Supabase

struct CardService {
    private static var client: SupabaseClient { SupabaseManager.shared.client }

    static func fetchCards() async throws -> [Card] {
        try await client
            .from("cards")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func addCard(_ card: CardInput) async throws -> Card {
        let cards: [Card] = try await client
            .from("cards")
            .insert(card)
            .select()
            .execute()
            .value
        guard let first = cards.first else {
            throw NSError(domain: "CardService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Insert returned no data"])
        }
        return first
    }

    static func updateCard(_ card: Card) async throws {
        try await client
            .from("cards")
            .update(card)
            .eq("id", value: card.id.uuidString)
            .execute()
    }

    static func deleteCard(id: UUID) async throws {
        try await client
            .from("cards")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
