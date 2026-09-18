import WidgetKit
import SwiftUI
import ExpressiveUI

struct UntisScheduleEntry: TimelineEntry {
    let date: Date
    let accountId: String
    let accountLabel: String
    let status: String
    let dailySchedule: String
}

struct UntisScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> UntisScheduleEntry {
        UntisScheduleEntry(date: Date(), accountId: "", accountLabel: "Untis+", status: "", dailySchedule: untisWidgetCopy("fallbackSchedule", fallback: "Stundenplan wird geladen …"))
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
            accountId: accountId ?? "",
            accountLabel: untisWidgetValue("account_label", accountId: accountId) ?? "Untis+",
            status: untisWidgetValue("status", accountId: accountId) ?? "",
            dailySchedule: untisWidgetValue("daily_schedule", accountId: accountId) ?? untisWidgetCopy("fallbackSchedule", fallback: "Stundenplan wird geladen …")
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

@available(iOSApplicationExtension 17.0, *)
struct UntisDailyScheduleWidget: Widget {
    let kind: String = "UntisWidgetDailySchedule"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountScheduleProvider()) { entry in
            UntisDailyScheduleView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("widget.schedule.name"))
        .description(LocalizedStringKey("widget.schedule.description"))
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisDailyScheduleView: View {
    var entry: UntisScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(untisWidgetCopy("today", fallback: "HEUTE"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Spacer(minLength: 8)
                Text(entry.accountLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if entry.dailySchedule.isEmpty {
                Text(untisWidgetCopy("fallbackSchedule", fallback: "Stundenplan wird geladen …"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(entry.dailySchedule)
                    .font(.caption)
                    .lineLimit(nil)
            }

            Spacer(minLength: 0)

            HStack {
                if !entry.status.isEmpty {
                    UntisStatusPill(text: entry.status)
                }
                Spacer()
            }
        }
        .padding()
        .expressiveColors(UntisExpressiveTheme.lesson)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        .widgetURL(untisWidgetURL(accountId: entry.accountId))
    }
}
