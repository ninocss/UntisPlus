// settings_timetable_page.dart
part of '../../main.dart';

class SettingsTimetablePage extends StatelessWidget {
  const SettingsTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionTimetable,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: showCancelledNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetShowCancelled,
                    title: Text(
                      l.settingsShowCancelled,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsShowCancelledDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: Text(
                  l.settingsRefreshPushWidgetNow,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsRefreshPushWidgetNowDesc,
                  style: GoogleFonts.outfit(),
                ),
                onTap: () async {
                  await updateUntisData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.settingsBackgroundLoading),
                      behavior: SnackBarBehavior.floating,
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