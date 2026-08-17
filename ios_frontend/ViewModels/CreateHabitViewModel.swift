import CoreData
import SwiftUI

/// Drives the create-habit onboarding (§5.5). No prompts are seeded — the deck's
/// empty state covers a habit with none (§6).
@MainActor
final class CreateHabitViewModel: ObservableObject {
    @Published var name = ""
    @Published var category: HabitCategory = .spending
    @Published var startDate = Date()

    private let repository: HabitRepository

    init(context: NSManagedObjectContext) {
        repository = HabitRepository(context: context)
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { !trimmedName.isEmpty }

    func save() {
        guard canSave else { return }
        repository.createHabit(
            name: trimmedName,
            category: category.rawValue,
            startDate: startDate
        )
    }
}
