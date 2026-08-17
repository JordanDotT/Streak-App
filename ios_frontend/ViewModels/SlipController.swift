import CoreData
import SwiftUI

/// Coordinates the swipe-to-slip flow with an undo window (§5.4). A slip is applied
/// immediately (day count → 0) and finalized after a short delay unless undone. Any
/// screen that can trigger a slip hosts one of these and overlays `slipSnackbar`.
@MainActor
final class SlipController: ObservableObject {
    /// Non-nil while an applied slip can still be undone. Drives the snackbar.
    @Published var pending: SlipToken?

    /// Seconds the undo snackbar stays before the slip is finalized.
    let autoConfirmSeconds: UInt64 = 5

    private let repository: HabitRepository
    private var confirmTask: Task<Void, Never>?

    init(context: NSManagedObjectContext) {
        repository = HabitRepository(context: context)
    }

    /// Applies a slip and starts the undo countdown.
    func slip(_ habit: Habit) {
        // Finalize any still-pending slip before starting a new one.
        confirmNow()
        pending = repository.performSlip(on: habit)
        confirmTask = Task { [weak self] in
            guard let seconds = self?.autoConfirmSeconds else { return }
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.confirmNow()
        }
    }

    /// Rolls the pending slip back — the streak is restored as if it never happened.
    func undo() {
        confirmTask?.cancel()
        confirmTask = nil
        if let token = pending {
            repository.undoSlip(token)
        }
        pending = nil
    }

    /// Finalizes the pending slip now (also called when the countdown elapses).
    func confirmNow() {
        confirmTask?.cancel()
        confirmTask = nil
        if let token = pending {
            repository.confirmSlip(token)
        }
        pending = nil
    }
}
