part of '../main.dart';

class ChangelogData {
  final String markdown;
  final String version;
  final DateTime? publishedAt;
  final String? releaseUrl;

  const ChangelogData({
    required this.markdown,
    required this.version,
    this.publishedAt,
    this.releaseUrl,
  });

  factory ChangelogData.fromJson(Map<String, dynamic> json, AppL10n l) {
    return ChangelogData(
      markdown: (json['markdown'] ?? '').toString().trim().isEmpty
          ? l.changelogNoData
          : json['markdown'].toString(),
      version: (json['version'] ?? appVersion).toString(),
      publishedAt: DateTime.tryParse(
        (json['published_at'] ?? json['generated_at'] ?? '').toString(),
      ),
      releaseUrl: (json['release_url'] ?? '').toString().trim().isEmpty
          ? null
          : json['release_url'].toString(),
    );
  }

  factory ChangelogData.fromGithubRelease(
    Map<String, dynamic> json,
    AppL10n l,
  ) {
    return ChangelogData(
      markdown: (json['body'] ?? '').toString().trim().isEmpty
          ? l.changelogNoData
          : json['body'].toString(),
      version: (json['tag_name'] ?? json['name'] ?? appVersion).toString(),
      publishedAt: DateTime.tryParse(
        (json['published_at'] ?? json['created_at'] ?? '').toString(),
      ),
      releaseUrl: (json['html_url'] ?? '').toString().trim().isEmpty
          ? null
          : json['html_url'].toString(),
    );
  }
}

class ChangelogService {
  static const _releaseUrl =
      'https://api.github.com/repos/ninocss/UntisPlus/releases/latest';
  static const _legacyUrl =
      'https://raw.githubusercontent.com/ninocss/UntisPlus/main/changelog.json';

  Future<ChangelogData> fetchChangelog(AppL10n l) async {
    try {
      final response = await http.get(
        Uri.parse(_releaseUrl),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'UntisPlus changelog',
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final data = ChangelogData.fromGithubRelease(decoded, l);
          if (data.markdown != l.changelogNoData) return data;
        }
      }
    } catch (_) {
      // A bundled changelog keeps this screen useful while offline.
    }
    return _loadFallback(l);
  }

  Future<ChangelogData> _loadFallback(AppL10n l) async {
    try {
      final bundled = await rootBundle.loadString('changelog.json');
      final decoded = jsonDecode(bundled);
      if (decoded is Map<String, dynamic>) {
        return ChangelogData.fromJson(decoded, l);
      }
    } catch (_) {
      // Older app packages did not bundle changelog.json.
    }

    try {
      final response = await http.get(Uri.parse(_legacyUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return ChangelogData.fromJson(decoded, l);
        }
      }
    } catch (_) {}

    return ChangelogData(markdown: l.changelogNoData, version: appVersion);
  }
}

Future<void> showChangelogSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) {
      return const ChangelogWidget();
    },
  );
}

class ChangelogWidget extends StatefulWidget {
  const ChangelogWidget({super.key});

  @override
  State<ChangelogWidget> createState() => _ChangelogWidgetState();
}

class _ChangelogWidgetState extends State<ChangelogWidget> {
  final ChangelogService _service = ChangelogService();
  late Future<ChangelogData> _changelogFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppL10n.of(appLocaleNotifier.value);
    _changelogFuture = _service.fetchChangelog(l);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;

    return _sheetSurface(
      context: context,
      blur: blurEnabledNotifier.value,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.new_releases_rounded,
                      color: cs.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppL10n.of(appLocaleNotifier.value).changelogTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Untis+ $appVersion',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.onSurfaceVariant.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<ChangelogData>(
                future: _changelogFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: cs.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppL10n.of(
                                appLocaleNotifier.value,
                              ).changelogLoadError,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _changelogFuture = _service.fetchChangelog(
                                    AppL10n.of(appLocaleNotifier.value),
                                  );
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                AppL10n.of(
                                  appLocaleNotifier.value,
                                ).changelogRetry,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final locale = switch (AppL10n.of(
                    appLocaleNotifier.value,
                  ).locale) {
                    'en' => 'en_US',
                    'fr' => 'fr_FR',
                    'es' => 'es_ES',
                    _ => 'de_DE',
                  };
                  final releaseDate = data.publishedAt == null
                      ? null
                      : DateFormat.yMMMd(
                          locale,
                        ).format(data.publishedAt!.toLocal());
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 17,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                releaseDate == null
                                    ? data.version
                                    : '${data.version} · $releaseDate',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            if (data.releaseUrl != null)
                              IconButton(
                                tooltip: data.releaseUrl,
                                onPressed: () => unawaited(
                                  url_launcher.launchUrlString(
                                    data.releaseUrl!,
                                    mode: url_launcher
                                        .LaunchMode
                                        .externalApplication,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                  color: cs.onPrimaryContainer,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Markdown(
                          data: data.markdown,
                          padding: EdgeInsets.fromLTRB(
                            24,
                            20,
                            24,
                            mq.padding.bottom + 24,
                          ),
                          physics: const BouncingScrollPhysics(),
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(
                              fontSize: 15,
                              color: cs.onSurface.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                            h1: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            h2: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            h3: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            listBullet: TextStyle(
                              color: cs.primary,
                              fontSize: 18,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            code: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: cs.primary,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
