
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
        struct CardUpdateFields: Encodable {
            let name: String
            let provider: String
            let lastFour: String
            let creditLimit: Double
            let billingStartDay: Int
            let network: String
            let colorIndex: Int

            enum CodingKeys: String, CodingKey {
                case name, provider, network
                case lastFour        = "last_four"
                case creditLimit     = "credit_limit"
                case billingStartDay = "billing_start_day"
                case colorIndex      = "color_index"
            }
        }
        let fields = CardUpdateFields(
            name: card.name,
            provider: card.provider,
            lastFour: card.lastFour,
            creditLimit: card.creditLimit,
            billingStartDay: card.billingStartDay,
            network: card.network.rawValue,
            colorIndex: card.colorIndex
        )
        try await client
            .from("cards")
            .update(fields)
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
