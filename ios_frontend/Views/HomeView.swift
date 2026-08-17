import CoreData
import SwiftUI

/// Home (§5.1): the single habit's day count + times-resisted and the primary
/// "Talk me out of it" CTA. Tap the streak card to open Habit Detail.
struct HomeView: View {
    @ObservedObject var habit: Habit
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var slip: SlipController
    @State private var showingDeck = false

    private let context: NSManagedObjectContext

    init(habit: Habit) {
        self.habit = habit
        let ctx = habit.managedObjectContext ?? PersistenceController.shared.container.viewContext
        self.context = ctx
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: ctx, habit: habit))
        _slip = StateObject(wrappedValue: SlipController(context: ctx))
    }

    private var currentDays: Int {
        StreakMath.currentStreakDays(since: habit.currentStreakStart)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            NavigationLink {
                HabitDetailView(habit: habit)
            } label: {
                VStack(spacing: 8) {
                    Text(habit.name ?? "Habit")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(currentDays)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("days clean")
                        .font(.title3)
                    Text("resisted \(viewModel.timesResisted) times")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showingDeck = true
            } label: {
                Text("Talk me out of it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .navigationTitle("Streaks")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingDeck) {
            InterventionDeckView(habit: habit, context: context) { outcome in
                switch outcome {
                case .resisted:
                    viewModel.refresh()
                case .gaveIn:
                    slip.slip(habit)
                }
            }
        }
        .slipSnackbar(slip)
        .onAppear { viewModel.refresh() }
    }
}

#Preview {
    NavigationStack {
        HomeView(habit: PersistenceController.preview.container.viewContext
            .registeredObjects.compactMap { $0 as? Habit }.first!)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
