import EventKit
import Flutter
import UIKit
import CoreGraphics
import ActivityKit
import UserNotifications
import WidgetKit
import BackgroundTasks
import workmanager_apple

// Must stay structurally identical to `UntisLessonActivityAttributes` in the
// UntisWidget extension so ActivityKit matches both ends.
@available(iOS 16.2, *)
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

@available(iOS 16.2, *)
enum UntisLiveActivityController {
    static func upsert(payload: [String: Any]) {
        let state = UntisLessonActivityAttributes.ContentState(
            lessonName: payload["lessonName"] as? String ?? "",
            nextLesson: payload["nextLesson"] as? String ?? "",
            timeRemaining: payload["timeRemaining"] as? String ?? "",
            lessonStartMs: (payload["startTimeMs"] as? NSNumber)?.int64Value,
            lessonEndMs: (payload["endTimeMs"] as? NSNumber)?.int64Value
        )
        // Mark the activity stale once the lesson ends so a missed background
        // refresh dims the card instead of showing frozen "live" content.
        let staleDate: Date? = (payload["endTimeMs"] as? NSNumber).map {
            Date(timeIntervalSince1970: $0.doubleValue / 1000)
        }
        let content = ActivityContent(state: state, staleDate: staleDate)
        if let activity = Activity<UntisLessonActivityAttributes>.activities.first {
            Task {
                await activity.update(content)
            }
        } else {
            do {
                _ = try Activity.request(
                    attributes: UntisLessonActivityAttributes(),
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Untis+: failed to start Live Activity: \(error)")
            }
        }
    }

    static func end() {
        Task {
            let activities = Activity<UntisLessonActivityAttributes>.activities
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}

@MainActor
private class UntisLiveActivityPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "untisplus/live_activities",
            binaryMessenger: registrar.messenger()
        )
        let instance = UntisLiveActivityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "upsert":
            guard #available(iOS 16.2, *) else {
                result(FlutterError(code: "unsupported",
                                    message: "Live Activities require iOS 16.2+",
                                    details: nil))
                return
            }
            let args = call.arguments as? [String: Any] ?? [:]
            UntisLiveActivityController.upsert(payload: args)
            result(true)
        case "end":
            guard #available(iOS 16.2, *) else {
                result(false)
                return
            }
            UntisLiveActivityController.end()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alarm Live Activity channel (`untisplus/alarm_live_activity`).
// Mirrors `AlarmScheduler.replacePlans` / scheduleSnooze / cancelAll from
// `AlarmSystem.kt`.
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
private class UntisAlarmLiveActivityPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "untisplus/alarm_live_activity",
            binaryMessenger: registrar.messenger()
        )
        let instance = UntisAlarmLiveActivityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "upsert":
            guard #available(iOS 16.2, *) else {
                result(FlutterError(code: "unsupported",
                                    message: "Live Activities require iOS 16.2+",
                                    details: nil))
                return
            }
            let args = call.arguments as? [String: Any] ?? [:]
            Task { await UntisAlarmActivityManager.upsert(plan: args) }
            result(true)
        case "end":
            guard #available(iOS 16.2, *) else { result(false); return }
            Task { await UntisAlarmActivityManager.end() }
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alarm channel (`untisplus/alarm`) mirroring `MainActivity.kt`.
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
private class UntisAlarmPlugin: NSObject, FlutterPlugin {
    static let channelName = "untisplus/alarm"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = UntisAlarmPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "replacePlans":
            let maps = (call.arguments as? [String: Any])?["plans"] as? [[String: Any]] ?? []
            let plans = maps.compactMap { $0 as? [AnyHashable: Any] }
            UntisAlarmScheduler.replacePlans(plans)
            WidgetCenter.shared.reloadAllTimelines()
            result(nil)
        case "getReadiness":
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let allowed: Bool
                switch settings.authorizationStatus {
                case .authorized, .provisional, .notDetermined:
                    allowed = true
                case .denied:
                    allowed = false
                @unknown default:
                    // e.g. ephemeral on iOS 14+: notifications may be shown.
                    allowed = true
                }
                result([
                    // iOS schedules exact times through calendar triggers and
                    // cannot opt out per-alarm; no separate DND gate exists.
                    "exactAlarms": true,
                    "fullScreenIntent": true,
                    "dndAccess": true,
                    "notifications": allowed,
                ])
            }
        case "openPermissionSettings":
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            result(nil)
        case "pickRingtone":
            // iOS exposes only bundled sounds; the system default is used.
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications channel (`untisplus/notifications`) mirroring `MainActivity.kt`
// `showProgressiveNotification` and `onNotificationAction`.
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
private class UntisNotificationsPlugin: NSObject, FlutterPlugin {
    static let channelName = "untisplus/notifications"

