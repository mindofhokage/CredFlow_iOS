
import SwiftUI

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case alimentation
    case restaurant
    case transport
    case divertissement
    case sante
    case maison
    case voyages
    case shopping
    case services
    case autre

    var id: String { rawValue }

    var displayName: String {
        LocalizationManager.shared.t("category.\(rawValue)")
    }

    var icon: String {
        switch self {
        case .alimentation:   return "cart.fill"
        case .restaurant:     return "fork.knife"
        case .transport:      return "car.fill"
        case .divertissement: return "tv.fill"
        case .sante:          return "cross.fill"
        case .maison:         return "house.fill"
        case .voyages:        return "airplane"
        case .shopping:       return "bag.fill"
        case .services:       return "wrench.fill"
        case .autre:          return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .alimentation:   return .orange
        case .restaurant:     return .red
        case .transport:      return .blue
        case .divertissement: return .purple
        case .sante:          return .green
        case .maison:         return .brown
        case .voyages:        return .cyan
        case .shopping:       return .pink
        case .services:       return .gray
        case .autre:          return .secondary
        }
    }
}
