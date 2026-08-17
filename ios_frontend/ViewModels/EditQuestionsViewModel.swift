import CoreData
import SwiftUI

/// Manages the habit's user-defined prompts: add, edit, delete, reorder (§6).
@MainActor
final class EditQuestionsViewModel: ObservableObject {
    @Published private(set) var questions: [Question] = []

    private let repository: HabitRepository
    private let habit: Habit

    init(context: NSManagedObjectContext, habit: Habit) {
        self.repository = HabitRepository(context: context)
        self.habit = habit
        refresh()
    }

    func refresh() {
        questions = repository.questions(for: habit)
    }

    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        repository.addQuestion(text: trimmed, to: habit)
        refresh()
    }

    func update(_ question: Question, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        repository.updateQuestion(question, text: trimmed)
        refresh()
    }

    func delete(at offsets: IndexSet) {
        offsets.map { questions[$0] }.forEach { repository.deleteQuestion($0) }
        refresh()
    }

    func move(from source: IndexSet, to destination: Int) {
        var reordered = questions
        reordered.move(fromOffsets: source, toOffset: destination)
        repository.reorderQuestions(reordered)
        refresh()
    }
}
