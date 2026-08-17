import Foundation

/// Central place for App Group + shared-store constants so the app target and the
/// (future) widget extension read the exact same identifiers. If the App Group ID
/// changes, change it here only.
enum AppGroup {
    /// Must match the App Group entitlement on every target that shares the store.
    static let identifier = "group.com.jordantam.streaks"

    /// Name of the Core Data model file (`Streaks.xcdatamodeld`), without extension.
    static let modelName = "Streaks"

    /// Shared container URL for the App Group, used to place the Core Data store
    /// where both the app and the widget can reach it.
    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)
        else {
            // Falls back to the app's own sandbox if the App Group capability isn't
            // enabled yet (e.g. before signing is configured). The widget won't see
            // this data — enable the App Groups capability in the Signing pane.
            return FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }
        return url
    }
}
