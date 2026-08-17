import Foundation

/// Pure functions for the two derived headline numbers. Kept free of Core Data so
/// they're trivially unit-testable and reusable by the widget.
enum StreakMath {
    /// Days since the current streak started, in whole calendar days.
    /// Day 0 = started today. Uses the user's calendar so it rolls over at midnight.
    static func currentStreakDays(
        since start: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard let start else { return 0 }
        let startDay = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
        return max(0, days)
    }

    /// What Habit Detail shows for "longest streak": the stored best never
    /// undercounts an in-progress record streak (§5.2 / §10.8).
    static func displayedLongestStreak(
        stored longestStreakDays: Int,
        currentStreakDays: Int
    ) -> Int {
        max(longestStreakDays, currentStreakDays)
    }
}
