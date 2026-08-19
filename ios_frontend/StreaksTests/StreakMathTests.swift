import XCTest
@testable import Streaks

/// Exercises the pure day-count and longest-streak math (HANDOFF_02 §C). A fixed
/// gregorian calendar in a known time zone keeps these deterministic regardless of
/// where the test runs.
final class StreakMathTests: XCTestCase {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: - currentStreakDays

    func testStartedTodayIsZero() {
        let start = date(2026, 8, 18, hour: 8)
        let now = date(2026, 8, 18, hour: 23)
        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: calendar), 0)
    }

    func testNextCalendarDayIsOne() {
        let start = date(2026, 8, 18, hour: 23)
        let now = date(2026, 8, 19, hour: 1) // only two hours later, but a day boundary crossed
        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: calendar), 1)
    }

    func testNilStartIsZero() {
        XCTAssertEqual(StreakMath.currentStreakDays(since: nil, calendar: calendar), 0)
    }

    func testAcrossMonthBoundary() {
        let start = date(2026, 1, 30)
        let now = date(2026, 2, 2)
        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: calendar), 3)
    }

    func testAcrossDSTChangeCountsCalendarDays() {
        // US "spring forward" was 2026-03-08; the lost hour must not shift the day count.
        let start = date(2026, 3, 7)
        let now = date(2026, 3, 10)
        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: calendar), 3)
    }

    func testFutureStartClampsToZero() {
        let start = date(2026, 8, 20)
        let now = date(2026, 8, 18)
        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: calendar), 0)
    }

    func testHonorsSuppliedTimeZone() {
        // 2026-08-18 23:30 in New York is already 2026-08-19 in UTC, so the same
        // instant yields different day counts depending on the calendar's zone.
        let start = date(2026, 8, 18, hour: 12)
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 23, minute: 30))!

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!

        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: calendar), 0)
        XCTAssertEqual(StreakMath.currentStreakDays(since: start, now: now, calendar: utc), 1)
    }

    // MARK: - displayedLongestStreak

    func testDisplayedLongestPrefersStoredWhenLarger() {
        XCTAssertEqual(StreakMath.displayedLongestStreak(stored: 30, currentStreakDays: 12), 30)
    }

    func testDisplayedLongestPrefersCurrentInProgressRecord() {
        XCTAssertEqual(StreakMath.displayedLongestStreak(stored: 10, currentStreakDays: 14), 14)
    }
}
