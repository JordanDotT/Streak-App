import CoreData
import SwiftUI

/// Backs the "Talk me out of it" deck. Builds the card list from the habit's
/// user-defined prompts (via the `QuestionProvider` seam) plus an optional stakes
/// card, tracks progress, and logs the resisted outcome.
@MainActor
final class InterventionViewModel: ObservableObject {
    enum Phase {
        case empty      // no prompts yet
        case deck       // swiping through cards
        case outcome    // pass / gave-in choice
    }

    @Published private(set) var cards: [String]
    @Published private(set) var index: Int = 0
    @Published private(set) var phase: Phase

    private let repository: HabitRepository
    private let habit: Habit

    init(context: NSManagedObjectContext, habit: Habit) {
        self.repository = HabitRepository(context: context)
        self.habit = habit

        let provider: QuestionProvider = CoreDataQuestionProvider(context: context)
        var prompts = provider.questions(for: habit)

        // Seed a stakes card first when there's a streak on the line (§5.3).
        let days = StreakMath.currentStreakDays(since: habit.currentStreakStart)
        if days > 0, !prompts.isEmpty {
            let unit = days == 1 ? "day" : "days"
            prompts.insert("You're \(days) \(unit) in. Reset to zero?", at: 0)
        }

        self.cards = prompts
        self.phase = prompts.isEmpty ? .empty : .deck
    }

    var currentCard: String? {
        guard index < cards.count else { return nil }
        return cards[index]
    }

    /// Cards still to show, top-most last (for stacking).
    var remaining: [String] {
        guard index < cards.count else { return [] }
        return Array(cards[index...])
    }

    func advance() {
        guard phase == .deck else { return }
        index += 1
        if index >= cards.count {
            phase = .outcome
        }
    }

    /// "I'll pass" — log the resist. The day streak is untouched.
    func resist() {
        repository.logResist(for: habit)
    }
}
