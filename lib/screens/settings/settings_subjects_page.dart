// settings_subjects_page.dart
part of '../../main.dart';

class SettingsSubjectsPage extends StatelessWidget {
  const SettingsSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

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
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            SettingsGroup(
              title: l.settingsSectionSubjects,
              children: [
                SettingsTile(
                  icon: Icons.color_lens_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsSectionColors,
                  subtitle: l.settingsColorsDesc,
                  onTap: () {
                    Navigator.push(
                      context,
                      _buildBouncyRoute(const SubjectColorsPage()),
                    );
                  },
                ),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: hiddenSubjectsNotifier,
                  builder: (context, hidden, _) {
                    return SettingsTile(
                      icon: Icons.visibility_off_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsSectionHidden,
                      subtitle:
                          hidden.isEmpty
                              ? l.settingsNoHidden
                              : l.settingsHiddenCount(hidden.length),
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildBouncyRoute(const HiddenSubjectsPage()),
                        );
                      },
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
