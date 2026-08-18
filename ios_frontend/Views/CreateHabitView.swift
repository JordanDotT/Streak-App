import CoreData
import SwiftUI

/// The habit form. In create mode it's first-run onboarding — saving flips
/// `ContentView`'s fetch and reveals Home. In edit mode (`habit` supplied) it's
/// presented over Habit Detail, saving/deleting then dismisses (§B).
struct CreateHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateHabitViewModel
    @State private var showingDeleteConfirmation = false

    init(context: NSManagedObjectContext, habit: Habit? = nil) {
        _viewModel = StateObject(wrappedValue: CreateHabitViewModel(context: context, habit: habit))
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
                Text(viewModel.isEditing
                     ? "Changing this reshapes your current day count."
                     : "Defaults to today. Set it earlier if your streak already started.")
            }

            Section {
                Button {
                    viewModel.save()
                    if viewModel.isEditing { dismiss() }
                } label: {
                    Text(viewModel.isEditing ? "Save changes" : "Start tracking")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canSave)
            }

            if viewModel.isEditing {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete habit")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit habit" : "New habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .confirmationDialog(
            "Delete this habit?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the habit and its history. This can't be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        CreateHabitView(context: PersistenceController.preview.container.viewContext)
    }
}
