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
              AppL10n.of(appLocaleNotifier.value).ui('notificationsDenied'),
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
                SettingsTile(
                  icon: Icons.widgets_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.ui('notificationsWidgets'),
                  subtitle: l.ui('notificationsWidgetsDesc'),
                  onTap: () => Navigator.push(
                    context,
                    _buildBouncyRoute(const SettingsWidgetsPage()),
                  ),
                ),
                if (Platform.isAndroid)
                  SettingsTile(
                    icon: Icons.alarm_rounded,
                    iconBackgroundColor: cs.primaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    iconColor: cs.onPrimaryContainer,
                    title: l.ui('notificationsAlarms'),
                    subtitle: l.ui('notificationsAlarmsDesc'),
                    onTap: () => Navigator.push(
                      context,
                      _buildBouncyRoute(const SettingsAlarmPage()),
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
        ),
      ),
    );
  }
}
