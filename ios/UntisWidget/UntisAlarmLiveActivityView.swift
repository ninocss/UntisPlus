import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct UntisAlarmLiveActivityView: View {
    let context: ActivityViewContext<UntisAlarmActivityAttributes>

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
            if let countdown = context.state.countdown {
                Text(countdown)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(context.state.statusLabel)
                .font(.caption2)
                .foregroundStyle(.red)
        }
        .padding()
        .activityBackgroundTint(Color.red)
    }
}
