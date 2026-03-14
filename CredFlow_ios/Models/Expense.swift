
import Foundation

struct Expense: Codable, Identifiable {
    let id: UUID
    let cardId: UUID
    let userId: UUID
    var amount: Double
    var merchant: String
    var category: String
    var date: Date
    var note: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case cardId    = "card_id"
        case userId    = "user_id"
        case amount
        case merchant
        case category
        case date
        case note
        case createdAt = "created_at"
    }
}

struct ExpenseInput: Encodable {
    let cardId: String
    let userId: String
    let amount: Double
    let merchant: String
    let category: String
    let date: String   // "YYYY-MM-DD"
    let note: String?

    enum CodingKeys: String, CodingKey {
        case cardId   = "card_id"
        case userId   = "user_id"
        case amount
        case merchant
        case category
        case date
        case note
    }
}
