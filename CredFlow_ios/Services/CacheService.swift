
import Foundation

struct CacheService {

    // MARK: - Fichiers

    private static var cacheDir: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CredFlowCache", isDirectory: true)
    }

    private static func ensureDir() {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    private static func url(for name: String) -> URL {
        cacheDir.appendingPathComponent("\(name).json")
    }

    // MARK: - Cartes

    static func saveCards(_ cards: [Card]) {
        ensureDir()
        try? JSONEncoder().encode(cards).write(to: url(for: "cards"))
    }

    static func loadCards() -> [Card]? {
        guard let data = try? Data(contentsOf: url(for: "cards")) else { return nil }
        return try? JSONDecoder().decode([Card].self, from: data)
    }

    // MARK: - Dépenses (clé = cardId + début de période)

    private static func expensesKey(cardId: UUID, periodStart: Date) -> String {
        let day = ISO8601DateFormatter().string(from: periodStart).prefix(10)
        return "expenses_\(cardId.uuidString)_\(day)"
    }

    static func saveExpenses(_ expenses: [Expense], cardId: UUID, periodStart: Date) {
        ensureDir()
        let key = expensesKey(cardId: cardId, periodStart: periodStart)
        try? JSONEncoder().encode(expenses).write(to: url(for: key))
    }

    static func loadExpenses(cardId: UUID, periodStart: Date) -> [Expense]? {
        let key = expensesKey(cardId: cardId, periodStart: periodStart)
        guard let data = try? Data(contentsOf: url(for: key)) else { return nil }
        return try? JSONDecoder().decode([Expense].self, from: data)
    }

    // MARK: - Nettoyage (à appeler au logout)

    static func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
    }
}
