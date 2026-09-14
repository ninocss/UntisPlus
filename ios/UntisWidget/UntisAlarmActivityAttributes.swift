import ActivityKit

/// Alarm state mirrored from Android's `AlarmScheduler`/`AlarmAlertService`.
///
/// `alarmId` is the normalized plan id (`manual-<id>` or `smart-primary`).
/// `time` is the alarm trigger formatted as `HH:mm`. `status` is either
/// `"active"` or `"snoozing"`. The countdown is pushed by the app while
/// foregrounded; it is not a system-driven timer on iOS.
@available(iOS 16.2, *)
struct UntisAlarmActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let alarmId: String
        let label: String
        let time: String
        let status: String
        let countdown: String?
    }

    init() {}
}
