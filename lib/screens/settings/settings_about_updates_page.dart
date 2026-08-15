// settings_about_updates_page.dart
part of '../../main.dart';

class SettingsAboutUpdatesPage extends StatefulWidget {
  const SettingsAboutUpdatesPage({super.key});

  @override
  State<SettingsAboutUpdatesPage> createState() =>
      _SettingsAboutUpdatesPageState();
}

class _SettingsAboutUpdatesPageState extends State<SettingsAboutUpdatesPage> {
  bool _checking = false;

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

  String? _pickReleaseAssetUrl(List<dynamic> assets) {
    String? fallback;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = (asset['name'] ?? '').toString().toLowerCase();
      final url = (asset['browser_download_url'] ?? '').toString();
      if (url.isEmpty) continue;
      fallback ??= url;
      if (name.endsWith('.apk')) return url;
    }
    return fallback;
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
      final assets =
          (data['assets'] is List)
              ? data['assets'] as List<dynamic>
              : const <dynamic>[];
      final assetUrl = _pickReleaseAssetUrl(assets);
      final targetUrl = assetUrl ?? htmlUrl;
      final latestVersion =
          tag.isEmpty ? (data['name'] ?? '').toString() : tag;
      final hasComparableVersion = RegExp(r'\d').hasMatch(latestVersion);
      final hasUpdate =
          hasComparableVersion
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

      final confirmed = await _confirmInstall(l, latestVersion);
      if (!confirmed) return;

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
                  trailing:
                      _checking
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                          : const Icon(Icons.chevron_right_rounded),
                  onTap: _checking ? null : _checkGithubUpdate,
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
          ],
        ),
      ),
    );
  }
}
