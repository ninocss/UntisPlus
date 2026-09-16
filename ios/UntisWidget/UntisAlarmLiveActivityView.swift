import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct UntisAlarmLiveActivityView: View {
    let context: ActivityViewContext<UntisAlarmActivityAttributes>

    /// System-driven countdown to the alarm target (`alarmDateMs`), falling
    /// back to the pushed `countdown` string for older activities.
    @ViewBuilder
    private var countdownText: some View {
        if let ms = context.state.alarmDateMs {
            let target = Date(timeIntervalSince1970: Double(ms) / 1000)
            if target > Date() {
                Text(timerInterval: Date()...target, countsDown: true)
            } else if let countdown = context.state.countdown {
                Text(countdown)
            }
        } else if let countdown = context.state.countdown {
            Text(countdown)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(context.state.time)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.red)
                .accessibilityLabel(context.state.timeAccessibilityLabel)
            Text(context.state.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel(context.state.label)
            countdownText
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(context.state.statusLabel)
                .font(.caption2)
                .foregroundStyle(.red)
        }
        .padding()
        .activityBackgroundTint(Color.red)
    }
}
