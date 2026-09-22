import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/core/version_utils.dart';

void main() {
  group('compareVersionStrings', () {
    test('compares versions with different component counts', () {
      expect(compareVersionStrings('5.5', '5.5.1'), isNegative);
      expect(compareVersionStrings('5.5.1', '5.5'), isPositive);
      expect(compareVersionStrings('5.5.0', '5.5'), 0);
    });

    test('accepts common release prefixes and suffixes', () {
      expect(compareVersionStrings('v5.5.0', '5.6.0-beta.1'), isNegative);
      expect(extractVersionParts('release-v5.6.0'), [5, 6, 0]);
    });
  });
}
