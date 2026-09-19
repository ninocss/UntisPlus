import WidgetKit
import SwiftUI
import AppIntents
import ActivityKit
import ExpressiveUI

/// Material 3 colour roles mapped onto a single Untis+ accent, so every
/// ExpressiveUI component below the theme picks up the app's accent.
enum UntisExpressiveTheme {
    static func accent(_ color: Color) -> ExpressiveColors {
        ExpressiveColors(
            primary: color,
            onPrimary: .white,
            onPrimaryContainer: Color(uiColor: .white),
            surfaceContainerHighest: color.opacity(0.24),
            outline: color.opacity(0.6),
            primaryContainer: color.opacity(0.28),
            surfaceContainer: color.opacity(0.14),
            onSurfaceVariant: Color(uiColor: .secondaryLabel),
            onSurface: Color(uiColor: .label),
            surfaceContainerLow: color.opacity(0.10),
            secondaryContainer: color.opacity(0.16),
            onSecondaryContainer: Color(uiColor: .label),
            outlineVariant: color.opacity(0.38),
            tertiaryContainer: color.opacity(0.20),
            onTertiaryContainer: Color(uiColor: .label)
        )
    }

    /// Alarm Live Activity: red, matching the alarm alert UI.
    static let alarm = accent(Color(uiColor: .systemRed))

    /// Lesson Live Activity: blue, matching the schedule.
    static let lesson = accent(Color(uiColor: .systemBlue))
}

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

/// Flutter publishes this catalog through HomeWidget whenever the in-app
/// language changes. WidgetKit can therefore render app-language fallbacks
/// even while the Flutter engine is not running.
func untisWidgetCopy(_ key: String, fallback: String) -> String {
    let defaults = UserDefaults(suiteName: "group.com.ninocss.untisplus") ?? UserDefaults.standard
    guard let raw = defaults.string(forKey: "widget_native_copy"),
          let data = raw.data(using: .utf8),
          let values = try? JSONSerialization.jsonObject(with: data) as? [String: String],
          let value = values[key], !value.isEmpty
    else { return fallback }
    return value
}

func untisWidgetURL(accountId: String) -> URL {
    var components = URLComponents()
    components.scheme = "untisplus"
    components.host = "widget"
    if !accountId.isEmpty {
        components.queryItems = [URLQueryItem(name: "account", value: accountId)]
    }
    return components.url ?? URL(string: "untisplus://widget")!
}

struct UntisStatusPill: View {
    let text: String
    @Environment(\.expressiveColors) private var colors
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(colors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(colors.primaryContainer))
    }
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
    nonisolated(unsafe) static var title: LocalizedStringResource = "widget.account.title"
    nonisolated(unsafe) static var description = IntentDescription("Wähle das Untis+-Konto für dieses Widget.")
    @Parameter(title: "widget.account.parameter", optionsProvider: UntisAccountOptions()) var account: String?

    init() {}
}

@available(iOSApplicationExtension 17.0, *)
func untisAccountId(_ selection: String?) -> String? {
    selection?.split(separator: "|", maxSplits: 1).first.map(String.init)
}

struct UntisLessonEntry: TimelineEntry {
    let date: Date
    let accountId: String
    let accountLabel: String
    let currentLesson: String
    let nextLesson: String
    let timeRemaining: String
    let status: String
    let dailySchedule: String
}

