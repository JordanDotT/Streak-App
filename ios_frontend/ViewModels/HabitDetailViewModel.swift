import CoreData
import SwiftUI

/// Backs Habit Detail: the derived tallies and the reset history list.
@MainActor
final class HabitDetailViewModel: ObservableObject {
    @Published private(set) var timesResisted: Int = 0
    @Published private(set) var history: [ResetEvent] = []

    private let repository: HabitRepository
    private let habit: Habit

    init(context: NSManagedObjectContext, habit: Habit) {
        self.repository = HabitRepository(context: context)
        self.habit = habit
        refresh()
    }

    func refresh() {
        timesResisted = repository.resistedCount(for: habit)
        history = repository.resetHistory(for: habit)
    }
}
