import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../l10n.dart';
import 'github_release_repository.dart';

class ChangelogData {
  const ChangelogData({
    required this.markdown,
    required this.version,
    this.publishedAt,
    this.releaseUrl,
  });

  final String markdown;
  final String version;
  final DateTime? publishedAt;
  final String? releaseUrl;

  factory ChangelogData.fromJson(
    Map<String, dynamic> json,
    AppL10n l, {
    required String fallbackVersion,
  }) => ChangelogData(
    markdown: (json['markdown'] ?? '').toString().trim().isEmpty
        ? l.changelogNoData
        : json['markdown'].toString(),
    version: (json['version'] ?? fallbackVersion).toString(),
    publishedAt: DateTime.tryParse(
      (json['published_at'] ?? json['generated_at'] ?? '').toString(),
    ),
    releaseUrl: (json['release_url'] ?? '').toString().trim().isEmpty
        ? null
        : json['release_url'].toString(),
  );

  factory ChangelogData.fromGithubRelease(GithubRelease release, AppL10n l) =>
      ChangelogData(
        markdown: release.markdown.trim().isEmpty
            ? l.changelogNoData
            : release.markdown,
        version: release.version,
        publishedAt: release.publishedAt,
        releaseUrl: release.htmlUrl.trim().isEmpty ? null : release.htmlUrl,
      );
}

class ChangelogRepository {
  ChangelogRepository({
    GithubReleaseRepository? releases,
    http.Client? legacyClient,
    AssetBundle? assetBundle,
  }) : _releases = releases ?? GithubReleaseRepository(),
       _legacyClient = legacyClient ?? http.Client(),
       _assetBundle = assetBundle ?? rootBundle;

  static final Uri legacyUri = Uri.parse(
    'https://raw.githubusercontent.com/ninocss/UntisPlus/main/changelog.json',
  );

  final GithubReleaseRepository _releases;
  final http.Client _legacyClient;
  final AssetBundle _assetBundle;

  Future<ChangelogData> fetch({
    required AppL10n l10n,
    required String currentVersion,
  }) async {
    try {
      final release = await _releases.fetchLatest();
      final data = ChangelogData.fromGithubRelease(release, l10n);
      if (data.markdown != l10n.changelogNoData) return data;
    } catch (_) {
      // The bundled changelog keeps this surface useful while offline.
    }
    return _loadFallback(l10n, currentVersion);
  }

  Future<ChangelogData> _loadFallback(
    AppL10n l10n,
    String currentVersion,
  ) async {
    try {
      final bundled = await _assetBundle.loadString('changelog.json');
      final decoded = jsonDecode(bundled);
      if (decoded is Map) {
        return ChangelogData.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
          l10n,
          fallbackVersion: currentVersion,
        );
      }
    } catch (_) {
      // Older app packages did not bundle changelog.json.
    }

    try {
      final response = await _legacyClient.get(legacyUri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          return ChangelogData.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
            l10n,
            fallbackVersion: currentVersion,
          );
        }
      }
    } catch (_) {}

    return ChangelogData(
      markdown: l10n.changelogNoData,
      version: currentVersion,
    );
  }

  void close() {
    _releases.close();
    _legacyClient.close();
  }
}
