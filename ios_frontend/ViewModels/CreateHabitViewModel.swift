import CoreData
import SwiftUI

/// Drives the habit form used for both create-habit onboarding (§5.5) and editing
/// an existing habit (§B). When `habit` is supplied the form is pre-filled and
/// `save()` updates in place; otherwise it creates a new habit. No prompts are
/// seeded — bundled defaults cover the deck (§A).
@MainActor
final class CreateHabitViewModel: ObservableObject {
    @Published var name = ""
    @Published var category: HabitCategory = .spending
    @Published var startDate = Date()

    private let repository: HabitRepository
    private let editingHabit: Habit?

    var isEditing: Bool { editingHabit != nil }

    init(context: NSManagedObjectContext, habit: Habit? = nil) {
        repository = HabitRepository(context: context)
        editingHabit = habit
        if let habit {
            name = habit.name ?? ""
            category = HabitCategory(rawValue: habit.category ?? "") ?? .other
            startDate = habit.currentStreakStart ?? Date()
        }
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { !trimmedName.isEmpty }

    func save() {
        guard canSave else { return }
        if let editingHabit {
            repository.updateHabit(
                editingHabit,
                name: trimmedName,
                category: category.rawValue,
                startDate: startDate
            )
        } else {
            repository.createHabit(
                name: trimmedName,
                category: category.rawValue,
                startDate: startDate
            )
        }
    }

    func delete() {
        guard let editingHabit else { return }
        repository.deleteHabit(editingHabit)
    }
}
