import ActivityKit
import SwiftUI
import WidgetKit
import ExpressiveUI

/// Dynamic Island representation of the alarm Live Activity.
///
/// Lock Screen: time + label.
/// Expanded: countdown + snooze/dismiss actions.
/// Compact Leading/Trailing: time.
/// Minimal: time.
@available(iOS 16.2, *)
struct UntisAlarmActivityConfiguration: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UntisAlarmActivityAttributes.self) { context in
            UntisAlarmLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Group {
                        Text(context.state.time)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                    .expressiveColors(UntisExpressiveTheme.alarm)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Group {
                        Text(context.state.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .expressiveColors(UntisExpressiveTheme.alarm)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Group {
                        HStack {
                            if let ms = context.state.alarmDateMs {
                                let target = Date(timeIntervalSince1970: Double(ms) / 1000)
                                if target > Date() {
                                    Text(timerInterval: Date()...target, countsDown: true)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                } else if let countdown = context.state.countdown {
                                    Text(countdown)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else if let countdown = context.state.countdown {
                                Text(countdown)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(context.state.statusLabel)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .expressiveColors(UntisExpressiveTheme.alarm)
                }
            } compactLeading: {
                Group {
                    Text(context.state.time)
                        .font(.headline)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                .expressiveColors(UntisExpressiveTheme.alarm)
            } compactTrailing: {
                Group {
                    Text(context.state.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .expressiveColors(UntisExpressiveTheme.alarm)
            } minimal: {
                Group {
                    Text(context.state.time)
                        .font(.headline)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                .expressiveColors(UntisExpressiveTheme.alarm)
            }
            .keylineTint(.red)
        }
    }
}
