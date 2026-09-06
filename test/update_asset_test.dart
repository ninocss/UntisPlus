import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  const assets = [
    GithubReleaseAsset(
      name: 'UntisPlus-arm64-v8a-release.apk',
      downloadUrl: 'https://example.com/arm64.apk',
    ),
    GithubReleaseAsset(
      name: 'UntisPlus-armeabi-v7a-release.apk',
      downloadUrl: 'https://example.com/armv7.apk',
    ),
    GithubReleaseAsset(
      name: 'UntisPlus-x86_64-release.apk',
      downloadUrl: 'https://example.com/x64.apk',
    ),
  ];

  test('selects the first compatible Android ABI', () {
    expect(
      selectCompatibleAndroidApk(assets, ['arm64-v8a', 'armeabi-v7a'])?.name,
      'UntisPlus-arm64-v8a-release.apk',
    );
    expect(
      selectCompatibleAndroidApk(assets, ['x86_64'])?.name,
      'UntisPlus-x86_64-release.apk',
    );
    expect(
      selectCompatibleAndroidApk(
        [
          assets[2],
          const GithubReleaseAsset(
            name: 'UntisPlus-x86-release.apk',
            downloadUrl: 'https://example.com/x86.apk',
          ),
        ],
        ['x86'],
      )?.name,
      'UntisPlus-x86-release.apk',
    );
  });

  test('allows an explicitly universal APK but rejects a wrong split APK', () {
    const universal = GithubReleaseAsset(
      name: 'UntisPlus-universal-release.apk',
      downloadUrl: 'https://example.com/universal.apk',
    );
    expect(
      selectCompatibleAndroidApk([assets[1], universal], ['arm64-v8a'])?.name,
      universal.name,
    );
    expect(selectCompatibleAndroidApk([assets[1]], ['arm64-v8a']), isNull);
  });
}
