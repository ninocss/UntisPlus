import ActivityKit
import SwiftUI
import WidgetKit

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
                    Text(context.state.time)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let countdown = context.state.countdown {
                            Text(countdown)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(context.state.statusLabel)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            } compactLeading: {
                Text(context.state.time)
                    .font(.headline)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } compactTrailing: {
                Text(context.state.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } minimal: {
                Text(context.state.time)
                    .font(.headline)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
            .keylineTint(.red)
        }
    }
}
