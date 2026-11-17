import 'package:flutter/material.dart';
import 'expressive_lesson_card.dart';

class ExpressiveCurrentHourWidget extends StatelessWidget {
  final String subject;
  final String teacher;
  final String room;
  final bool isCancelled;
  final ExpressiveShapeVariant shapeVariant;
  final ExpressiveTone? tone;

  const ExpressiveCurrentHourWidget({
    super.key,
    required this.subject,
    required this.teacher,
    required this.room,
    this.isCancelled = false,
    this.shapeVariant = ExpressiveShapeVariant.shape1,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressiveLessonCard(
      subject: subject,
      teacher: teacher,
      room: room,
      isCancelled: isCancelled,
      shapeVariant: shapeVariant,
      tone: tone,
      isNow: true,
    );
  }
}
