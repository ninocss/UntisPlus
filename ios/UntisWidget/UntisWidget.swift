import WidgetKit
import SwiftUI
import AppIntents

func untisWidgetValue(_ key: String, accountId: String? = nil) -> String? {
    let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
    let active = accountId ?? defaults.string(forKey: "widget_active_account") ?? "active"
    return defaults.string(forKey: "widget.\(active).\(key)") ?? defaults.string(forKey: key)
}

@available(iOSApplicationExtension 17.0, *)
struct UntisAccountOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
        guard let raw = defaults.string(forKey: "widget_accounts"),
              let data = raw.data(using: .utf8),
              let values = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return values.compactMap { item in
            guard let id = item["id"] as? String, !id.isEmpty else { return nil }
            let label = (item["label"] as? String) ?? "Untis+"
            return "\(id)|\(label)"
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisAccountIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Konto"
    static var description = IntentDescription("Wähle das Untis+-Konto für dieses Widget.")
    @Parameter(title: "Konto", optionsProvider: UntisAccountOptions()) var account: String?

    init() {}
}

@available(iOSApplicationExtension 17.0, *)
func untisAccountId(_ selection: String?) -> String? {
    selection?.split(separator: "|", maxSplits: 1).first.map(String.init)
}

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

    func loadEntry(accountId: String? = nil) -> UntisLessonEntry {
        return UntisLessonEntry(
            date: Date(),
            currentLesson: untisWidgetValue("current_lesson", accountId: accountId) ?? "No lesson",
            nextLesson: untisWidgetValue("next_lesson", accountId: accountId) ?? "-",
            timeRemaining: untisWidgetValue("time_remaining", accountId: accountId) ?? "-",
            dailySchedule: untisWidgetValue("daily_schedule", accountId: accountId) ?? ""
        )
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisAccountLessonProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UntisLessonEntry { UntisLessonProvider().placeholder(in: context) }
    func snapshot(for configuration: UntisAccountIntent, in context: Context) async -> UntisLessonEntry {
        UntisLessonProvider().loadEntry(accountId: untisAccountId(configuration.account))
    }
    func timeline(for configuration: UntisAccountIntent, in context: Context) async -> Timeline<UntisLessonEntry> {
        let entry = UntisLessonProvider().loadEntry(accountId: untisAccountId(configuration.account))
        let update = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(update))
    }
}

struct UntisCurrentLessonWidget: Widget {
    let kind: String = "UntisWidget"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountLessonProvider()) { entry in
                UntisCurrentLessonView(entry: entry)
            }
        } else {
            StaticConfiguration(kind: kind, provider: UntisLessonProvider()) { entry in
                UntisCurrentLessonView(entry: entry)
            }
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

struct UntisSummaryEntry: TimelineEntry {
    let date: Date
    let title: String
    let body: String
}

struct UntisStaticSummaryProvider: TimelineProvider {
    let title: String
    let field: String
    func placeholder(in context: Context) -> UntisSummaryEntry { load() }
    func getSnapshot(in context: Context, completion: @escaping (UntisSummaryEntry) -> Void) { completion(load()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<UntisSummaryEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(Calendar.current.date(byAdding: .minute, value: 30, to: Date())!)))
    }
    func load(accountId: String? = nil) -> UntisSummaryEntry {
        UntisSummaryEntry(date: Date(), title: title, body: untisWidgetValue(field, accountId: accountId) ?? "Wird aktualisiert …")
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisAccountSummaryProvider: AppIntentTimelineProvider {
    let title: String
    let field: String
    func placeholder(in context: Context) -> UntisSummaryEntry { UntisStaticSummaryProvider(title: title, field: field).load() }
    func snapshot(for configuration: UntisAccountIntent, in context: Context) async -> UntisSummaryEntry {
        UntisStaticSummaryProvider(title: title, field: field).load(accountId: untisAccountId(configuration.account))
    }
    func timeline(for configuration: UntisAccountIntent, in context: Context) async -> Timeline<UntisSummaryEntry> {
        let entry = UntisStaticSummaryProvider(title: title, field: field).load(accountId: untisAccountId(configuration.account))
        return Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .minute, value: 30, to: Date())!))
    }
}

struct UntisSummaryView: View {
    let entry: UntisSummaryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title).font(.caption).fontWeight(.bold).foregroundStyle(.tint)
            Text(entry.body).font(.headline).lineLimit(2)
            Spacer()
        }.padding()
    }
}

struct UntisHomeworkWidget: Widget {
    let kind = "UntisWidgetHomework"
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountSummaryProvider(title: "AUFGABEN", field: "homework_summary")) { UntisSummaryView(entry: $0) }
        } else {
            StaticConfiguration(kind: kind, provider: UntisStaticSummaryProvider(title: "AUFGABEN", field: "homework_summary")) { UntisSummaryView(entry: $0) }
        }
    }
}

struct UntisNotificationsWidget: Widget {
    let kind = "UntisWidgetNotifications"
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountSummaryProvider(title: "MITTEILUNGEN", field: "notification_summary")) { UntisSummaryView(entry: $0) }
        } else {
            StaticConfiguration(kind: kind, provider: UntisStaticSummaryProvider(title: "MITTEILUNGEN", field: "notification_summary")) { UntisSummaryView(entry: $0) }
        }
    }
}