    /// One channel per running engine (main app + transient background-refresh
    /// engine). Alarm actions are broadcast to all of them; only the app's own
    /// Dart handler reacts to them.
    nonisolated(unsafe) private static var registeredChannels: [FlutterMethodChannel] = []

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        registeredChannels.append(channel)
        let instance = UntisNotificationsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        UntisNotificationProxy.forwardAction = { actionID, plan in
            let arguments: [String: Any] = [
                "actionId": actionID,
                "currentLesson": (plan["label"] as? String) ?? "",
                "nextLesson": "",
                "payload": plan,
            ]
            for ch in registeredChannels {
                ch.invokeMethod("onNotificationAction", arguments: arguments)
            }
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "showProgressiveNotification":
            let args = call.arguments as? [String: Any] ?? [:]
            showProgressiveNotification(args: args)
            result(true)
        case "onNotificationAction":
            let args = call.arguments as? [String: Any] ?? [:]
            UserDefaults(suiteName: "group.com.ninocss.untisplus")?
                .set(args, forKey: "lastNotificationAction")
            WidgetCenter.shared.reloadAllTimelines()
            result(nil)
        case "activateNotificationDelegation":
            // Called from Dart at the end of `NotificationService.init()`
            // (and once at launch). Re-arms the proxy so alarm actions are
            // handled natively while every other notification keeps flowing
            // through the flutter_local_notifications delegate.
            UntisNotificationProxy.activate()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func showProgressiveNotification(args: [String: Any]) {
        let content = UNMutableNotificationContent()
        content.title = args["title"] as? String ?? ""
        content.body = args["body"] as? String ?? ""
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI channel (`untisplus/ui`) mirroring `MainActivity.kt`.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Calendar channel (`untisplus/calendar`) for fetching calendars and creating
// new calendars. Mirrors Android's MainActivity.kt calendar channel.
// ─────────────────────────────────────────────────────────────────────────────

/// True when the app may read and/or write the user's event store, independent
/// of the runtime OS version. iOS 17 introduced `.fullAccess` / `.writeOnly`;
/// earlier releases only expose `.authorized`, so the check must be
/// availability-routed to compile against the 16.0 deployment target.
private func untisHasCalendarAccess(_ status: EKAuthorizationStatus) -> Bool {
    if #available(iOS 17.0, *) {
        return status == .fullAccess || status == .writeOnly
    } else {
        return status == .authorized
    }
}

/// Formats an `EKCalendar`'s color as a `#RRGGBB` string using its `CGColor`.
/// Falls back to opaque red when the color cannot be decomposed.
private func untisCalendarHexColor(_ calendar: EKCalendar) -> String {
    let uiColor = UIColor(cgColor: calendar.cgColor)
    var r: CGFloat = 1, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "#%06X", Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255))
}

/// True when the caller may access the event store. iOS 17 split the old
/// `.authorized` case into `.fullAccess`/`.writeOnly`, so compare those when
/// available and fall back to `.authorized` on iOS 16.x.
private func untisHasFullCalendarAccess(_ status: EKAuthorizationStatus) -> Bool {
    if #available(iOS 17.0, *) {
        return status == .fullAccess || status == .writeOnly
    } else {
        return status == .authorized
    }
}

@MainActor
private class UntisCalendarPlugin: NSObject, FlutterPlugin {
    static let channelName = "untisplus/calendar"
    private let eventStore = EKEventStore()


    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = UntisCalendarPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCalendars":
            Task {
                let calendars = await getCalendars()
                result(calendars)
            }
        case "createCalendar":
            let args = call.arguments as? [String: Any] ?? [:]
            let name = args["name"] as? String ?? "Untis+ Calendar"
            let colorHex = args["color"] as? String ?? "#FF0000"
            let accountName = args["accountName"] as? String ?? "Untis+"
            Task {
                let calendarId = await createCalendar(name: name, colorHex: colorHex, accountName: accountName)
                result(calendarId)
            }
        case "getEvents":
            let args = call.arguments as? [String: Any] ?? [:]
            let calendarId = args["calendarId"] as? String
            let startMs = (args["startMs"] as? NSNumber)?.int64Value ?? 0
            let endMs = (args["endMs"] as? NSNumber)?.int64Value ?? 0
            Task {
                let events = await getEvents(calendarId: calendarId, startMs: startMs, endMs: endMs)
                result(events)
            }

