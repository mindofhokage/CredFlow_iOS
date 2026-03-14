
import Foundation

enum CardNetwork: String, Codable, CaseIterable {
    case visa
    case mastercard
    case amex

    var displayName: String {
        switch self {
        case .visa:       return "Visa"
        case .mastercard: return "Mastercard"
        case .amex:       return "Amex"
        }
    }
}

struct Card: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var name: String
    var provider: String
    var lastFour: String
    var creditLimit: Double
    var billingStartDay: Int
    var network: CardNetwork
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId        = "user_id"
        case name
        case provider
        case lastFour      = "last_four"
        case creditLimit   = "credit_limit"
        case billingStartDay = "billing_start_day"
        case network
        case createdAt     = "created_at"
    }
}

struct CardInput: Encodable {
    let userId: String
    let name: String
    let provider: String
    let lastFour: String
    let creditLimit: Double
    let billingStartDay: Int
    let network: String

    enum CodingKeys: String, CodingKey {
        case userId        = "user_id"
        case name
        case provider
        case lastFour      = "last_four"
        case creditLimit   = "credit_limit"
        case billingStartDay = "billing_start_day"
        case network
    }
}
