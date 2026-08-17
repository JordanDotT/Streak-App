import CoreData
import SwiftUI

/// CRUD + reordering for the habit's reflection prompts (§5.2 / §6).
struct EditQuestionsView: View {
    @StateObject private var viewModel: EditQuestionsViewModel

    @State private var newPrompt = ""
    @State private var editingQuestion: Question?
    @State private var editingText = ""

    init(habit: Habit, context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: EditQuestionsViewModel(context: context, habit: habit))
    }

    var body: some View {
        List {
            Section("Add a prompt") {
                HStack {
                    TextField("Write a reflection…", text: $newPrompt, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                    Button {
                        viewModel.add(newPrompt)
                        newPrompt = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Your prompts") {
                if viewModel.questions.isEmpty {
                    Text("No prompts yet. Add one above.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.questions) { question in
                        Button {
                            editingQuestion = question
                            editingText = question.text ?? ""
                        } label: {
                            Text(question.text ?? "")
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onDelete { viewModel.delete(at: $0) }
                    .onMove { viewModel.move(from: $0, to: $1) }
                }
            }
        }
        .navigationTitle("Edit prompts")
        .toolbar { EditButton() }
        .alert("Edit prompt", isPresented: editAlertBinding) {
            TextField("Prompt", text: $editingText)
            Button("Save") {
                if let question = editingQuestion {
                    viewModel.update(question, text: editingText)
                }
                editingQuestion = nil
            }
            Button("Cancel", role: .cancel) { editingQuestion = nil }
        }
    }

    private var editAlertBinding: Binding<Bool> {
        Binding(
            get: { editingQuestion != nil },
            set: { if !$0 { editingQuestion = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        EditQuestionsView(
            habit: PersistenceController.preview.container.viewContext.registeredObjects.compactMap { $0 as? Habit }.first!,
            context: PersistenceController.preview.container.viewContext
        )
    }
}
