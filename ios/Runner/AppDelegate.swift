import Flutter
import UIKit
import ActivityKit
import UserNotifications
import WidgetKit
import BackgroundTasks

// Must stay structurally identical to `UntisLessonActivityAttributes` in the
// UntisWidgetExtension extension so ActivityKit matches both ends.
@available(iOS 16.2, *)
struct UntisLessonActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let lessonName: String
        let nextLesson: String
        let timeRemaining: String
    }
    init() {}
}

@available(iOS 16.2, *)
enum UntisLiveActivityController {
    static func upsert(payload: [String: Any]) {
        let state = UntisLessonActivityAttributes.ContentState(
            lessonName: payload["lessonName"] as? String ?? "",
            nextLesson: payload["nextLesson"] as? String ?? "",
            timeRemaining: payload["timeRemaining"] as? String ?? ""
        )
        if let activity = Activity<UntisLessonActivityAttributes>.activities.first {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        } else {
            do {
                _ = try Activity.request(
                    attributes: UntisLessonActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil),
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

private class UntisNotificationsPlugin: NSObject, FlutterPlugin {
    static let channelName = "untisplus/notifications"

    /// One channel per running engine (main app + transient background-refresh
    /// engine). Alarm actions are broadcast to all of them; only the app's own
    /// Dart handler reacts to them.
    private static var registeredChannels: [FlutterMethodChannel] = []

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
            result(error == nil)
        }
    }
}

@main
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

  static func registerNativePlugins(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    UntisLiveActivityPlugin.register(with: registry)
    UntisAlarmLiveActivityPlugin.register(with: registry)
    UntisAlarmPlugin.register(with: registry)
    UntisNotificationsPlugin.register(with: registry)
    UntisUIPlugin.register(with: registry)
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
    let alarmCategory = UNNotificationCategory(
      identifier: UntisAlarmScheduler.alarmCategory,
      actions: [
        UNNotificationAction(identifier: UntisAlarmScheduler.snoozeActionID, title: "Snooze", options: []),
        UNNotificationAction(identifier: UntisAlarmScheduler.dismissActionID, title: "Dismiss", options: [.destructive]),
      ],
      intentIdentifiers: [],
      categorySummaryFormat: nil
    )
    let legacyCategory = UNNotificationCategory(
      identifier: "untis_alarm_channel",
      actions: [
        UNNotificationAction(identifier: "snooze", title: "Snooze", options: []),
        UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [])
      ],
      intentIdentifiers: [],
      categorySummaryFormat: nil
    )
    UNUserNotificationCenter.current().setNotificationCategories([alarmCategory, legacyCategory])
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
