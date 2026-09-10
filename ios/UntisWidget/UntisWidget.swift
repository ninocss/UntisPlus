import WidgetKit
import SwiftUI
import AppIntents

func untisWidgetValue(_ key: String, accountId: String? = nil) -> String? {
    let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
    let active = accountId ?? defaults.string(forKey: "widget_active_account") ?? "active"
    if let scoped = defaults.string(forKey: "widget.\(active).\(key)") {
        return scoped
    }
    // A widget explicitly bound to another account must not fall back to the
    // active account's legacy payload while its first refresh is pending.
    if accountId != nil {
        return nil
    }
    return defaults.string(forKey: key)
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

@available(iOSApplicationExtension 17.0, *)
struct UntisCurrentLessonWidget: Widget {
    let kind: String = "UntisWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountLessonProvider()) { entry in
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

@available(iOSApplicationExtension 17.0, *)
struct UntisHomeworkWidget: Widget {
    let kind = "UntisWidgetHomework"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountSummaryProvider(title: "AUFGABEN", field: "homework_summary")) { UntisSummaryView(entry: $0) }
            .configurationDisplayName("Aufgaben")
            .description("Zeigt deine aktuellen Aufgaben.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisNotificationsWidget: Widget {
    let kind = "UntisWidgetNotifications"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountSummaryProvider(title: "MITTEILUNGEN", field: "notification_summary")) { UntisSummaryView(entry: $0) }
            .configurationDisplayName("Mitteilungen")
            .description("Zeigt deine aktuellen Mitteilungen.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisWidgetProfileOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
        guard let raw = defaults.string(forKey: "widget_configurations_v1"),
              let data = raw.data(using: .utf8),
              let profiles = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return profiles.compactMap { profile in
            guard let id = profile["id"] as? String, !id.isEmpty else { return nil }
            return "\(id)|\((profile["name"] as? String) ?? "Widget")"
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisWidgetProfileIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget-Profil"
    @Parameter(title: "Profil", optionsProvider: UntisWidgetProfileOptions()) var profile: String?
    init() {}
}

struct UntisCustomEntry: TimelineEntry {
    let date: Date
    let blocks: [String]
    let values: [String: String]
    let background: Int
    let accent: Int
    let text: Int
    let opacity, radius, scale: Double
    let icons: Bool
}

func untisCustomColor(_ raw: Int, opacity: Double = 1) -> Color {
    let value = UInt32(truncatingIfNeeded: raw)
    return Color(red: Double((value >> 16) & 0xff) / 255, green: Double((value >> 8) & 0xff) / 255, blue: Double(value & 0xff) / 255, opacity: opacity)
}

func untisCustomEntry(profile: String?) -> UntisCustomEntry {
    let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
    let selected = profile?.split(separator: "|", maxSplits: 1).first.map(String.init)
    let profiles: [[String: Any]] = {
        guard let raw = defaults.string(forKey: "widget_configurations_v1"), let data = raw.data(using: .utf8) else { return [] }
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }()
    let item = profiles.first { ($0["id"] as? String) == selected } ?? [:]
    let account = item["accountId"] as? String
    let fields = ["current_lesson", "next_lesson", "daily_schedule", "homework_summary", "exam_summary", "notification_summary", "account_label", "status"]
    var values: [String: String] = [:]
    for field in fields { values[field] = untisWidgetValue(field, accountId: account) ?? "" }
    return UntisCustomEntry(
        date: Date(), blocks: (item["blocks"] as? [String]) ?? ["current", "next", "status"], values: values,
        background: item["backgroundColor"] as? Int ?? Int(0xFF171C25), accent: item["accentColor"] as? Int ?? Int(0xFF8AB4F8), text: item["textColor"] as? Int ?? Int(0xFFF7F9FF),
        opacity: item["opacity"] as? Double ?? 0.94, radius: item["cornerRadius"] as? Double ?? 24, scale: item["textScale"] as? Double ?? 1, icons: item["showIcons"] as? Bool ?? true)
}

@available(iOSApplicationExtension 17.0, *)
struct UntisCustomProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UntisCustomEntry { untisCustomEntry(profile: nil) }
    func snapshot(for configuration: UntisWidgetProfileIntent, in context: Context) async -> UntisCustomEntry { untisCustomEntry(profile: configuration.profile) }
    func timeline(for configuration: UntisWidgetProfileIntent, in context: Context) async -> Timeline<UntisCustomEntry> {
        Timeline(entries: [untisCustomEntry(profile: configuration.profile)], policy: .after(Calendar.current.date(byAdding: .minute, value: 15, to: Date())!))
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisCustomWidget: Widget {
    let kind = "UntisWidgetCustom"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisWidgetProfileIntent.self, provider: UntisCustomProvider()) { UntisCustomView(entry: $0) }
            .configurationDisplayName("Untis+ Custom")
            .description("Dein eigenes Untis+-Widget.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisCustomView: View {
    let entry: UntisCustomEntry
    func value(_ block: String) -> String {
        let keys = ["current": "current_lesson", "next": "next_lesson", "schedule": "daily_schedule", "homework": "homework_summary", "exams": "exam_summary", "notices": "notification_summary", "account": "account_label", "status": "status"]
        return entry.values[keys[block] ?? "status"] ?? ""
    }
    func icon(_ block: String) -> String { ["current": "play.circle.fill", "next": "forward.fill", "schedule": "list.bullet", "homework": "checklist", "exams": "calendar", "notices": "bell", "account": "person.circle", "status": "clock"][block] ?? "square.grid.2x2" }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: entry.radius).fill(untisCustomColor(entry.background, opacity: entry.opacity))
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(entry.blocks.prefix(4).enumerated()), id: \.offset) { index, block in
                    HStack(alignment: .top, spacing: 6) {
                        if entry.icons { Image(systemName: icon(block)).foregroundStyle(untisCustomColor(entry.accent)).font(.system(size: 13 * entry.scale)) }
                        Text(value(block)).font(.system(size: (index == 0 ? 17 : 13) * entry.scale, weight: index == 0 ? .bold : .medium)).foregroundStyle(index == 0 ? untisCustomColor(entry.accent) : untisCustomColor(entry.text)).lineLimit(block == "schedule" ? 3 : 2)
                    }
                }
                Spacer(minLength: 0)
            }.padding()
        }.containerBackground(for: .widget) { Color.clear }
    }
}
