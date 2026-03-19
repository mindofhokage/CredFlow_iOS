
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
    var isPaid: Bool
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
        case isPaid    = "is_paid"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id        = try container.decode(UUID.self,   forKey: .id)
        cardId    = try container.decode(UUID.self,   forKey: .cardId)
        userId    = try container.decode(UUID.self,   forKey: .userId)
        amount    = try container.decode(Double.self, forKey: .amount)
        merchant  = try container.decode(String.self, forKey: .merchant)
        category  = try container.decode(String.self, forKey: .category)
        note      = try container.decodeIfPresent(String.self, forKey: .note)
        isPaid    = try container.decodeIfPresent(Bool.self, forKey: .isPaid) ?? false

        // "date" est stocké comme "YYYY-MM-DD" dans Supabase
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFmt = ISO8601DateFormatter()
        dateFmt.formatOptions = [.withFullDate]
        guard let parsedDate = dateFmt.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container,
                debugDescription: "Format de date invalide: \(dateString)")
        }
        date = parsedDate

        // "created_at" arrive avec fractions de secondes depuis Supabase
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let tsFmtFractional = ISO8601DateFormatter()
        tsFmtFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let tsFmt = ISO8601DateFormatter()
        tsFmt.formatOptions = [.withInternetDateTime]
        guard let parsedCreatedAt = tsFmtFractional.date(from: createdAtString) ?? tsFmt.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container,
                debugDescription: "Format de timestamp invalide: \(createdAtString)")
        }
        createdAt = parsedCreatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,       forKey: .id)
        try c.encode(cardId,   forKey: .cardId)
        try c.encode(userId,   forKey: .userId)
        try c.encode(amount,   forKey: .amount)
        try c.encode(merchant, forKey: .merchant)
        try c.encode(category, forKey: .category)
        try c.encode(note,     forKey: .note)
        try c.encode(isPaid,   forKey: .isPaid)
        let dateFmt = ISO8601DateFormatter()
        dateFmt.formatOptions = [.withFullDate]
        try c.encode(dateFmt.string(from: date), forKey: .date)
        let tsFmt = ISO8601DateFormatter()
        tsFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try c.encode(tsFmt.string(from: createdAt), forKey: .createdAt)
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
