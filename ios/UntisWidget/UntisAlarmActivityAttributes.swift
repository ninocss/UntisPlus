import ActivityKit

/// Alarm state mirrored from Android's `AlarmScheduler`/`AlarmAlertService`.
///
/// `alarmId` is the normalized plan id (`manual-<id>` or `smart-primary`).
/// `time` is the alarm trigger formatted as `HH:mm`. `status` is either
/// `"active"` or `"snoozing"`. `alarmDateMs` is the absolute epoch-millisecond
/// time the alarm rings (or re-rings after snooze), driving a system countdown.
/// The `countdown` string is pushed by the app while foregrounded as a fallback.
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
