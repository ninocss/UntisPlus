part of '../main.dart';

class ChangelogData {
  final String markdown;

  ChangelogData({required this.markdown});

  factory ChangelogData.fromJson(Map<String, dynamic> json) {
    return ChangelogData(
      markdown: json['markdown'] ?? '# Keine Daten verfügbar',
    );
  }
}

class ChangelogService {
  final String url =
      'https://raw.githubusercontent.com/ninocss/UntisPlus/main/changelog.json';

  Future<ChangelogData> fetchChangelog() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return ChangelogData.fromJson(decoded);
    } else {
      throw Exception('Fehler beim Laden des Changelogs');
    }
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
  void initState() {
    super.initState();
    _changelogFuture = _service.fetchChangelog();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          'Neuigkeiten',
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
                    icon: Icon(
                      Icons.close_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.onSurfaceVariant.withValues(alpha: 0.1),
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
                      child: CircularProgressIndicator(
                        color: cs.primary,
                      ),
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
                              'Fehler beim Laden',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _changelogFuture = _service.fetchChangelog();
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  return Markdown(
                    data: data.markdown,
                    padding: EdgeInsets.fromLTRB(24, 20, 24, mq.padding.bottom + 24),
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
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
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
