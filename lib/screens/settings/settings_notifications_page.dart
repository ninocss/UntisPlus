part of '../../main.dart';

class SettingsNotificationsPage extends StatelessWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsHubNotifications,
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
              child: ValueListenableBuilder<bool>(
                valueListenable: progressivePushNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetProgressivePush,
                    title: Text(
                      l.settingsProgressivePush,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsProgressivePushDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: dailyBriefingPushNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetDailyBriefingPush,
                    title: Text(
                      l.settingsDailyBriefingPush,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsDailyBriefingPushDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: importantChangesPushNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetImportantChangesPush,
                    title: Text(
                      l.settingsImportantChangesPush,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsImportantChangesPushDesc,
                      style: GoogleFonts.outfit(),
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
