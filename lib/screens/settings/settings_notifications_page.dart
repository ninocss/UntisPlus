// settings_notifications_page.dart
part of '../../main.dart';

class SettingsNotificationsPage extends StatelessWidget {
  const SettingsNotificationsPage({super.key});

  Future<void> _setEnabled(
    BuildContext context,
    bool enabled,
    Future<void> Function(bool) persist,
  ) async {
    if (enabled) {
      await NotificationService().init();
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appL10nFor(appLocaleNotifier.value).notificationsDenied,
            ),
          ),
        );
        return;
      }
    }
    await persist(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return SettingsPageShell(
      title: l.settingsHubNotifications,
      children: [
        SettingsGroup(
          title: l.settingsHubNotifications,
          children: [
            SettingsTile(
              icon: Icons.widgets_rounded,
              iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
              iconColor: cs.onTertiaryContainer,
              title: l.notificationsWidgets,
              subtitle: l.notificationsWidgetsDesc,
              onTap: () => Navigator.push(
                context,
                _buildBouncyRoute(const SettingsWidgetsPage()),
              ),
            ),
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
                  onChanged: (enabled) => _setEnabled(
                    context,
                    enabled,
                    _settingsSetProgressivePush,
                  ),
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
                  onChanged: (enabled) => _setEnabled(
                    context,
                    enabled,
                    _settingsSetDailyBriefingPush,
                  ),
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
                  onChanged: (enabled) => _setEnabled(
                    context,
                    enabled,
                    _settingsSetImportantChangesPush,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
