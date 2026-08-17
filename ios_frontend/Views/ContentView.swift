import SwiftUI

/// Root view. For the scaffold it hosts Home directly; navigation to Habit Detail,
/// the intervention deck, and onboarding arrives in later PRs.
struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
