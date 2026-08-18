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

/// Ships a bundled bank of default prompts keyed by category, so a fresh habit's
/// deck is never empty (HANDOFF_02 §A). Defaults live in `default_prompts.json` and
/// are *never* written to Core Data — they stay undeletable-by-accident and can
/// improve with app updates. An unknown or custom category falls back to `generic`.
struct BundledQuestionProvider: QuestionProvider {
    private static let genericKey = "generic"

    /// Category key → default prompts, loaded once from the bundled JSON.
    private let banks: [String: [String]]

    init(bundle: Bundle = .main, resource: String = "default_prompts") {
        banks = Self.load(bundle: bundle, resource: resource)
    }

    func questions(for habit: Habit) -> [String] {
        let key = habit.category?.lowercased() ?? Self.genericKey
        return banks[key] ?? banks[Self.genericKey] ?? []
    }

    private static func load(bundle: Bundle, resource: String) -> [String: [String]] {
        guard let url = bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            assertionFailure("Missing or malformed \(resource).json")
            return [:]
        }
        return decoded
    }
}

/// Concatenates several providers into one deck. Order is preserved, so the deck for
/// a habit is its category's bundled defaults followed by the user's custom prompts.
struct CompositeQuestionProvider: QuestionProvider {
    let providers: [QuestionProvider]

    func questions(for habit: Habit) -> [String] {
        providers.flatMap { $0.questions(for: habit) }
    }
}
