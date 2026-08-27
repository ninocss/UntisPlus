import WidgetKit
import SwiftUI

struct UntisWidgetBundle: WidgetBundle {
    var body: some Widget {
        UntisCurrentLessonWidget()
        UntisDailyScheduleWidget()
    }
}
