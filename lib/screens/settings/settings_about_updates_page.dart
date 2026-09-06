// settings_about_updates_page.dart
part of '../../main.dart';

@immutable
class GithubReleaseAsset {
  final String name;
  final String downloadUrl;
  final int sizeBytes;

  const GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    this.sizeBytes = 0,
  });
}

List<GithubReleaseAsset> githubReleaseAssetsFromApi(dynamic rawAssets) {
  if (rawAssets is! List) return const [];
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
  final pattern =
      '(^|[^a-z0-9_])$escaped(?=[^a-z0-9_]|'
      r'$)';
  return RegExp(pattern).hasMatch(value);
}

/// Selects the APK matching the device's ABI. A generic APK is considered
/// only when it is explicitly universal or the release has a single APK.
GithubReleaseAsset? selectCompatibleAndroidApk(
  List<GithubReleaseAsset> assets,
  List<String> supportedAbis,
) {
  final apks = assets
      .where((asset) => asset.name.toLowerCase().endsWith('.apk'))
      .toList();
  if (apks.isEmpty) return null;

  const aliasesByAbi = <String, List<String>>{
    'arm64-v8a': ['arm64-v8a', 'arm64', 'aarch64'],
    'armeabi-v7a': ['armeabi-v7a', 'armv7', 'arm32'],
    'x86_64': ['x86_64', 'x86-64', 'x64'],
    'x86': ['x86'],
  };
  final allArchitectureTokens = aliasesByAbi.values
      .expand((aliases) => aliases)
      .toSet();

  for (final abi in supportedAbis.map((abi) => abi.toLowerCase().trim())) {
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

class SettingsAboutUpdatesPage extends StatefulWidget {
  const SettingsAboutUpdatesPage({super.key});

  @override
  State<SettingsAboutUpdatesPage> createState() =>
      _SettingsAboutUpdatesPageState();
}

class _SettingsAboutUpdatesPageState extends State<SettingsAboutUpdatesPage>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _downloading = false;
  CancelToken? _downloadCancelToken;
  double? _downloadProgress;
  int _downloadReceived = 0;
  int _downloadTotal = 0;
  String _downloadAssetName = '';
  DateTime? _lastProgressUpdate;
  String? _pendingInstallPath;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _downloadCancelToken?.cancel('Update screen was closed.');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _pendingInstallPath == null) {
      return;
    }
    final path = _pendingInstallPath!;
    _pendingInstallPath = null;
    unawaited(_promptInstaller(AppL10n.of(appLocaleNotifier.value), path));
  }

  List<int> _extractVersionParts(String input) {
    final cleaned = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final matches = RegExp(r'\d+').allMatches(cleaned);
    if (matches.isEmpty) return const [0];
    return matches
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList(growable: false);
  }

  int _compareVersionStrings(String current, String latest) {
    final currentParts = _extractVersionParts(current);
    final latestParts = _extractVersionParts(latest);
    final maxLen = math.max(currentParts.length, latestParts.length);
    for (var i = 0; i < maxLen; i++) {
      final a = i < currentParts.length ? currentParts[i] : 0;
      final b = i < latestParts.length ? latestParts[i] : 0;
      if (a == b) continue;
      return a.compareTo(b);
    }
    return 0;
  }

  Future<List<String>> _supportedAbis() async {
    if (!_isAndroid) return const [];
    try {
      final raw = await _uiChannel.invokeMethod<List<dynamic>>(
        'getSupportedAbis',
      );
      return raw
              ?.map((abi) => abi.toString().trim())
              .where((abi) => abi.isNotEmpty)
              .toList(growable: false) ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> _isApkFile(File file) async {
    if (!await file.exists() || await file.length() < 1024) return false;
    final handle = await file.open();
    try {
      final header = await handle.read(4);
      return header.length == 4 && header[0] == 0x50 && header[1] == 0x4b;
    } finally {
      await handle.close();
    }
  }

  void _cancelDownload() {
    _downloadCancelToken?.cancel('Cancelled by user.');
  }

  Future<void> _promptInstaller(AppL10n l, String apkPath) async {
    final messenger = ScaffoldMessenger.of(context);
    final installResult = await _uiChannel.invokeMethod<String>('installApk', {
      'path': apkPath,
    });
    if (!mounted) return;
    if (installResult == 'permission') {
      _pendingInstallPath = apkPath;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          installResult == 'permission'
              ? l.settingsGithubInstallPermissionRequired
              : l.settingsGithubInstallerOpened,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadAndInstall(AppL10n l, GithubReleaseAsset asset) async {
    if (_downloading) return;
    final messenger = ScaffoldMessenger.of(context);
    final cacheDirectory = await getTemporaryDirectory();
    final updatesDirectory = Directory(
      '${cacheDirectory.path}${Platform.pathSeparator}updates',
    );
    await updatesDirectory.create(recursive: true);
    final safeName = asset.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final target = File(
      '${updatesDirectory.path}${Platform.pathSeparator}$safeName',
    );
    final temporary = File('${target.path}.part');
    if (await temporary.exists()) await temporary.delete();

    final cancelToken = CancelToken();
    setState(() {
      _downloading = true;
      _downloadCancelToken = cancelToken;
      _downloadProgress = asset.sizeBytes > 0 ? 0 : null;
      _downloadReceived = 0;
      _downloadTotal = asset.sizeBytes;
      _downloadAssetName = asset.name;
      _lastProgressUpdate = null;
    });

    try {
      await Dio().download(
        asset.downloadUrl,
        temporary.path,
        cancelToken: cancelToken,
        options: Options(headers: const {'User-Agent': 'UntisPlus updater'}),
        onReceiveProgress: (received, total) {
          final now = DateTime.now();
          if (_lastProgressUpdate != null &&
              now.difference(_lastProgressUpdate!).inMilliseconds < 120 &&
              total != received) {
            return;
          }
          _lastProgressUpdate = now;
          if (!mounted || cancelToken.isCancelled) return;
          setState(() {
            _downloadReceived = received;
            _downloadTotal = total > 0 ? total : asset.sizeBytes;
            _downloadProgress = total > 0 ? received / total : null;
          });
        },
      );

      if (!await _isApkFile(temporary)) {
        throw const FormatException('Downloaded file is not a valid APK.');
      }
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);

      await _promptInstaller(l, target.path);
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            CancelToken.isCancel(error)
                ? l.settingsGithubDownloadCancelled
                : l.settingsGithubDownloadFailed,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.settingsGithubDownloadFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadCancelToken = null;
          _downloadProgress = null;
          _downloadReceived = 0;
          _downloadTotal = 0;
          _downloadAssetName = '';
        });
      }
    }
  }

  Future<bool> _confirmInstall(AppL10n l, String latestVersion) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            l.settingsGithubUpdateFound(latestVersion),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.settingsGithubCurrentVersion}: $appVersion',
                style: GoogleFonts.outfit(),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.settingsGithubLatestVersion}: $latestVersion',
                style: GoogleFonts.outfit(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.settingsGithubInstallQuestion,
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.settingsGithubInstallLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.settingsGithubInstallNow),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _checkGithubUpdate() async {
    if (_checking) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    setState(() => _checking = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.settingsGithubChecking),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final resp = await http.get(
        Uri.parse(
          'https://api.github.com/repos/ninocss/UntisPlus/releases/latest',
        ),
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('GitHub API error ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid GitHub response');
      }

      final tag = (data['tag_name'] ?? '').toString().trim();
      final htmlUrl =
          (data['html_url'] ?? 'https://github.com/ninocss/UntisPlus/releases')
              .toString();
      final assets = githubReleaseAssetsFromApi(data['assets']);
      final latestVersion = tag.isEmpty ? (data['name'] ?? '').toString() : tag;
      final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersion);
      final hasUpdate = hasComparableVersion
          ? _compareVersionStrings(appVersion, latestVersion) < 0
          : true;

      if (!hasUpdate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubNoUpdate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final androidAsset = _isAndroid
          ? selectCompatibleAndroidApk(assets, await _supportedAbis())
          : null;
      if (_isAndroid && androidAsset == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.settingsGithubNoCompatibleAndroidApk),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final confirmed = await _confirmInstall(l, latestVersion);
      if (!confirmed) return;

      if (_isAndroid) {
        await _downloadAndInstall(l, androidAsset!);
        return;
      }

      final targetUrl = assets.isNotEmpty ? assets.first.downloadUrl : htmlUrl;
      final launched = await url_launcher.launchUrlString(
        targetUrl,
        mode: url_launcher.LaunchMode.externalApplication,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            launched
                ? l.settingsGithubInstallPrompted
                : l.settingsGithubOpenFailed,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsGithubCheckFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsHubUpdatesAbout,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            // ── GROUP 1: UPDATES & RELEASES ──
            SettingsGroup(
              title: l.settingsHubUpdatesAbout,
              children: [
                SettingsTile(
                  icon: Icons.system_update_alt_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsGithubUpdateCheck,
                  subtitle: l.settingsGithubUpdateCheckDesc,
                  trailing: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : _downloading
                      ? IconButton(
                          tooltip: l.settingsGithubDownloadCancel,
                          onPressed: _cancelDownload,
                          icon: const Icon(Icons.close_rounded),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _checking || _downloading ? null : _checkGithubUpdate,
                ),
                if (_downloading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.settingsGithubDownloading,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              _downloadProgress == null
                                  ? _formatBytes(_downloadReceived)
                                  : '${(_downloadProgress! * 100).clamp(0, 100).toStringAsFixed(0)} %',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 5),
                        Text(
                          _downloadTotal > 0
                              ? '${_formatBytes(_downloadReceived)} / ${_formatBytes(_downloadTotal)} · $_downloadAssetName'
                              : _downloadAssetName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                SettingsTile(
                  icon: Icons.open_in_new_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: l.settingsGithubOpenReleasePage,
                  subtitle: l.settingsGithubRepoLabel,
                  onTap: () {
                    url_launcher.launchUrlString(
                      'https://github.com/ninocss/UntisPlus/releases',
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.new_releases_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.settingsChangelogTitle,
                  subtitle: l.settingsChangelogSubtitle,
                  onTap: () => showChangelogSheet(context),
                ),
              ],
            ),

            // ── GROUP 2: APP INFO ──
            SettingsGroup(
              title: l.appName,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          size: 24,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.appName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${l.settingsAppVersion} $appVersion (${l.settingsBuild} ${appBuildNumber.isEmpty ? '-' : appBuildNumber})',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── GROUP 3: CREDITS ──
            SettingsGroup(
              title: l.settingsSectionCredits,
              children: [
                SettingsTile(
                  icon: Icons.code_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: 'ninocss',
                  subtitle: l.settingsCreditsDevelopers,
                  onTap: () {
                    url_launcher.launchUrlString(
                      'https://github.com/ninocss',
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.code_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: 'OseMine',
                  subtitle: l.settingsCreditsDevelopers,
                  onTap: () {
                    url_launcher.launchUrlString(
                      'https://github.com/OseMine',
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