struct UntisLessonProvider: TimelineProvider {
    func placeholder(in context: Context) -> UntisLessonEntry {
        UntisLessonEntry(
            date: Date(),
            accountId: "",
            accountLabel: "Untis+",
            currentLesson: untisWidgetCopy("fallbackCurrent", fallback: "Freistunde"),
            nextLesson: untisWidgetCopy("fallbackNext", fallback: "Heute keine weitere Stunde"),
            timeRemaining: "",
            status: "",
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
            accountId: accountId ?? "",
            accountLabel: untisWidgetValue("account_label", accountId: accountId) ?? "Untis+",
            currentLesson: untisWidgetValue("current_lesson", accountId: accountId) ?? untisWidgetCopy("fallbackCurrent", fallback: "Freistunde"),
            nextLesson: untisWidgetValue("next_lesson", accountId: accountId) ?? untisWidgetCopy("fallbackNext", fallback: "Heute keine weitere Stunde"),
            timeRemaining: untisWidgetValue("time_remaining", accountId: accountId) ?? "",
            status: untisWidgetValue("status", accountId: accountId) ?? "",
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
        .configurationDisplayName(LocalizedStringKey("widget.current.name"))
        .description(LocalizedStringKey("widget.current.description"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisCurrentLessonView: View {
    var entry: UntisLessonEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(entry.accountLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if !entry.status.isEmpty {
                    UntisStatusPill(text: entry.status)
                }
            }

            Text(entry.currentLesson)
                .font(.headline)
                .lineLimit(2)

            Text(entry.nextLesson)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)

            HStack {
                if !entry.timeRemaining.isEmpty {
                    UntisStatusPill(text: entry.timeRemaining)
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

struct UntisSummaryEntry: TimelineEntry {
    let date: Date
    let accountId: String
    let title: String
    let body: String
    let accountLabel: String
    let status: String
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
        UntisSummaryEntry(
            date: Date(),
            accountId: accountId ?? "",
            title: title,
            body: untisWidgetValue(field, accountId: accountId) ?? untisWidgetCopy("fallbackRefreshing", fallback: "Wird aktualisiert …"),
            accountLabel: untisWidgetValue("account_label", accountId: accountId) ?? "Untis+",
            status: untisWidgetValue("status", accountId: accountId) ?? ""
        )
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

@available(iOSApplicationExtension 17.0, *)
struct UntisSummaryView: View {
    let entry: UntisSummaryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(entry.title).font(.caption).fontWeight(.bold).foregroundStyle(.blue)
                Spacer(minLength: 8)
                Text(entry.accountLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(entry.body).font(.headline).lineLimit(2)
            Spacer(minLength: 0)
            HStack {
                if !entry.status.isEmpty {
                    UntisStatusPill(text: entry.status)
                }
                Spacer()
            }
        }.padding()
        .expressiveColors(UntisExpressiveTheme.lesson)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        .widgetURL(untisWidgetURL(accountId: entry.accountId))
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisHomeworkWidget: Widget {
    let kind = "UntisWidgetHomework"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountSummaryProvider(title: untisWidgetCopy("titleHomework", fallback: "AUFGABEN"), field: "homework_summary")) { UntisSummaryView(entry: $0) }
            .configurationDisplayName(LocalizedStringKey("widget.homework.name"))
            .description(LocalizedStringKey("widget.homework.description"))
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct UntisNotificationsWidget: Widget {
    let kind = "UntisWidgetNotifications"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UntisAccountIntent.self, provider: UntisAccountSummaryProvider(title: untisWidgetCopy("titleNotices", fallback: "MITTEILUNGEN"), field: "notification_summary")) { UntisSummaryView(entry: $0) }
            .configurationDisplayName(LocalizedStringKey("widget.notices.name"))
            .description(LocalizedStringKey("widget.notices.description"))
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
    nonisolated(unsafe) static var title: LocalizedStringResource = "widget.profile.title"
    @Parameter(title: "widget.profile.parameter", optionsProvider: UntisWidgetProfileOptions()) var profile: String?
    init() {}
}

struct UntisCustomEntry: TimelineEntry {
    let date: Date
    let accountId: String
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
        date: Date(), accountId: account ?? "", blocks: (item["blocks"] as? [String]) ?? ["current", "next", "status"], values: values,
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
            .configurationDisplayName(LocalizedStringKey("widget.custom.name"))
            .description(LocalizedStringKey("widget.custom.description"))
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
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
        .widgetURL(untisWidgetURL(accountId: entry.accountId))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Activity (iOS 16.1+)
//
// Mirrors Android's ongoing "current lesson" notification: a lock-screen /
// Dynamic Island presentation fed from the app through ActivityKit.
// ─────────────────────────────────────────────────────────────────────────────

@available(iOSApplicationExtension 16.1, *)
struct UntisLessonActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let lessonName: String
        let nextLesson: String
        let timeRemaining: String
        let lessonStartMs: Int64?
        let lessonEndMs: Int64?
    }
    init() {}
}

@available(iOSApplicationExtension 16.1, *)
func untisLessonCountdownText(_ state: UntisLessonActivityAttributes.ContentState) -> Text {
    if let startMs = state.lessonStartMs, let endMs = state.lessonEndMs {
        let start = Date(timeIntervalSince1970: Double(startMs) / 1000)
        let end = Date(timeIntervalSince1970: Double(endMs) / 1000)
        if start < end, Date() < end {
            return Text(timerInterval: start...end, countsDown: true)
        }
    }
    return Text(state.timeRemaining)
}

@available(iOSApplicationExtension 16.1, *)
func untisLessonProgress(_ state: UntisLessonActivityAttributes.ContentState) -> Double {
    guard let startMs = state.lessonStartMs, let endMs = state.lessonEndMs, endMs > startMs else { return 0 }
    let start = Date(timeIntervalSince1970: Double(startMs) / 1000)
    let end = Date(timeIntervalSince1970: Double(endMs) / 1000)
    let now = Date()
    guard now > start else { return 0 }
    return min(max(now.timeIntervalSince(start) / end.timeIntervalSince(start), 0), 1)
}

@available(iOSApplicationExtension 16.1, *)
struct UntisLessonLiveActivityView: View {
    let context: ActivityViewContext<UntisLessonActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            ExpressiveCircularProgressIndicator(progress: untisLessonProgress(context.state))
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.lessonName)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.nextLesson)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            untisLessonCountdownText(context.state)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
                .lineLimit(1)
        }
        .padding()
        .expressiveColors(UntisExpressiveTheme.lesson)
        .activityBackgroundTint(Color(UIColor.systemBackground))
    }
}

@available(iOSApplicationExtension 16.1, *)
func untisLiveActivityCompactLabel(_ value: String) -> String {
    let compact = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !compact.isEmpty else { return "" }
    let prefix = String(compact.prefix(3)).uppercased()
    return prefix
}

@available(iOSApplicationExtension 16.1, *)
struct UntisLessonActivityConfiguration: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UntisLessonActivityAttributes.self) { context in
            UntisLessonLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Group {
                        Text(context.state.lessonName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .expressiveColors(UntisExpressiveTheme.lesson)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Group {
                        untisLessonCountdownText(context.state)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                    }
                    .expressiveColors(UntisExpressiveTheme.lesson)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Group {
                        Text(context.state.nextLesson)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .expressiveColors(UntisExpressiveTheme.lesson)
                }
            } compactLeading: {
                Group {
                    Text(untisLiveActivityCompactLabel(context.state.lessonName))
                        .font(.headline)
                        .lineLimit(1)
                }
                .expressiveColors(UntisExpressiveTheme.lesson)
            } compactTrailing: {
                Group {
                    untisLessonCountdownText(context.state)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
                .expressiveColors(UntisExpressiveTheme.lesson)
            } minimal: {
                Group {
                    untisLessonCountdownText(context.state)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
                .expressiveColors(UntisExpressiveTheme.lesson)
            }
            .keylineTint(.blue)
        }
    }
}
