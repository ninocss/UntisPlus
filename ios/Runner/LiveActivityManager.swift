import ActivityKit

// Must stay structurally identical to `UntisAlarmActivityAttributes` in the
// UntisWidget extension so ActivityKit matches both ends.
@available(iOS 16.2, *)
struct UntisAlarmActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let alarmId: String
        let label: String
        let time: String
        let status: String
        let statusLabel: String
        let timeAccessibilityLabel: String
        let countdown: String?
        let alarmDateMs: Int64?
    }
    init() {}
}

@available(iOS 16.2, *)
enum UntisAlarmActivityManager {
    /// Start or update the alarm Live Activity for `plan`.
    static func upsert(plan: [String: Any]) async {
        guard #available(iOS 16.2, *) else { return }
        let state = UntisAlarmActivityAttributes.ContentState(
            alarmId: plan["id"] as? String ?? "",
            label: plan["label"] as? String ?? "Untis+ Wecker",
            time: plan["time"] as? String ?? "",
            status: plan["status"] as? String ?? "active",
            statusLabel: plan["statusLabel"] as? String ?? "Alarm active",
            timeAccessibilityLabel: plan["timeAccessibilityLabel"] as? String ?? "Alarm time",
            countdown: plan["countdown"] as? String,
            alarmDateMs: (plan["alarmDateMs"] as? NSNumber)?.int64Value
        )
        do {
            if let activity = Activity<UntisAlarmActivityAttributes>.activities.first {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                _ = try await Activity.request(
                    attributes: UntisAlarmActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            }
        } catch {
            print("Untis+: failed to start alarm Live Activity: \(error)")
        }
    }

    /// End the alarm Live Activity.
    static func end() async {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<UntisAlarmActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
