import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untisplus/features/updates/data/github_release_repository.dart';

void main() {
  test('fetchLatest parses release metadata and assets', () async {
    late http.Request capturedRequest;
    final repository = GithubReleaseRepository(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'tag_name': 'v5.6.0',
            'html_url': 'https://github.com/ninocss/UntisPlus/releases/v5.6.0',
            'body': 'Changes',
            'published_at': '2026-09-22T12:00:00Z',
            'assets': [
              {
                'name': 'untisplus-arm64-v8a.apk',
                'browser_download_url': 'https://example.test/app.apk',
                'size': 123,
              },
              {'name': 'invalid.apk', 'browser_download_url': 'not a URL'},
            ],
          }),
          200,
        );
      }),
    );

    final release = await repository.fetchLatest();

    expect(capturedRequest.url, GithubReleaseRepository.latestReleaseUri);
    expect(capturedRequest.headers['user-agent'], 'UntisPlus');
    expect(release.version, 'v5.6.0');
    expect(release.markdown, 'Changes');
    expect(release.assets, hasLength(1));
    expect(release.assets.single.sizeBytes, 123);
  });

  test('concurrent release requests share one HTTP request', () async {
    var requestCount = 0;
    final responseReady = Completer<void>();
    final repository = GithubReleaseRepository(
      client: MockClient((_) async {
        requestCount++;
        await responseReady.future;
        return http.Response(jsonEncode({'tag_name': 'v5.6.0'}), 200);
      }),
    );

    final first = repository.fetchLatest();
    final second = repository.fetchLatest();
    responseReady.complete();
    final releases = await Future.wait([first, second]);

    expect(requestCount, 1);
    expect(identical(releases.first, releases.last), isTrue);
  });

  test('APK selection prefers the supported architecture', () {
    const assets = <GithubReleaseAsset>[
      GithubReleaseAsset(
        name: 'untisplus-x86_64.apk',
        downloadUrl: 'https://example.test/x86.apk',
      ),
      GithubReleaseAsset(
        name: 'untisplus-arm64-v8a.apk',
        downloadUrl: 'https://example.test/arm.apk',
      ),
    ];

    final selected = selectCompatibleAndroidApk(assets, const ['arm64-v8a']);

    expect(selected?.name, 'untisplus-arm64-v8a.apk');
  });
}
