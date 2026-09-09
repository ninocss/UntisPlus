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
  String? _switchingAccountId;

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

  Future<void> _switchAccount(UntisAccount account) async {
    if (account.id == activeUntisAccountId || _switchingAccountId != null) {
      return;
    }
    setState(() => _switchingAccountId = account.id);
    await switchUntisAccount(account.id);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _buildBouncyRoute(const MainNavigationScreen()),
      (route) => false,
    );
  }

  Future<void> _removeActiveAccount() async {
    final activeId = activeUntisAccountId;
    if (activeId == null) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.ui('accountRemoveQuestion')),
        content: Text(l.ui('accountRemoveDesc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.ui('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.ui('accountRemove')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final hasNextAccount = await removeUntisAccount(activeId);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _buildBouncyRoute(
        hasNextAccount ? const MainNavigationScreen() : const OnboardingFlow(),
      ),
      (route) => false,
    );
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
                  icon: Icons.person_remove_rounded,
                  iconBackgroundColor: cs.errorContainer.withValues(alpha: 0.8),
                  iconColor: cs.onErrorContainer,
                  title: l.ui('accountRemoveThis'),
                  subtitle: l.ui('accountSignOut'),
                  destructive: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _removeActiveAccount,
                ),
              ],
            ),

            ValueListenableBuilder<List<UntisAccount>>(
              valueListenable: untisAccountsNotifier,
              builder: (context, accounts, _) => SettingsGroup(
                title: l.ui('accounts'),
                children: [
                  for (final account in accounts)
                    SettingsTile(
                      icon: account.id == activeUntisAccountId
                          ? Icons.check_circle_rounded
                          : Icons.account_circle_outlined,
                      iconBackgroundColor: account.id == activeUntisAccountId
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      iconColor: account.id == activeUntisAccountId
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                      title: account.label,
                      subtitle: '${account.schoolName} · ${account.schoolUrl}',
                      trailing: _switchingAccountId == account.id
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : account.id == activeUntisAccountId
                          ? const Icon(Icons.check_rounded)
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () => _switchAccount(account),
                    ),
                  SettingsTile(
                    icon: Icons.person_add_alt_1_rounded,
                    title: l.ui('accountAdd'),
                    subtitle: l.ui('accountConnect'),
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () => Navigator.of(context).push(
                      _buildBouncyRoute(
                        const OnboardingFlow(accountOnly: true),
                      ),
                    ),
                  ),
                ],
              ),
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
