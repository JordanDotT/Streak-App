import CoreData
import SwiftUI

/// The "Talk me out of it" flow: swipe through reflection prompts, then choose an
/// outcome. Resist is logged and celebrated here; "I gave in" hands the slip back to
/// the presenter (which shows the undo snackbar), keeping one slip path (§5.3/§5.4).
struct InterventionDeckView: View {
    @ObservedObject var habit: Habit
    let onFinish: (InterventionOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: InterventionViewModel
    @State private var celebrating = false

    private let context: NSManagedObjectContext

    init(habit: Habit, context: NSManagedObjectContext, onFinish: @escaping (InterventionOutcome) -> Void) {
        self.habit = habit
        self.context = context
        self.onFinish = onFinish
        _viewModel = StateObject(wrappedValue: InterventionViewModel(context: context, habit: habit))
    }

    var body: some View {
        NavigationStack {
            Group {
                if celebrating {
                    celebration
                } else {
                    switch viewModel.phase {
                    case .empty: emptyState
                    case .deck: deck
                    case .outcome: outcome
                    }
                }
            }
            .padding()
            .navigationTitle("Talk me out of it")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Empty state (§6)

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No prompts yet", systemImage: "text.bubble")
        } description: {
            Text("Add a few reflections to talk yourself out of it next time.")
        } actions: {
            NavigationLink("Add your first prompt") {
                EditQuestionsView(habit: habit, context: context)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Deck

    private var deck: some View {
        VStack {
            Text("\(min(viewModel.index + 1, viewModel.cards.count)) of \(viewModel.cards.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ZStack {
                ForEach(Array(viewModel.remaining.prefix(3).enumerated()), id: \.offset) { pair in
                    let depth = pair.offset
                    SwipeCard(text: pair.element, isTop: depth == 0) {
                        viewModel.advance()
                    }
                    .zIndex(Double(3 - depth))
                    .scaleEffect(1 - CGFloat(depth) * 0.04)
                    .offset(y: CGFloat(depth) * 10)
                    .allowsHitTesting(depth == 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text("Swipe a card away when you've read it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Outcome

    private var outcome: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("How are you feeling?")
                .font(.title2.weight(.semibold))
            Spacer()

            Button {
                viewModel.resist()
                withAnimation { celebrating = true }
            } label: {
                Text("I'll pass")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                onFinish(.gaveIn)
                dismiss()
            } label: {
                Text("I gave in")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Celebration (resist)

    private var celebration: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("Nice. Streak intact.")
                .font(.title2.weight(.bold))
            Text("That's one more time you resisted.")
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                onFinish(.resisted)
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}