        case "deleteEvent":
            let args = call.arguments as? [String: Any] ?? [:]
            let calendarId = args["calendarId"] as? String ?? ""
            let eventId = args["eventId"] as? String ?? ""
            Task {
                let success = await deleteEvent(calendarId: calendarId, eventId: eventId)
                result(success)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getCalendars() async -> [[String: Any]] {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard untisHasFullCalendarAccess(status) else {
            return []
        }
        let calendars = eventStore.calendars(for: .event)
        return calendars.map { cal in
            var isDefault = false
            if let defaultCal = eventStore.defaultCalendarForNewEvents {
                isDefault = defaultCal.calendarIdentifier == cal.calendarIdentifier
            }
            return [
                "id": cal.calendarIdentifier,
                "name": cal.title,
                "color": untisCalendarHexColor(cal),
                "accountName": cal.source.title,
                "accountType": cal.source.sourceType.rawValue,
                "isReadOnly": !cal.allowsContentModifications,
                "isDefault": isDefault
            ]
        }
    }

    private func createCalendar(name: String, colorHex: String, accountName: String) async -> String? {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard untisHasFullCalendarAccess(status) else {
            return nil
        }
        let sources = eventStore.sources
        guard let localSource = sources.first(where: { $0.sourceType == .local }) else {
            return nil
        }
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = name
        calendar.source = localSource
        if let color = colorFromHex(colorHex) {
            calendar.cgColor = color.cgColor
        }
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar.calendarIdentifier
        } catch {
            print("Untis+: failed to create calendar: \(error)")
            return nil
        }
    }

    private func colorFromHex(_ hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        guard hexSanitized.count == 6,
              let rgbValue = UInt32(hexSanitized, radix: 16) else {
            return nil
        }
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    private func getEvents(calendarId: String?, startMs: Int64, endMs: Int64) async -> [[String: Any]] {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard untisHasFullCalendarAccess(status) else {
            return []
        }
        let predicate: NSPredicate
        if let calendarId = calendarId, !calendarId.isEmpty,
           let calendar = eventStore.calendar(withIdentifier: calendarId) {
            predicate = eventStore.predicateForEvents(
                withStart: Date(timeIntervalSince1970: TimeInterval(startMs) / 1000),
                end: Date(timeIntervalSince1970: TimeInterval(endMs) / 1000),
                calendars: [calendar]
            )
        } else {
            predicate = eventStore.predicateForEvents(
                withStart: Date(timeIntervalSince1970: TimeInterval(startMs) / 1000),
                end: Date(timeIntervalSince1970: TimeInterval(endMs) / 1000),
                calendars: nil
            )
        }
        let events = eventStore.events(matching: predicate)
        return events.map { event in
            [
                "id": event.eventIdentifier,
                "title": event.title ?? "",
                "description": event.notes ?? "",
                "start": Int64(event.startDate.timeIntervalSince1970 * 1000),
                "end": Int64(event.endDate.timeIntervalSince1970 * 1000),
                "location": event.location ?? "",
                "calendarId": event.calendar.calendarIdentifier,
                "rrule": event.recurrenceRules?.first?.description ?? "",
                "status": event.status.rawValue
            ]
        }
    }

    private func deleteEvent(calendarId: String, eventId: String) async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard untisHasFullCalendarAccess(status) else {
            return false
        }
        guard let event = eventStore.event(withIdentifier: eventId) else {
            return false
        }
        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            return true
        } catch {
            print("Untis+: failed to delete event: \(error)")
            return false
        }
    }
}

@MainActor
private class UntisUIPlugin: NSObject, FlutterPlugin {
    static let channelName = "untisplus/ui"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = UntisUIPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setWindowBlur":
            let radius = (call.arguments as? NSNumber)?.intValue ?? 0
            if radius > 0 {
                addWindowBlur()
            } else {
                removeWindowBlur()
            }
            result(nil)
        case "setLauncherIcon":
            let icon = call.arguments as? String ?? "default"
            setLauncherIcon(icon, result: result)
        case "getSupportedAbis":
            result([])
        case "installApk":
            result("unsupported")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static let blurViewTag = 845_209

    private func addWindowBlur() {
        guard let window = Self.keyWindow else { return }
        if window.viewWithTag(Self.blurViewTag) != nil { return }
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        effect.tag = Self.blurViewTag
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.isUserInteractionEnabled = false
        window.addSubview(effect)
        NSLayoutConstraint.activate([
            effect.topAnchor.constraint(equalTo: window.topAnchor),
            effect.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            effect.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: window.trailingAnchor),
        ])
    }

    private func removeWindowBlur() {
        guard let window = Self.keyWindow else { return }
        window.viewWithTag(Self.blurViewTag)?.removeFromSuperview()
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func setLauncherIcon(_ icon: String, result: @escaping FlutterResult) {
        guard #available(iOS 10.3, *) else { result(false); return }
        guard UIApplication.shared.supportsAlternateIcons else { result(false); return }
        let names: [String: String] = [
            "3d": "Icon3D",
            "chrom": "IconChrom",
            "galaxy": "IconGalaxy",
            "gradiant": "IconGradient",
            "marmor": "IconMarmor",
            "paper": "IconPaper",
        ]
        // "default" restores the primary icon (empty alternate name).
        let target = names[icon]
        guard icon == "default" || target != nil else { result(false); return }
        UIApplication.shared.setAlternateIconName(target) { error in
            if let error {
                NSLog("setAlternateIconName(%@) failed: %@", icon, error as NSError)
            }
            result(error == nil)
        }
    }
}

