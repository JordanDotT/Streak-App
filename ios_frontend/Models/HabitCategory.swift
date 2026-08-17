import Foundation

/// Suggested categories for the create-habit picker. Cosmetic for MVP (§7) — it no
/// longer drives a default question bank — but kept as a first-class list so the
/// future default-bank / LLM seam has something to key off. Stored as the raw string
/// on `Habit.category`; users can also type their own.
enum HabitCategory: String, CaseIterable, Identifiable {
    case spending
    case substances
    case social
    case food
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spending: return "Spending"
        case .substances: return "Substances"
        case .social: return "Social / screen"
        case .food: return "Food"
        case .other: return "Other"
        }
    }
}
