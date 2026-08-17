import CoreData
import SwiftUI

/// First-run onboarding: name the habit, pick a category, set a start date.
/// Creating the habit flips `ContentView`'s fetch and reveals Home.
struct CreateHabitView: View {
    @StateObject private var viewModel: CreateHabitViewModel

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: CreateHabitViewModel(context: context))
    }

    var body: some View {
        Form {
            Section {
                TextField("What are you quitting?", text: $viewModel.name)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Text("Habit")
            } footer: {
                Text("e.g. \"Impulse spending\"")
            }

            Section("Category") {
                Picker("Category", selection: $viewModel.category) {
                    ForEach(HabitCategory.allCases) { category in
                        Text(category.label).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                DatePicker(
                    "Clean since",
                    selection: $viewModel.startDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
            } footer: {
                Text("Defaults to today. Set it earlier if your streak already started.")
            }

            Section {
                Button {
                    viewModel.save()
                } label: {
                    Text("Start tracking")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canSave)
            }
        }
        .navigationTitle("New habit")
    }
}

#Preview {
    NavigationStack {
        CreateHabitView(context: PersistenceController.preview.container.viewContext)
    }
}
