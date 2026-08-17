import CoreData
import SwiftUI

/// Root view. Routes to onboarding when there's no habit yet, otherwise Home.
/// The `@FetchRequest` makes the swap automatic the moment a habit is created.
struct ContentView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Habit.createdAt, order: .forward)]
    )
    private var habits: FetchedResults<Habit>

    var body: some View {
        NavigationStack {
            if let habit = habits.first {
                HomeView(habit: habit)
            } else {
                CreateHabitView(context: context)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
