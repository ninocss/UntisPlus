import Flutter
import UIKit
import ActivityKit

// Must stay structurally identical to `UntisLessonActivityAttributes` in the
// UntisWidget extension so ActivityKit matches both ends.
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

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.applicationIconBadgeNumber = 0
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0
    super.applicationDidBecomeActive(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "UntisLiveActivityPlugin") {
      UntisLiveActivityPlugin.register(with: registrar)
    }
  }
}