@main
@MainActor
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.applicationIconBadgeNumber = 0
    UNUserNotificationCenter.current().delegate = nil
    UntisNotificationProxy.activate()
    requestNotificationPermission()
    registerBackgroundRefresh()
    // This app adopts the UIScene lifecycle, so Flutter registers plugins
    // (and thus WorkmanagerPlugin's application delegate) only after this
    // method returns. BGTaskScheduler requires its launch handlers to be
    // registered during `didFinishLaunching`, so re-arm the persisted
    // workmanager task identifiers explicitly here.
    WorkmanagerPlugin.registerLaunchHandlers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0
    super.applicationDidBecomeActive(application)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Opportunistic pre-wake refresh: re-submit while the OS still gives the
    // app the chance (the scheduler also re-submits on every plan update).
    UntisAlarmScheduler.scheduleStoredBackgroundRefresh()
    super.applicationDidEnterBackground(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    AppDelegate.registerNativePlugins(with: engineBridge.pluginRegistry)
  }

  @MainActor
  static func registerNativePlugins(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    UntisLiveActivityPlugin.register(with: registry.registrar(forPlugin: "UntisLiveActivityPlugin")!)
    UntisAlarmLiveActivityPlugin.register(with: registry.registrar(forPlugin: "UntisAlarmLiveActivityPlugin")!)
    UntisAlarmPlugin.register(with: registry.registrar(forPlugin: "UntisAlarmPlugin")!)
    UntisNotificationsPlugin.register(with: registry.registrar(forPlugin: "UntisNotificationsPlugin")!)
    UntisUIPlugin.register(with: registry.registrar(forPlugin: "UntisUIPlugin")!)
    UntisCalendarPlugin.register(with: registry.registrar(forPlugin: "UntisCalendarPlugin")!)
  }

  private func registerBackgroundRefresh() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: UntisAlarmScheduler.refreshIdentifier,
      using: nil
    ) { task in
      guard let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      UntisAlarmRefreshController.handle(refreshTask)
    }
  }

  private func requestNotificationPermission() {
    UntisAlarmScheduler.configureCategories(for: nil)
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        print("Untis+: notification permission error: \(error)")
      }
      UntisAlarmScheduler.scheduleStoredBackgroundRefresh()
    }
  }
}

/// Runs the Dart `alarmRefreshDispatcher` entrypoint in a throwaway engine so
/// smart alarms get a pre-wake timetable refresh, then completes the pending
/// `BGAppRefreshTask`. Mirrors Android's `AlarmRefreshService`.
@MainActor
enum UntisAlarmRefreshController {
    private static var engine: FlutterEngine?
    private static var task: BGAppRefreshTask?

    static func handle(_ refreshTask: BGAppRefreshTask) {
        task = refreshTask
        refreshTask.expirationHandler = {
            finish(success: false)
        }
        DispatchQueue.main.async {
            guard engine == nil else {
                finish(success: false)
                return
            }
            let refreshEngine = FlutterEngine(name: "com.ninocss.untisplus.alarmRefresh")
            AppDelegate.registerNativePlugins(with: refreshEngine)
            let channel = FlutterMethodChannel(
                name: UntisAlarmScheduler.channelIdentifier,
                binaryMessenger: refreshEngine.binaryMessenger
            )
            channel.setMethodCallHandler { call, _ in
                if call.method == "completed" {
                    UntisAlarmRefreshController.finish(success: true)
                }
            }
            engine = refreshEngine
            refreshEngine.run(withEntrypoint: "alarmRefreshDispatcher")

            // The native sync retains the last confirmed plan on failure; end
            // the task eagerly so the OS keeps scheduling background work.
            DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
                UntisAlarmRefreshController.finish(success: false)
            }
            UntisAlarmScheduler.scheduleStoredBackgroundRefresh()
        }
    }

    static func finish(success: Bool) {
        guard let active = task else { return }
        task = nil
        let running = engine
        engine = nil
        active.setTaskCompleted(success: success)
        if let running {
            DispatchQueue.main.async {
                running.destroyContext()
            }
        }
    }
}
