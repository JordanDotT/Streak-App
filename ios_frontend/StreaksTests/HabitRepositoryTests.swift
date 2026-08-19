import CoreData
import XCTest
@testable import Streaks

/// Exercises the Core Data mutations through `HabitRepository` on an in-memory
/// store — never the App Group store (HANDOFF_02 §C). Covers slip/undo/confirm,
/// resist logging, habit create/update/delete, and question CRUD + ordering.
final class HabitRepositoryTests: XCTestCase {
    private var context: NSManagedObjectContext!
    private var repository: HabitRepository!

    override func setUp() {
        super.setUp()
        context = PersistenceController(inMemory: true).container.viewContext
        repository = HabitRepository(context: context)
    }

    override func tearDown() {
        repository = nil
        context = nil
        super.tearDown()
    }

    /// A habit whose current streak started `days` ago (noon, to avoid boundary flake).
    private func makeHabit(daysAgo days: Int, longest: Int32 = 0) -> Habit {
        let start = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Calendar.current.startOfDay(for: Date())
        )!
        let habit = repository.createHabit(name: "Test", category: "spending", startDate: start)
        habit.longestStreakDays = longest
        repository.save()
        return habit
    }

    // MARK: - Slip

    func testPerformSlipResetsDayCountAndLogsReset() {
        let habit = makeHabit(daysAgo: 10)
        XCTAssertEqual(repository.currentStreakDays(for: habit), 10)

        let token = repository.performSlip(on: habit)

        XCTAssertEqual(repository.currentStreakDays(for: habit), 0)
        XCTAssertEqual(token.endedStreakDays, 10)
        XCTAssertEqual(repository.resetHistory(for: habit).count, 1)
    }

    // MARK: - Undo

    func testUndoSlipRestoresStreakAndDoesNotPromoteLongest() {
        let habit = makeHabit(daysAgo: 10, longest: 5)
        let originalStart = habit.currentStreakStart

        let token = repository.performSlip(on: habit)
        repository.undoSlip(token)

        XCTAssertEqual(habit.currentStreakStart, originalStart)
        XCTAssertEqual(repository.currentStreakDays(for: habit), 10)
        XCTAssertEqual(habit.longestStreakDays, 5, "undo must never promote the record")
        XCTAssertTrue(repository.resetHistory(for: habit).isEmpty, "the reset event should be gone")
    }

    // MARK: - Confirm

    func testConfirmSlipPromotesLongestWhenRecordBeaten() {
        let habit = makeHabit(daysAgo: 10, longest: 5)
        let token = repository.performSlip(on: habit)

        repository.confirmSlip(token)

        XCTAssertEqual(habit.longestStreakDays, 10)
    }

    func testConfirmSlipLeavesLongestWhenRecordNotBeaten() {
        let habit = makeHabit(daysAgo: 3, longest: 5)
        let token = repository.performSlip(on: habit)

        repository.confirmSlip(token)

        XCTAssertEqual(habit.longestStreakDays, 5)
    }

    // MARK: - Resist

    func testLogResistRecordsSessionAndLeavesDayCount() {
        let habit = makeHabit(daysAgo: 7)

        repository.logResist(for: habit)

        XCTAssertEqual(repository.resistedCount(for: habit), 1)
        XCTAssertEqual(repository.currentStreakDays(for: habit), 7)
        XCTAssertTrue(repository.resetHistory(for: habit).isEmpty)
    }

    // MARK: - Habit CRUD

    func testCreateHabitIsPrimary() {
        let habit = repository.createHabit(name: "Spending", category: "spending", startDate: Date())
        XCTAssertEqual(repository.primaryHabit(), habit)
    }

    func testUpdateHabitEditsFields() {
        let habit = makeHabit(daysAgo: 5)
        let newStart = Calendar.current.date(byAdding: .day, value: -20, to: Date())!

        repository.updateHabit(habit, name: "Doomscrolling", category: "social", startDate: newStart)

        XCTAssertEqual(habit.name, "Doomscrolling")
        XCTAssertEqual(habit.category, "social")
        XCTAssertEqual(repository.currentStreakDays(for: habit), 20)
    }

    func testDeleteHabitCascadesChildren() {
        let habit = makeHabit(daysAgo: 4)
        repository.addQuestion(text: "Why?", to: habit)
        repository.logResist(for: habit)
        _ = repository.performSlip(on: habit) // creates a ResetEvent + gaveIn session

        repository.deleteHabit(habit)

        XCTAssertNil(repository.primaryHabit())
        XCTAssertEqual(try context.count(for: Question.fetchRequest()), 0)
        XCTAssertEqual(try context.count(for: ResetEvent.fetchRequest()), 0)
        XCTAssertEqual(try context.count(for: InterventionSession.fetchRequest()), 0)
    }

    // MARK: - Questions

    func testAddQuestionAssignsIncrementingSortOrder() {
        let habit = makeHabit(daysAgo: 1)

        let first = repository.addQuestion(text: "One", to: habit)
        let second = repository.addQuestion(text: "Two", to: habit)

        XCTAssertEqual(first.sortOrder, 0)
        XCTAssertEqual(second.sortOrder, 1)
        XCTAssertEqual(repository.questions(for: habit).map(\.text), ["One", "Two"])
    }

    func testReorderQuestionsRewritesSortOrder() {
        let habit = makeHabit(daysAgo: 1)
        let a = repository.addQuestion(text: "A", to: habit)
        let b = repository.addQuestion(text: "B", to: habit)
        let c = repository.addQuestion(text: "C", to: habit)

        repository.reorderQuestions([c, a, b])

        XCTAssertEqual(repository.questions(for: habit).map(\.text), ["C", "A", "B"])
    }

    func testUpdateAndDeleteQuestion() {
        let habit = makeHabit(daysAgo: 1)
        let q = repository.addQuestion(text: "Old", to: habit)

        repository.updateQuestion(q, text: "New")
        XCTAssertEqual(repository.questions(for: habit).map(\.text), ["New"])

        repository.deleteQuestion(q)
        XCTAssertTrue(repository.questions(for: habit).isEmpty)
    }
}
