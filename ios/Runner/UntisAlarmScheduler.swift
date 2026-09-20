import UIKit
@preconcurrency import UserNotifications
import BackgroundTasks

/// Native, durable scheduling layer for iOS alarms.
///
/// Mirrors `AlarmScheduler`/`AlarmAlertService` in `android/.../AlarmSystem.kt`:
/// Dart supplies configuration through the `untisplus/alarm` channel and iOS
/// owns wake-up through local notifications. iOS cannot show a full-screen
/// wake UI, pick arbitrary ringtones or guarantee exact background refreshes;
/// the closest equivalents are time-sensitive alerts, the system default
/// sound and opportunistic `BGAppRefreshTask` runs.
enum UntisAlarmScheduler {
    static let channelIdentifier = "untisplus/alarm_refresh"
    static let refreshIdentifier = "com.ninocss.untisplus.alarmRefresh"
    static let alarmCategory = "untis_alarm"
    static let snoozeActionID = "snooze"
    static let dismissActionID = "dismiss"

    private static let prefix = "untis.alarm."
    nonisolated(unsafe) private static let suite = UserDefaults(suiteName: "group.com.ninocss.untisplus")

    // MARK: - Plan sync

    /// Persists the plans, cancels every previously scheduled alarm and
    /// re-schedules the current set. Mirrors `AlarmScheduler.replacePlans`.
    static func replacePlans(_ plans: [[AnyHashable: Any]]) {
        store(plans)
        configureCategories(for: plans.first)
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let stale = requests.map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            center.removeDeliveredNotifications(withIdentifiers: stale)
            for plan in plans where (plan["id"] as? String)?.isEmpty == false {
                schedule(plan)
            }
            Self.submitBackgroundRefresh(for: plans)
        }
    }

    static func store(_ plans: [[AnyHashable: Any]]) {
        guard let data = try? JSONSerialization.data(withJSONObject: plans, options: []) else { return }
        suite?.set(data, forKey: "alarmPlans")
    }

    private static func storedPlans() -> [[AnyHashable: Any]] {
        guard let data = suite?.data(forKey: "alarmPlans"),
              let plans = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return plans.map { plan -> [AnyHashable: Any] in
            var bridged: [AnyHashable: Any] = [:]
            for (key, value) in plan { bridged[key] = value }
            return bridged
        }
    }

    // MARK: - Scheduling

    static func schedule(_ plan: [AnyHashable: Any]) {
        switch plan["kind"] as? String {
        case "manual": scheduleManual(plan)
        case "smart": scheduleSmart(plan)
        default: break
        }
    }

    private static func scheduleManual(_ plan: [AnyHashable: Any]) {
        guard let id = plan["id"] as? String, !id.isEmpty else { return }
        let minutes = max(0, min(1439, (plan["timeOfDayMinutes"] as? NSNumber)?.intValue ?? 420))
        let weekdays = (plan["weekdays"] as? [Int])?.filter { (1...7).contains($0) } ?? []
        guard !weekdays.isEmpty else { return }
        var base = DateComponents()
        base.timeZone = TimeZone.current
        base.hour = minutes / 60
        base.minute = minutes % 60
        for weekday in weekdays {
            var match = base
            // Dart DateTime.weekday: 1=Monday … 7=Sunday.
            // UNCalendarNotificationTrigger weekday: 1=Sunday … 7=Saturday.
            match.weekday = weekday == 7 ? 1 : weekday + 1
            let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: true)
            add(id: "\(prefix)\(id).\(weekday)", plan: plan, trigger: trigger)
        }
    }

    private static func scheduleSmart(_ plan: [AnyHashable: Any]) {
        guard let id = plan["id"] as? String, !id.isEmpty else { return }
        let millis = (plan["triggerAtMillis"] as? NSNumber)?.int64Value ?? 0
        let date = Date(timeIntervalSince1970: Double(millis) / 1000)
        guard millis > 0, date > Date() else { return }
        let match = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: false)
        add(id: "\(prefix)\(id)", plan: plan, trigger: trigger)
    }

    static func scheduleSnooze(plan: [AnyHashable: Any], minutes: Int) {
        let seconds = Double(max(1, min(60, minutes))) * 60
        let id = "\(prefix)snooze.\(Int(Date().timeIntervalSince1970 * 1000))"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        add(id: id, plan: plan, trigger: trigger)
    }

    // MARK: - Content

    private static func copy(_ plan: [AnyHashable: Any], _ key: String, _ fallback: String) -> String {
        let values = plan["nativeCopy"] as? [String: Any]
        guard let value = values?[key] as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return fallback }
        return value
    }

    /// Notification action labels are owned by iOS, so refresh their category
    /// whenever Dart publishes plans in a different app language.
    static func configureCategories(for plan: [AnyHashable: Any]?) {
        let plan = plan ?? [:]
        let alarm = UNNotificationCategory(
            identifier: alarmCategory,
            actions: [
                UNNotificationAction(identifier: snoozeActionID, title: copy(plan, "snooze", "Snooze"), options: []),
                UNNotificationAction(identifier: dismissActionID, title: copy(plan, "dismiss", "Dismiss"), options: [.destructive]),
            ],
            intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: nil, categorySummaryFormat: nil
        )
        UNUserNotificationCenter.current().setNotificationCategories([alarm])
    }

    private static func add(id: String, plan: [AnyHashable: Any], trigger: UNNotificationTrigger?) {
        let request = UNNotificationRequest(identifier: id, content: content(plan), trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func content(_ plan: [AnyHashable: Any]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let label = (plan["label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        content.title = (label?.isEmpty ?? true) ? copy(plan, "defaultLabel", "Untis+ Wecker") : label!
        content.body = alarmTimeString(plan)
        content.sound = .default
        content.categoryIdentifier = alarmCategory
        content.threadIdentifier = "untis_alarm"
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        content.userInfo = plan
        return content
    }

    private static func alarmTimeString(_ plan: [AnyHashable: Any]) -> String {
        if let minutes = (plan["timeOfDayMinutes"] as? NSNumber)?.intValue {
            return String(format: "%02d:%02d", minutes / 60, minutes % 60)
        }
        if let millis = (plan["triggerAtMillis"] as? NSNumber)?.int64Value, millis > 0 {
            return timeFormatter.string(from: Date(timeIntervalSince1970: Double(millis) / 1000))
        }
        return ""
    }

    // MARK: - Cancel

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshIdentifier)
    }

    // MARK: - Alarm Live Activity

    static func presentRinging(_ plan: [AnyHashable: Any], snoozing: Bool = false) async {
        guard #available(iOS 16.2, *) else { return }
        let label = (plan["label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        // Absolute ring target: while snoozing count down to the re-ring, on a
        // smart alarm keep the original trigger, otherwise use now (ringing).
        let now = Date()
        let alarmDateMs: Int64
        if snoozing {
            let minutes = (plan["snoozeMinutes"] as? NSNumber)?.intValue ?? 5
            alarmDateMs = Int64(now.addingTimeInterval(Double(max(1, min(60, minutes))) * 60).timeIntervalSince1970 * 1000)
        } else if let millis = (plan["triggerAtMillis"] as? NSNumber)?.int64Value, millis > 0 {
            alarmDateMs = millis
        } else {
            alarmDateMs = Int64(now.timeIntervalSince1970 * 1000)
        }
        let snapshot: [String: Any] = [
            "id": plan["id"] as? String ?? "",
            "label": (label?.isEmpty ?? true) ? copy(plan, "defaultLabel", "Untis+ Wecker") : label!,
            "time": alarmTimeString(plan),
            "status": snoozing ? "snoozing" : "active",
            "statusLabel": copy(plan, snoozing ? "statusSnoozing" : "statusActive", snoozing ? "Snoozing" : "Alarm active"),
            "timeAccessibilityLabel": copy(plan, "timeAccessibility", "Alarm time {time}")
                .replacingOccurrences(of: "{time}", with: alarmTimeString(plan)),
            "alarmDateMs": alarmDateMs,
        ]
        await UntisAlarmActivityManager.upsert(plan: snapshot)
    }

    static func endLiveActivity() async {
        guard #available(iOS 16.2, *) else { return }
        await UntisAlarmActivityManager.end()
    }

    // MARK: - Background refresh

    /// Resubmits the pre-wake refresh for the nearest stored smart plan.
    static func scheduleStoredBackgroundRefresh() {
        submitBackgroundRefresh(for: storedPlans())
    }

    private static func submitBackgroundRefresh(for plans: [[AnyHashable: Any]]) {
        guard #available(iOS 13.0, *) else { return }
        var earliest: Date?
        for plan in plans where (plan["kind"] as? String) == "smart" {
            guard let millis = (plan["preRefreshAtMillis"] as? NSNumber)?.int64Value, millis > 0 else { continue }
            let date = Date(timeIntervalSince1970: Double(millis) / 1000)
            if date > Date(), earliest == nil || date < earliest! {
                earliest = date
            }
        }
        guard let earliest else { return }
        let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
        request.earliestBeginDate = earliest
        try? BGTaskScheduler.shared.submit(request)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

/// Single `UNUserNotificationCenter` delegate that keeps the app in charge of
/// alarm actions while passing everything else through to the
/// flutter_local_notifications delegate (so launch details, payload parsing
/// and the progressive/update notifications keep working).
@preconcurrency
final class UntisNotificationProxy: NSObject, UNUserNotificationCenterDelegate {
    /// Installed by `UntisNotificationsPlugin.register` to push alarm actions
    /// into Dart through the `untisplus/notifications` channel.
    static var forwardAction: ((String, [AnyHashable: Any]) -> Void)?

    /// Re-activates the proxy right after Dart finished `NotificationService
    /// .init()`. At that point `center.delegate` is the flutter_local_notifications
    /// instance; capturing it lets us forward non-alarm notifications to it.
    static func activate() {
        let center = UNUserNotificationCenter.current()
        // Ensure shared instance is created on main thread without deadlock
        let proxy = shared
        if center.delegate !== proxy {
            passthroughDelegate = center.delegate
        }
        center.delegate = proxy
    }

    nonisolated(unsafe) private static var passthroughDelegate: UNUserNotificationCenterDelegate?
    nonisolated(unsafe) private static var _shared: UntisNotificationProxy?
    private static var shared: UntisNotificationProxy {
        if let existing = _shared { return existing }
        if Thread.isMainThread {
            _shared = UntisNotificationProxy()
            return _shared!
        }
        return DispatchQueue.main.sync { 
            if let existing = _shared { return existing }
            _shared = UntisNotificationProxy()
            return _shared!
        }
    }

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content
        guard content.categoryIdentifier == UntisAlarmScheduler.alarmCategory else {
            if let passthrough = Self.passthroughDelegate {
                passthrough.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
            } else {
                completionHandler([.banner, .sound])
            }
            return
        }
        Task { await UntisAlarmScheduler.presentRinging(content.userInfo) }
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        guard content.categoryIdentifier == UntisAlarmScheduler.alarmCategory else {
            if let passthrough = Self.passthroughDelegate {
                passthrough.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
            } else {
                completionHandler()
            }
            return
        }
        let plan = content.userInfo
        let actionID: String
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            actionID = "open_alarm"
        case UNNotificationDismissActionIdentifier, UntisAlarmScheduler.dismissActionID:
            actionID = "dismiss"
            Task { await UntisAlarmScheduler.endLiveActivity() }
        case UntisAlarmScheduler.snoozeActionID:
            actionID = "snooze"
            let minutes = (plan["snoozeMinutes"] as? NSNumber)?.intValue ?? 5
            UntisAlarmScheduler.scheduleSnooze(plan: plan, minutes: minutes)
            Task { await UntisAlarmScheduler.presentRinging(plan, snoozing: true) }
        default:
            actionID = response.actionIdentifier
        }
        Self.forwardAction?(actionID, plan)
        completionHandler()
    }
}
