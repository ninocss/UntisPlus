import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class GithubReleaseAsset {
  const GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    this.sizeBytes = 0,
  });

  final String name;
  final String downloadUrl;
  final int sizeBytes;
}

@immutable
class GithubRelease {
  const GithubRelease({
    required this.version,
    required this.htmlUrl,
    required this.assets,
    required this.markdown,
    this.publishedAt,
  });

  final String version;
  final String htmlUrl;
  final List<GithubReleaseAsset> assets;
  final String markdown;
  final DateTime? publishedAt;

  factory GithubRelease.fromApi(Map<String, dynamic> json) {
    final tag = (json['tag_name'] ?? '').toString().trim();
    return GithubRelease(
      version: tag.isEmpty ? (json['name'] ?? '').toString().trim() : tag,
      htmlUrl:
          (json['html_url'] ?? 'https://github.com/ninocss/UntisPlus/releases')
              .toString(),
      assets: githubReleaseAssetsFromApi(json['assets']),
      markdown: (json['body'] ?? '').toString(),
      publishedAt: DateTime.tryParse(
        (json['published_at'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }
}

class GithubReleaseException implements Exception {
  const GithubReleaseException(this.message);

  final String message;

  @override
  String toString() => 'GithubReleaseException: $message';
}

class GithubReleaseRepository {
  GithubReleaseRepository({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  static final Uri latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/ninocss/UntisPlus/releases/latest',
  );

  final http.Client _client;
  final Duration timeout;
  Future<GithubRelease>? _inFlight;

  Future<GithubRelease> fetchLatest() {
    final current = _inFlight;
    if (current != null) return current;
    final future = _fetchLatest();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<GithubRelease> _fetchLatest() async {
    http.Response response;
    try {
      response = await _client
          .get(
            latestReleaseUri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'UntisPlus',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GithubReleaseException('GitHub request timed out.');
    } on http.ClientException {
      throw const GithubReleaseException('GitHub is not reachable.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GithubReleaseException(
        'GitHub returned HTTP ${response.statusCode}.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const GithubReleaseException('GitHub returned invalid JSON.');
    }
    if (decoded is! Map) {
      throw const GithubReleaseException('GitHub returned invalid data.');
    }
    final release = GithubRelease.fromApi(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (release.version.isEmpty) {
      throw const GithubReleaseException('GitHub release has no version.');
    }
    return release;
  }

  void close() => _client.close();
}

List<GithubReleaseAsset> githubReleaseAssetsFromApi(dynamic rawAssets) {
  if (rawAssets is! List) return const <GithubReleaseAsset>[];
  return rawAssets
      .whereType<Map>()
      .map((rawAsset) {
        final name = (rawAsset['name'] ?? '').toString().trim();
        final url = (rawAsset['browser_download_url'] ?? '').toString().trim();
        final size = rawAsset['size'];
        return GithubReleaseAsset(
          name: name,
          downloadUrl: url,
          sizeBytes: size is num ? size.toInt() : 0,
        );
      })
      .where((asset) {
        final uri = Uri.tryParse(asset.downloadUrl);
        return asset.name.isNotEmpty &&
            uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http');
      })
      .toList(growable: false);
}

bool _assetNameHasToken(String value, String token) {
  final escaped = RegExp.escape(token);
  return RegExp('(^|[^a-z0-9_])$escaped(?=[^a-z0-9_]|\$)').hasMatch(value);
}

GithubReleaseAsset? selectCompatibleAndroidApk(
  List<GithubReleaseAsset> assets,
  List<String> supportedAbis,
) {
  final apks = assets
      .where((asset) => asset.name.toLowerCase().endsWith('.apk'))
      .toList();
  if (apks.isEmpty) return null;

  const aliasesByAbi = <String, List<String>>{
    'arm64-v8a': <String>['arm64-v8a', 'arm64', 'aarch64'],
    'armeabi-v7a': <String>['armeabi-v7a', 'armv7', 'arm32'],
    'x86_64': <String>['x86_64', 'x86-64', 'x64'],
    'x86': <String>['x86'],
  };
  final allArchitectureTokens = aliasesByAbi.values
      .expand((aliases) => aliases)
      .toSet();

  for (final abi in supportedAbis.map((value) => value.toLowerCase().trim())) {
    final aliases = aliasesByAbi[abi];
    if (aliases == null) continue;
    for (final asset in apks) {
      final name = asset.name.toLowerCase();
      if (aliases.any((alias) => _assetNameHasToken(name, alias))) {
        return asset;
      }
    }
  }

  for (final asset in apks) {
    final name = asset.name.toLowerCase();
    final declaresArchitecture = allArchitectureTokens.any(
      (token) => _assetNameHasToken(name, token),
    );
    final isUniversal =
        name.contains('universal') ||
        name.contains('all-abi') ||
        name.contains('fat.apk') ||
        name.contains('-release.apk');
    if (!declaresArchitecture && isUniversal) return asset;
  }
  if (apks.length != 1) return null;
  final onlyApkDeclaresArchitecture = allArchitectureTokens.any(
    (token) => _assetNameHasToken(apks.single.name.toLowerCase(), token),
  );
  return onlyApkDeclaresArchitecture ? null : apks.single;
}
