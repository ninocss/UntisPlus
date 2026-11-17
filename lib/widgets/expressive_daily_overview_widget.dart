import 'package:flutter/material.dart';
import 'expressive_lesson_card.dart';

class ExpressiveDailyOverviewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final ExpressiveShapeVariant shapeVariant;

  const ExpressiveDailyOverviewWidget({
    super.key,
    required this.lessons,
    this.shapeVariant = ExpressiveShapeVariant.shape4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: lessons.map((lesson) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ExpressiveLessonCard(
            subject: lesson['subject'],
            teacher: lesson['teacher'],
            room: lesson['room'],
            isCancelled: lesson['isCancelled'] ?? false,
            shapeVariant: shapeVariant,
          ),
        );
      }).toList(),
    );
  }
}
