
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
    var colorIndex: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId          = "user_id"
        case name
        case provider
        case lastFour        = "last_four"
        case creditLimit     = "credit_limit"
        case billingStartDay = "billing_start_day"
        case network
        case colorIndex      = "color_index"
        case createdAt       = "created_at"
    }

    init(id: UUID, userId: UUID, name: String, provider: String, lastFour: String,
         creditLimit: Double, billingStartDay: Int, network: CardNetwork,
         colorIndex: Int = 0, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.provider = provider
        self.lastFour = lastFour
        self.creditLimit = creditLimit
        self.billingStartDay = billingStartDay
        self.network = network
        self.colorIndex = colorIndex
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id              = try container.decode(UUID.self,        forKey: .id)
        userId          = try container.decode(UUID.self,        forKey: .userId)
        name            = try container.decode(String.self,      forKey: .name)
        provider        = try container.decode(String.self,      forKey: .provider)
        lastFour        = try container.decode(String.self,      forKey: .lastFour)
        creditLimit     = try container.decode(Double.self,      forKey: .creditLimit)
        billingStartDay = try container.decode(Int.self,         forKey: .billingStartDay)
        network         = try container.decode(CardNetwork.self, forKey: .network)
        colorIndex      = try container.decodeIfPresent(Int.self, forKey: .colorIndex) ?? 0

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
}

struct CardInput: Encodable {
    let userId: String
    let name: String
    let provider: String
    let lastFour: String
    let creditLimit: Double
    let billingStartDay: Int
    let network: String
    let colorIndex: Int

    enum CodingKeys: String, CodingKey {
        case userId          = "user_id"
        case name
        case provider
        case lastFour        = "last_four"
        case creditLimit     = "credit_limit"
        case billingStartDay = "billing_start_day"
        case network
        case colorIndex      = "color_index"
    }
}
