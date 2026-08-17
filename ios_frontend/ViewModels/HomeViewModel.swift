import CoreData
import SwiftUI

/// Drives the Home screen. In this scaffold it surfaces the single MVP habit and
/// its two derived headline numbers; the intervention/slip flows land in later PRs.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var habit: Habit?
    @Published private(set) var currentStreakDays: Int = 0
    @Published private(set) var timesResisted: Int = 0

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        refresh()
    }

    /// Loads the primary habit (MVP = single habit) and recomputes derived values.
    func refresh() {
        let request = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = 1
        habit = (try? context.fetch(request))?.first

        currentStreakDays = StreakMath.currentStreakDays(since: habit?.currentStreakStart)
        timesResisted = resistedCount(for: habit)
    }

    /// Times-resisted is derived: count of `.resisted` sessions for the habit.
    private func resistedCount(for habit: Habit?) -> Int {
        guard let habit else { return 0 }
        let request = InterventionSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit == %@ AND outcome == %@",
            habit, InterventionOutcome.resisted.rawValue
        )
        return (try? context.count(for: request)) ?? 0
    }
}
