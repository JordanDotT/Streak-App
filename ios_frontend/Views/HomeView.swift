import CoreData
import SwiftUI

/// Home screen (scaffold). Shows the single habit's day count + times-resisted and
/// the primary "Talk me out of it" CTA. Layout is intentionally simple and tolerant
/// of a future list of habits (§5.1). Interactions are wired in later PRs.
struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: HomeViewModel

    init(context: NSManagedObjectContext? = nil) {
        // Allow injection for previews/tests; fall back to the shared store.
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: ctx))
    }

    var body: some View {
        VStack(spacing: 24) {
            if let habit = viewModel.habit {
                VStack(spacing: 8) {
                    Text(habit.name ?? "Habit")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.currentStreakDays)")
                        .font(.system(size: 88, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("days clean")
                        .font(.title3)
                    Text("resisted \(viewModel.timesResisted) times")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    // Intervention deck lands in a later PR.
                } label: {
                    Text("Talk me out of it")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "No habit yet",
                    systemImage: "flag.checkered",
                    description: Text("Create-habit onboarding arrives in a later PR.")
                )
            }
        }
        .padding()
        .onAppear { viewModel.refresh() }
    }
}

#Preview {
    HomeView(context: PersistenceController.preview.container.viewContext)
}
