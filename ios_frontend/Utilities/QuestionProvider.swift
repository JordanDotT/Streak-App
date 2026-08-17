import CoreData

/// The seam that keeps the intervention deck independent of where prompts come from
/// (§6). MVP ships one implementation — user-defined prompts from Core Data. A
/// bundled default bank or an LLM source can be added later behind this protocol
/// without reworking the deck.
protocol QuestionProvider {
    /// Ordered prompts to show in the deck for the given habit.
    func questions(for habit: Habit) -> [String]
}

/// Returns the habit's user-defined prompts, ordered by `sortOrder`.
struct CoreDataQuestionProvider: QuestionProvider {
    let context: NSManagedObjectContext

    func questions(for habit: Habit) -> [String] {
        let request = Question.fetchRequest()
        request.predicate = NSPredicate(format: "habit == %@", habit)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        let rows = (try? context.fetch(request)) ?? []
        return rows.compactMap { $0.text }
    }
}
