import CoreData

/// Owns the Core Data stack. The persistent store lives in the App Group container
/// (see `AppGroup`) so the app and the widget extension read the same data.
struct PersistenceController {
    static let shared = PersistenceController()

    /// In-memory stack for SwiftUI previews and tests — never touches disk.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Seed a sample habit so previews have something to render.
        let context = controller.container.viewContext
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Impulse spending"
        habit.category = "spending"
        habit.createdAt = Date()
        habit.currentStreakStart = Calendar.current.date(byAdding: .day, value: -12, to: Date())
        habit.longestStreakDays = 12
        try? context.save()
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: AppGroup.modelName)

        if inMemory {
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        } else {
            let storeURL = AppGroup.containerURL
                .appendingPathComponent("\(AppGroup.modelName).sqlite")
            container.persistentStoreDescriptions = [
                NSPersistentStoreDescription(url: storeURL)
            ]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Fatal only in development; a real migration/storage strategy comes
                // with the first schema change beyond the MVP scaffold.
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
