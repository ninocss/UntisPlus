// settings_account_page.dart
part of '../../main.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  String _username = '';
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? '';
      _serverUrl = prefs.getString('schoolUrl') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsHubAccount,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            // ── GROUP 1: ACCOUNT ──
            SettingsGroup(
              title: l.settingsHubAccount,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_circle_rounded,
                          size: 28,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.settingsLoggedInAs,
                              style: GoogleFonts.outfit(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _username.isEmpty ? '—' : _username,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: cs.onSurface,
                              ),
                            ),
                            if (_serverUrl.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _serverUrl,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  iconBackgroundColor: cs.errorContainer.withValues(alpha: 0.8),
                  iconColor: cs.onErrorContainer,
                  title: l.settingsLogout,
                  destructive: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _settingsLogout(context),
                ),
              ],
            ),

            // ── GROUP 2: DEMO MODE ──
            SettingsGroup(
              title: l.settingsDemoMode,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: demoModeNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.science_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsDemoMode,
                      subtitle: l.settingsDemoModeDesc,
                      value: value,
                      onChanged: (v) => _settingsSetDemoMode(context, v),
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
