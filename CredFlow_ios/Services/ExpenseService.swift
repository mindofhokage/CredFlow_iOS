
import Foundation
import Supabase

struct ExpenseService {
    private static var client: SupabaseClient { SupabaseManager.shared.client }

    static func fetchExpenses(cardId: UUID, periodStart: Date, periodEnd: Date) async throws -> [Expense] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let start = fmt.string(from: periodStart)
        let end   = fmt.string(from: periodEnd)

        return try await client
            .from("expenses")
            .select()
            .eq("card_id", value: cardId.uuidString)
            .gte("date", value: start)
            .lte("date", value: end)
            .order("date", ascending: false)
            .execute()
            .value
    }

    static func addExpense(_ expense: ExpenseInput) async throws -> Expense {
        let expenses: [Expense] = try await client
            .from("expenses")
            .insert(expense)
            .select()
            .execute()
            .value
        guard let first = expenses.first else {
            throw NSError(domain: "ExpenseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Insert returned no data"])
        }
        return first
    }

    private struct ExpenseUpdateFields: Encodable {
        let amount: Double
        let merchant: String
        let category: String
        let date: String
        let note: String?
        let isPaid: Bool

        enum CodingKeys: String, CodingKey {
            case amount, merchant, category, date, note
            case isPaid = "is_paid"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(amount,   forKey: .amount)
            try container.encode(merchant, forKey: .merchant)
            try container.encode(category, forKey: .category)
            try container.encode(date,     forKey: .date)
            try container.encode(note,     forKey: .note)   // envoie null si nil
            try container.encode(isPaid,   forKey: .isPaid)
        }
    }

    static func updateExpense(id: UUID, amount: Double, merchant: String, category: String, date: String, note: String?, isPaid: Bool) async throws {
        let fields = ExpenseUpdateFields(amount: amount, merchant: merchant, category: category, date: date, note: note, isPaid: isPaid)
        try await client
            .from("expenses")
            .update(fields)
            .eq("id", value: id.uuidString)
            .execute()
    }

    static func togglePaid(id: UUID, isPaid: Bool) async throws {
        try await client
            .from("expenses")
            .update(["is_paid": isPaid])
            .eq("id", value: id.uuidString)
            .execute()
    }

    static func deleteExpense(id: UUID) async throws {
        try await client
            .from("expenses")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
