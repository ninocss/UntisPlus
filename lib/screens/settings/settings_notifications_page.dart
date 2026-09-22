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
      appBar: _settingsHeaderAppBar(context, l.settingsHubNotifications),
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
                // #138: per-category filters for the important-changes
                // notification, only relevant while the master toggle is on.
                ValueListenableBuilder<bool>(
                  valueListenable: importantChangesPushNotifier,
                  builder: (context, enabled, _) {
                    if (!enabled) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _buildChangeCategoryToggle(
                          icon: Icons.event_busy_rounded,
                          iconBackgroundColor: cs.errorContainer.withValues(
                            alpha: 0.7,
                          ),
                          iconColor: cs.onErrorContainer,
                          title: l.settingsNotifyChangeCancellations,
                          subtitle: l.settingsNotifyChangeCancellationsDesc,
                          valueListenable: notifyChangeCancellationsNotifier,
                          setter: _settingsSetNotifyChangeCancellations,
                        ),
                        _buildChangeCategoryToggle(
                          icon: Icons.meeting_room_rounded,
                          iconBackgroundColor: cs.tertiaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          iconColor: cs.onTertiaryContainer,
                          title: l.settingsNotifyChangeRoom,
                          subtitle: l.settingsNotifyChangeRoomDesc,
                          valueListenable: notifyChangeRoomNotifier,
                          setter: _settingsSetNotifyChangeRoom,
                        ),
                        _buildChangeCategoryToggle(
                          icon: Icons.support_agent_rounded,
                          iconBackgroundColor: cs.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          iconColor: cs.onSecondaryContainer,
                          title: l.settingsNotifyChangeTeacher,
                          subtitle: l.settingsNotifyChangeTeacherDesc,
                          valueListenable: notifyChangeTeacherNotifier,
                          setter: _settingsSetNotifyChangeTeacher,
                        ),
                        _buildChangeCategoryToggle(
                          icon: Icons.more_horiz_rounded,
                          iconBackgroundColor: cs.primaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          iconColor: cs.onPrimaryContainer,
                          title: l.settingsNotifyChangeOther,
                          subtitle: l.settingsNotifyChangeOtherDesc,
                          valueListenable: notifyChangeOtherNotifier,
                          setter: _settingsSetNotifyChangeOther,
                        ),
                      ],
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

  Widget _buildChangeCategoryToggle({
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ValueListenable<bool> valueListenable,
    required Future<void> Function(bool) setter,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueListenable,
      builder: (context, value, _) {
        return SettingsSwitchTile(
          icon: icon,
          iconBackgroundColor: iconBackgroundColor,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          value: value,
          onChanged: (enabled) => _setEnabled(context, enabled, setter),
        );
      },
    );
  }
}
