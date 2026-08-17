import CoreData
import SwiftUI

/// Habit Detail (§5.2): big day count, times-resisted, longest streak, swipe-to-slip
/// with undo (§5.4), reset history, and entry points to the deck and prompt editor.
struct HabitDetailView: View {
    @ObservedObject var habit: Habit
    @StateObject private var viewModel: HabitDetailViewModel
    @StateObject private var slip: SlipController
    @State private var showingDeck = false

    private let context: NSManagedObjectContext

    init(habit: Habit) {
        self.habit = habit
        let ctx = habit.managedObjectContext ?? PersistenceController.shared.container.viewContext
        self.context = ctx
        _viewModel = StateObject(wrappedValue: HabitDetailViewModel(context: ctx, habit: habit))
        _slip = StateObject(wrappedValue: SlipController(context: ctx))
    }

    private var currentDays: Int {
        StreakMath.currentStreakDays(since: habit.currentStreakStart)
    }

    private var longestDisplayed: Int {
        StreakMath.displayedLongestStreak(
            stored: Int(habit.longestStreakDays),
            currentStreakDays: currentDays
        )
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text("\(currentDays)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("days clean")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                LabeledContent("Times resisted", value: "\(viewModel.timesResisted)")
                LabeledContent("Longest streak", value: "\(longestDisplayed) days")
            }

            Section {
                Button {
                    showingDeck = true
                } label: {
                    Label("Talk me out of it", systemImage: "hand.raised.fill")
                }

                NavigationLink {
                    EditQuestionsView(habit: habit, context: context)
                } label: {
                    Label("Edit prompts", systemImage: "text.bubble")
                }
            }

            Section {
                // Swipe-to-slip, no confirmation modal (§5.4). Swipe the row to reset.
                Label("I slipped", systemImage: "arrow.uturn.backward")
                    .foregroundStyle(.secondary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            slip.slip(habit)
                            viewModel.refresh()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                    }
            } footer: {
                Text("Swipe left to reset your streak. You'll have a moment to undo.")
            }

            if !viewModel.history.isEmpty {
                Section("Reset history") {
                    ForEach(viewModel.history) { event in
                        LabeledContent {
                            Text("")
                        } label: {
                            Text(event.date ?? Date(), format: .dateTime.month().day().year())
                        }
                    }
                }
            }
        }
        .navigationTitle(habit.name ?? "Habit")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingDeck) {
            InterventionDeckView(habit: habit, context: context) { outcome in
                switch outcome {
                case .resisted:
                    viewModel.refresh()
                case .gaveIn:
                    slip.slip(habit)
                    viewModel.refresh()
                }
            }
        }
        .slipSnackbar(slip)
        .onAppear { viewModel.refresh() }
    }
}
