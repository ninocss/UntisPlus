import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/core/design_tokens.dart';

void main() {
  test('automatic lesson colors remain stable', () {
    expect(untisPlusAutoLessonPalette(), const <Color>[
      Color(0xFF4F7CFF),
      Color(0xFF00B8D4),
      Color(0xFF00C853),
      Color(0xFFFFA000),
      Color(0xFFFF5252),
      Color(0xFF7C4DFF),
      Color(0xFFE91E63),
      Color(0xFF009688),
    ]);
  });

  test('subject palette follows the active color scheme', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    final palette = untisPlusSubjectPalette(scheme);

    expect(palette, hasLength(10));
    expect(palette.first, scheme.primary);
    expect(palette.last, scheme.errorContainer);
  });
}
