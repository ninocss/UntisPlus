part of '../../main.dart';

class SettingsSubjectsPage extends StatelessWidget {
  const SettingsSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionSubjects,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(
                  l.settingsSectionColors,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsColorsDesc,
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    _buildBouncyRoute(const SubjectColorsPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: hiddenSubjectsNotifier,
                builder: (context, hidden, _) {
                  return ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: Text(
                      l.settingsSectionHidden,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      hidden.isEmpty
                          ? l.settingsNoHidden
                          : l.settingsHiddenCount(hidden.length),
                      style: GoogleFonts.outfit(),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        _buildBouncyRoute(const HiddenSubjectsPage()),
                      );
                    },
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
