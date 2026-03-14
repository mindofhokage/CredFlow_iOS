
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

    static func deleteExpense(id: UUID) async throws {
        try await client
            .from("expenses")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
