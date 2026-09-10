import WidgetKit
import SwiftUI

@main
@available(iOSApplicationExtension 17.0, *)
struct UntisWidgetBundle: WidgetBundle {
    var body: some Widget {
        UntisCurrentLessonWidget()
        UntisDailyScheduleWidget()
        UntisHomeworkWidget()
        UntisNotificationsWidget()
        UntisCustomWidget()
    }
}
