import WidgetKit
import SwiftUI

struct UntisScheduleEntry: TimelineEntry {
    let date: Date
    let dailySchedule: String
}

struct UntisScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> UntisScheduleEntry {
        UntisScheduleEntry(date: Date(), dailySchedule: "No schedule data")
    }

    func getSnapshot(in context: Context, completion: @escaping (UntisScheduleEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UntisScheduleEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadEntry(accountId: String? = nil) -> UntisScheduleEntry {
        return UntisScheduleEntry(
            date: Date(),
            dailySchedule: untisWidgetValue("daily_schedule", accountId: accountId) ?? "No schedule data"
        )
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisAccountScheduleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UntisScheduleEntry { UntisScheduleProvider().placeholder(in: context) }
    func snapshot(for configuration: UntisAccountIntent, in context: Context) async -> UntisScheduleEntry {
        UntisScheduleProvider().loadEntry(accountId: untisAccountId(configuration.account))
    }
    func timeline(for configuration: UntisAccountIntent, in context: Context) async -> Timeline<UntisScheduleEntry> {
        let entry = UntisScheduleProvider().loadEntry(accountId: untisAccountId(configuration.account))
        let update = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(update))
    }
}

struct UntisDailyScheduleWidget: Widget {
    let kind: String = "UntisWidgetDailySchedule"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountScheduleProvider()) { entry in
                UntisDailyScheduleView(entry: entry)
            }
        } else {
            StaticConfiguration(kind: kind, provider: UntisScheduleProvider()) { entry in
                UntisDailyScheduleView(entry: entry)
            }
        }
        .configurationDisplayName("Daily Schedule")
        .description("Shows your full day schedule.")
        .supportedFamilies([.systemLarge])
    }
}

struct UntisDailyScheduleView: View {
    var entry: UntisScheduleEntry

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
                    Text(entry.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if entry.dailySchedule.isEmpty {
                    Text("No schedule data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(entry.dailySchedule)
                        .font(.caption)
                        .lineLimit(nil)
                }

                Spacer()
            }
            .padding()
        }
    }
}
