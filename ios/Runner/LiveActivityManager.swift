import ActivityKit

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
            countdown: plan["countdown"] as? String
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
