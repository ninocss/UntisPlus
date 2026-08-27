import WidgetKit
import SwiftUI

struct UntisLessonEntry: TimelineEntry {
    let date: Date
    let currentLesson: String
    let nextLesson: String
    let timeRemaining: String
    let dailySchedule: String
}

struct UntisLessonProvider: TimelineProvider {
    func placeholder(in context: Context) -> UntisLessonEntry {
        UntisLessonEntry(
            date: Date(),
            currentLesson: "No Lesson",
            nextLesson: "-",
            timeRemaining: "-",
            dailySchedule: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UntisLessonEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UntisLessonEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> UntisLessonEntry {
        let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
        return UntisLessonEntry(
            date: Date(),
            currentLesson: defaults.string(forKey: "current_lesson") ?? "No Lesson",
            nextLesson: defaults.string(forKey: "next_lesson") ?? "-",
            timeRemaining: defaults.string(forKey: "time_remaining") ?? "-",
            dailySchedule: defaults.string(forKey: "daily_schedule") ?? ""
        )
    }
}

struct UntisCurrentLessonWidget: Widget {
    let kind: String = "UntisWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UntisLessonProvider()) { entry in
            UntisCurrentLessonView(entry: entry)
        }
        .configurationDisplayName("Current Lesson")
        .description("Shows your current and next lesson.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UntisCurrentLessonView: View {
    var entry: UntisLessonEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Untis+")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Spacer()
                    Text(entry.timeRemaining)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Now")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.currentLesson)
                        .font(.headline)
                        .lineLimit(2)
                }

                if family == .systemMedium {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(entry.nextLesson)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}
