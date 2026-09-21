import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/ai/data/local_model_provider.dart';

void main() {
  group('local model diagnostics', () {
    test('recognizes the additional inference-context failure', () {
      expect(
        isFllamaLoadError('Error: Failed to create inference context'),
        isTrue,
      );
      expect(isFllamaLoadError('generated answer'), isFalse);
    });

    test('returns the last useful native log line', () {
      expect(
        lastMeaningfulNativeLine('first\n\n  final detail  \n'),
        'final detail',
      );
      expect(lastMeaningfulNativeLine(' \n '), isNull);
    });

    test('bounds long native log details', () {
      final detail = lastMeaningfulNativeLine(List.filled(240, 'x').join());
      expect(detail, hasLength(200));
    });
  });
}
