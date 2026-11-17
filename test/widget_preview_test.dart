import 'package:flutter/material.dart';
import 'package:untisplus/widgets/expressive_next_hour_widget.dart';
import 'package:untisplus/widgets/expressive_current_hour_widget.dart';
import 'package:untisplus/widgets/expressive_daily_overview_widget.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const ExpressiveNextHourWidget(
              subject: "Math",
              teacher: "Smith",
              room: "A101",
            ),
            const ExpressiveCurrentHourWidget(
              subject: "Physics",
              teacher: "Doe",
              room: "Lab 1",
            ),
            ExpressiveDailyOverviewWidget(
              lessons: [
                {'subject': 'Math', 'teacher': 'Smith', 'room': 'A101'},
                {'subject': 'Physics', 'teacher': 'Doe', 'room': 'Lab 1'},
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
