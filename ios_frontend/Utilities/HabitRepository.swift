import CoreData

/// A slip that has been applied optimistically and can still be undone.
/// Holds the state needed to either confirm (bump longest streak) or roll back.
struct SlipToken {
    let habit: Habit
    let resetEvent: ResetEvent
    let previousStreakStart: Date?
    let previousLongest: Int32
    let endedStreakDays: Int
}

/// Centralizes every Core Data mutation so view models stay thin and the streak
/// rules (derived counts, slip/undo, longest-streak timing) live in one place.
struct HabitRepository {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Habits

    /// The single MVP habit (earliest created). Multi-habit UI comes later.
    func primaryHabit() -> Habit? {
        let request = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    @discardableResult
    func createHabit(name: String, category: String?, startDate: Date) -> Habit {
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = name
        habit.category = category
        habit.createdAt = Date()
        habit.currentStreakStart = startDate
        habit.longestStreakDays = 0
        save()
        return habit
    }

    // MARK: - Derived values

    func currentStreakDays(for habit: Habit) -> Int {
        StreakMath.currentStreakDays(since: habit.currentStreakStart)
    }

    func resistedCount(for habit: Habit) -> Int {
        let request = InterventionSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit == %@ AND outcome == %@",
            habit, InterventionOutcome.resisted.rawValue
        )
        return (try? context.count(for: request)) ?? 0
    }

    // MARK: - Intervention outcomes

    /// "I'll pass" — logs a resisted session. The day streak is untouched.
    func logResist(for habit: Habit) {
        let session = InterventionSession(context: context)
        session.id = UUID()
        session.habit = habit
        session.date = Date()
        session.outcome = InterventionOutcome.resisted.rawValue
        save()
    }

    // MARK: - Slip (reset) with undo

    /// Applies a slip immediately: day count → 0 today, a `ResetEvent` is appended,
    /// and a `gaveIn` session is logged. Longest streak is *not* bumped yet — that
    /// happens on `confirmSlip` so an undo leaves the record untouched (§5.4).
    func performSlip(on habit: Habit, note: String? = nil) -> SlipToken {
        let previousStart = habit.currentStreakStart
        let previousLongest = habit.longestStreakDays
        let endedDays = currentStreakDays(for: habit)

        let reset = ResetEvent(context: context)
        reset.id = UUID()
        reset.habit = habit
        reset.date = Date()
        reset.note = note

        let session = InterventionSession(context: context)
        session.id = UUID()
        session.habit = habit
        session.date = Date()
        session.outcome = InterventionOutcome.gaveIn.rawValue

        habit.currentStreakStart = Date()
        save()

        return SlipToken(
            habit: habit,
            resetEvent: reset,
            previousStreakStart: previousStart,
            previousLongest: previousLongest,
            endedStreakDays: endedDays
        )
    }

    /// Finalizes a slip: promote the ended streak to the record if it beat it.
    func confirmSlip(_ token: SlipToken) {
        if token.endedStreakDays > Int(token.previousLongest) {
            token.habit.longestStreakDays = Int32(token.endedStreakDays)
        }
        save()
    }

    /// Rolls a slip back: restore the streak start and drop the reset/session rows.
    func undoSlip(_ token: SlipToken) {
        token.habit.currentStreakStart = token.previousStreakStart
        token.habit.longestStreakDays = token.previousLongest
        context.delete(token.resetEvent)
        // Remove the paired gaveIn session created during performSlip.
        if let session = mostRecentGaveInSession(for: token.habit) {
            context.delete(session)
        }
        save()
    }

    private func mostRecentGaveInSession(for habit: Habit) -> InterventionSession? {
        let request = InterventionSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit == %@ AND outcome == %@",
            habit, InterventionOutcome.gaveIn.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    // MARK: - Reset history

    func resetHistory(for habit: Habit) -> [ResetEvent] {
        let request = ResetEvent.fetchRequest()
        request.predicate = NSPredicate(format: "habit == %@", habit)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Questions (user-defined prompts)

    func questions(for habit: Habit) -> [Question] {
        let request = Question.fetchRequest()
        request.predicate = NSPredicate(format: "habit == %@", habit)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    @discardableResult
    func addQuestion(text: String, to habit: Habit) -> Question {
        let nextOrder = (questions(for: habit).map { $0.sortOrder }.max() ?? -1) + 1
        let question = Question(context: context)
        question.id = UUID()
        question.habit = habit
        question.text = text
        question.isUserDefined = true
        question.sortOrder = nextOrder
        save()
        return question
    }

    func updateQuestion(_ question: Question, text: String) {
        question.text = text
        save()
    }

    func deleteQuestion(_ question: Question) {
        context.delete(question)
        save()
    }

    /// Persists a new order by rewriting `sortOrder` to match the array.
    func reorderQuestions(_ ordered: [Question]) {
        for (index, question) in ordered.enumerated() {
            question.sortOrder = Int32(index)
        }
        save()
    }

    // MARK: - Save

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Core Data save failed: \(error)")
        }
    }
}
