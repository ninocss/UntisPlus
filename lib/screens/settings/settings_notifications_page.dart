// settings_notifications_page.dart
part of '../../main.dart';

class SettingsNotificationsPage extends StatelessWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

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
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            SettingsGroup(
              title: l.settingsHubNotifications,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: progressivePushNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.timelapse_rounded,
                      iconBackgroundColor: cs.primaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onPrimaryContainer,
                      title: l.settingsProgressivePush,
                      subtitle: l.settingsProgressivePushDesc,
                      value: value,
                      onChanged: _settingsSetProgressivePush,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: dailyBriefingPushNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.wb_sunny_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsDailyBriefingPush,
                      subtitle: l.settingsDailyBriefingPushDesc,
                      value: value,
                      onChanged: _settingsSetDailyBriefingPush,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: importantChangesPushNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.notifications_active_rounded,
                      iconBackgroundColor: cs.tertiaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onTertiaryContainer,
                      title: l.settingsImportantChangesPush,
                      subtitle: l.settingsImportantChangesPushDesc,
                      value: value,
                      onChanged: _settingsSetImportantChangesPush,
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
