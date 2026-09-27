import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/data/webuntis/untis_endpoint.dart';

void main() {
  tearDown(() {
    devModeNotifier.value = false;
    devServerUrlNotifier.value = kDefaultDevServerUrl;
    devUseHttpsNotifier.value = false;
    devServerReachableNotifier.value = false;
  });

  group('normalizeDevServerUrl', () {
    test('keeps a bare host:port unchanged', () {
      expect(normalizeDevServerUrl('localhost:3000'), 'localhost:3000');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeDevServerUrl('  10.0.2.2:8080  '), '10.0.2.2:8080');
    });

    test('strips a scheme, path, query and fragment', () {
      expect(normalizeDevServerUrl('http://localhost:3000/api?x=1#frag'),
          'localhost:3000');
      expect(normalizeDevServerUrl('https://dev.example.com/'), 'dev.example.com');
    });

    test('falls back to the default for empty input', () {
      expect(normalizeDevServerUrl(''), kDefaultDevServerUrl);
      expect(normalizeDevServerUrl('   '), kDefaultDevServerUrl);
      expect(normalizeDevServerUrl('https://'), kDefaultDevServerUrl);
    });
  });

  group('untisBaseUrl', () {
    test('always uses https for a school server', () {
      expect(
        untisBaseUrl(schoolUrl: 'example.webuntis.com'),
        'https://example.webuntis.com',
      );
    });

    test('trims the school url', () {
      expect(
        untisBaseUrl(schoolUrl: '  example.webuntis.com  '),
        'https://example.webuntis.com',
      );
    });

    test('uses dev server when developer mode is on and server is reachable', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'localhost:3000';
      devServerReachableNotifier.value = true;
      expect(
        untisBaseUrl(schoolUrl: 'example.webuntis.com'),
        'http://localhost:3000',
      );
    });

    test('falls back to school server when dev mode is on but server unreachable', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'localhost:3000';
      devServerReachableNotifier.value = false;
      expect(
        untisBaseUrl(schoolUrl: 'example.webuntis.com'),
        'https://example.webuntis.com',
      );
    });

    test('honours the https switch in developer mode', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'dev.example.com';
      devUseHttpsNotifier.value = true;
      devServerReachableNotifier.value = true;
      expect(
        untisBaseUrl(schoolUrl: 'example.webuntis.com'),
        'https://dev.example.com',
      );
    });

    test('normalizes the stored address when building the url', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'http://localhost:3000/unused';
      devServerReachableNotifier.value = true;
      expect(untisBaseUrl(schoolUrl: 'example.webuntis.com'),
          'http://localhost:3000');
    });

    test('uses dev server when no school is configured', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'localhost:3000';
      devServerReachableNotifier.value = false;
      expect(untisBaseUrl(schoolUrl: ''), 'http://localhost:3000');
    });
  });

  group('untisDirectoryBaseUrl', () {
    test('uses the public directory when developer mode is off', () {
      expect(untisDirectoryBaseUrl(), 'https://mobile.webuntis.com');
    });

    test('redirects to the dev server while developer mode is on and reachable', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'localhost:3000';
      devServerReachableNotifier.value = true;
      expect(untisDirectoryBaseUrl(), 'http://localhost:3000');
    });

    test('falls back to public directory when dev mode is on but server unreachable', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'localhost:3000';
      devServerReachableNotifier.value = false;
      expect(untisDirectoryBaseUrl(), 'https://mobile.webuntis.com');
    });

    test('honours the https switch, unlike a school server', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = 'dev.example.com';
      devUseHttpsNotifier.value = true;
      devServerReachableNotifier.value = true;
      expect(untisDirectoryBaseUrl(), 'https://dev.example.com');
    });

    test('falls back to the default address for a blank dev server', () {
      devModeNotifier.value = true;
      devServerUrlNotifier.value = '  ';
      devServerReachableNotifier.value = true;
      expect(untisDirectoryBaseUrl(), 'http://$kDefaultDevServerUrl');
    });
  });

  group('kDevServerRepositoryUrl', () {
    test('is an absolute https link the browser can open directly', () {
      final uri = Uri.parse(kDevServerRepositoryUrl);
      expect(uri.isAbsolute, isTrue);
      expect(uri.scheme, 'https');
      expect(uri.host, 'github.com');
      // No path beyond the owner and repository name, so nothing after it can
      // dangle onto a stale fragment when the constant is edited.
      expect(uri.pathSegments, ['OseMine', 'UntisPlus-dev-server']);
    });
  });
}
