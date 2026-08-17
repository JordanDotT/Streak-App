import CoreData
import SwiftUI
import WidgetKit

// MARK: - Timeline entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let hasHabit: Bool
    let habitName: String
    let currentStreakDays: Int
    let timesResisted: Int
    let longestStreakDays: Int

    static let placeholder = StreakEntry(
        date: Date(),
        hasHabit: true,
        habitName: "Impulse spending",
        currentStreakDays: 12,
        timesResisted: 8,
        longestStreakDays: 20
    )

    static let empty = StreakEntry(
        date: Date(),
        hasHabit: false,
        habitName: "",
        currentStreakDays: 0,
        timesResisted: 0,
        longestStreakDays: 0
    )
}

// MARK: - Provider

/// Reads the shared App Group store and refreshes at the day boundary so the day
/// count rolls over at midnight (§8). MVP targets the single primary habit.
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = currentEntry()
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func currentEntry() -> StreakEntry {
        let context = PersistenceController.shared.container.viewContext

        let request = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = 1

        guard let habit = (try? context.fetch(request))?.first else {
            return .empty
        }

        let days = StreakMath.currentStreakDays(since: habit.currentStreakStart)

        let resistRequest = InterventionSession.fetchRequest()
        resistRequest.predicate = NSPredicate(
            format: "habit == %@ AND outcome == %@",
            habit, InterventionOutcome.resisted.rawValue
        )
        let resisted = (try? context.count(for: resistRequest)) ?? 0

        let longest = StreakMath.displayedLongestStreak(
            stored: Int(habit.longestStreakDays),
            currentStreakDays: days
        )

        return StreakEntry(
            date: Date(),
            hasHabit: true,
            habitName: habit.name ?? "Habit",
            currentStreakDays: days,
            timesResisted: resisted,
            longestStreakDays: longest
        )
    }
}

// MARK: - Views

struct StreaksWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        if !entry.hasHabit {
            emptyState
        } else {
            switch family {
            case .systemMedium: MediumView(entry: entry)
            case .accessoryCircular: CircularView(entry: entry)
            case .accessoryInline: Text("\(entry.currentStreakDays)d clean")
            default: SmallView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "flag.checkered")
            Text("No habit yet")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
    }
}

private struct SmallView: View {
    let entry: StreakEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.habitName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("\(entry.currentStreakDays)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text("days clean")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MediumView: View {
    let entry: StreakEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text("\(entry.currentStreakDays)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("days clean")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                stat("Resisted", "\(entry.timesResisted)")
                stat("Longest", "\(entry.longestStreakDays)d")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct CircularView: View {
    let entry: StreakEntry
    var body: some View {
        VStack(spacing: 0) {
            Text("\(entry.currentStreakDays)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("days")
                .font(.system(size: 10))
        }
    }
}

// MARK: - Widget

struct StreaksWidget: Widget {
    let kind = "StreaksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StreaksWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Your current days-clean streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}
