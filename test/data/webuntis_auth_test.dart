import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/data/webuntis/webuntis_auth.dart';

void main() {
  group('normalizeWebUntisSecret', () {
    test('normalizes plain and Untis URI credentials', () {
      expect(normalizeWebUntisSecret(' ab cd '), 'ABCD');
      expect(normalizeWebUntisSecret('untis://login?key=ab%20cd'), 'ABCD');
    });

    test('preserves an empty credential', () {
      expect(normalizeWebUntisSecret('  '), isEmpty);
    });
  });

  test('extracts a session id from a Set-Cookie header', () {
    expect(
      webUntisSessionIdFromCookie('foo=bar; JSESSIONID=session-42; Path=/'),
      'session-42',
    );
    expect(webUntisSessionIdFromCookie(null), isEmpty);
  });
}
