import Foundation

/// Outcome of a "Talk me out of it" session. Stored as the raw string on
/// `InterventionSession.outcome`. Times-resisted = count of `.resisted` sessions.
enum InterventionOutcome: String {
    case resisted
    case gaveIn
}
