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
    final prefs = SettingsStore.instance.preferences;
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
    final l = appL10nFor(appLocaleNotifier.value);
    final confirmed = await showUntisDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.accountRemoveQuestion),
        content: Text(l.accountRemoveDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.accountRemove),
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

  /// Lets the developer point developer mode at a different local server. The
  /// address is validated by [_settingsSetDevServerUrl]; anything that cannot
  /// be connected to keeps the previous value and reports why.
  Future<void> _editDevServerUrl(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final initialText = normalizeDevServerUrl(devServerUrlNotifier.value);

    final value = await showUntisDialog<String>(
      context: context,
      builder: (dialogContext) {
        // Controller created inside the builder so it lives and dies with the
        // dialog widget tree. Avoids "controller used after dispose" when the
        // Save button closes the dialog while the TextField is still animating.
        final controller = TextEditingController(text: initialText);
        return AlertDialog(
          title: Text(l.settingsDevModeServer),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: kDefaultDevServerUrl,
              helperText: l.settingsDevModeServerDesc,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(dialogContext, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.save),
            ),
          ],
        );
      },
    );
    if (value == null || !context.mounted) return;
    final accepted = await _settingsSetDevServerUrl(value);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          accepted ? l.settingsDevModeSaved : l.settingsDevModeInvalidServer,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Opens the development server's source repository in the browser. Used by
  /// both the developer-mode tile and the sheet it opens, so a failure in either
  /// place reports the same way.
  Future<void> _openDevServerRepository(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await url_launcher.launchUrlString(
      kDevServerRepositoryUrl,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (ok || !context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.settingsDevModeOpenFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Explains what developer mode replaces and links to the server's
  /// repository, for anyone who turns the toggle on without a server running.
  Future<void> _showDevServerAboutSheet(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    return showUntisModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final paragraph = GoogleFonts.outfit(
          fontSize: 14.5,
          height: 1.5,
          color: cs.onSurfaceVariant,
        );
        return UntisSheetScaffold(
          title: Text(
            l.settingsDevModeAboutTitle,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          // The scaffold already insets the top through its drag handle and
          // title spacing, so only the trailing side needs padding here.
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.settingsDevModeAboutBody, style: paragraph),
              const SizedBox(height: 14),
              Text(l.settingsDevModeAboutCoverage, style: paragraph),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openDevServerRepository(ctx),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l.settingsDevModeRepository),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _devModeNotificationStyleLabel(DevModeNotificationStyle style, dynamic l) {
    switch (style) {
      case DevModeNotificationStyle.popup:
        return l.settingsDevModeNotificationStylePopup;
      case DevModeNotificationStyle.bar:
        return l.settingsDevModeNotificationStyleBar;
      case DevModeNotificationStyle.none:
        return l.settingsDevModeNotificationStyleNone;
    }
  }

  Future<void> _editDevServerSchoolName(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final controller = TextEditingController(text: devServerSchoolNameNotifier.value);
    try {
      final value = await showUntisDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.settingsDevModeSchoolName),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: l.settingsDevModeSchoolNameDesc,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(dialogContext, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (value == null || !context.mounted) return;
      await _settingsSetDevServerSchoolName(value);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.settingsDevModeSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editDevServerUsername(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final controller = TextEditingController(text: devServerUsernameNotifier.value);
    try {
      final value = await showUntisDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.settingsDevModeUsername),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: l.settingsDevModeUsernameDesc,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(dialogContext, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (value == null || !context.mounted) return;
      await _settingsSetDevServerUsername(value);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.settingsDevModeSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editDevServerPassword(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final controller = TextEditingController(text: devServerPasswordNotifier.value);
    try {
      final value = await showUntisDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.settingsDevModePassword),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: l.settingsDevModePasswordDesc,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(dialogContext, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (value == null || !context.mounted) return;
      await _settingsSetDevServerPassword(value);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.settingsDevModeSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _selectDevModeNotificationStyle(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    await showUntisModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) => UntisSheetScaffold(
        title: Text(l.settingsDevModeNotificationStyle),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final style in DevModeNotificationStyle.values)
              ListTile(
                title: Text(_devModeNotificationStyleLabel(style, l)),
                leading: Radio<DevModeNotificationStyle>(
                  // ignore: deprecated_member_use
                  value: style,
                  // ignore: deprecated_member_use
                  groupValue: devModeNotificationStyleNotifier.value,
                  onChanged: (value) {
                    if (value != null) {
                      _settingsSetDevModeNotificationStyle(value);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return SettingsPageShell(
      title: l.settingsHubAccount,
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
              title: l.accountRemoveThis,
              subtitle: l.accountSignOut,
              destructive: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _removeActiveAccount,
            ),
          ],
        ),

        ValueListenableBuilder<List<UntisAccount>>(
          valueListenable: untisAccountsNotifier,
          builder: (context, accounts, _) => SettingsGroup(
            title: l.accounts,
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
                title: l.accountAdd,
                subtitle: l.accountConnect,
                trailing: const Icon(Icons.add_rounded),
                onTap: () => Navigator.of(context).push(
                  _buildBouncyRoute(const OnboardingFlow(accountOnly: true)),
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
                  icon: Icons.abc_rounded,
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

        // ── GROUP 3: DEVELOPER MODE ──
        ValueListenableBuilder<bool>(
          valueListenable: devModeNotifier,
          builder: (context, devMode, _) => SettingsGroup(
            title: l.settingsDevMode,
            children: [
              SettingsSwitchTile(
                icon: Icons.science_rounded,
                iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
                iconColor: cs.onTertiaryContainer,
                title: l.settingsDevMode,
                subtitle: l.settingsDevModeDesc,
                value: devMode,
                onChanged: _settingsSetDevMode,
              ),
              if (devMode) ...[
                ValueListenableBuilder<String>(
                  valueListenable: devServerUrlNotifier,
                  builder: (context, serverUrl, _) => SettingsTile(
                    icon: Icons.dns_rounded,
                    iconBackgroundColor: cs.surfaceContainerHighest,
                    iconColor: cs.onSurfaceVariant,
                    title: l.settingsDevModeServer,
                    subtitle: normalizeDevServerUrl(serverUrl),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editDevServerUrl(context),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: devUseHttpsNotifier,
                  builder: (context, useHttps, _) => SettingsSwitchTile(
                    icon: Icons.lock_rounded,
                    iconBackgroundColor: cs.surfaceContainerHighest,
                    iconColor: cs.onSurfaceVariant,
                    title: l.settingsDevModeUseHttps,
                    subtitle: l.settingsDevModeUseHttpsDesc,
                    value: useHttps,
                    onChanged: _settingsSetDevUseHttps,
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: devServerSchoolNameNotifier,
                  builder: (context, schoolName, _) => SettingsTile(
                    icon: Icons.school_rounded,
                    iconBackgroundColor: cs.surfaceContainerHighest,
                    iconColor: cs.onSurfaceVariant,
                    title: l.settingsDevModeSchoolName,
                    subtitle: schoolName.isEmpty ? l.settingsDevModeSchoolNameDesc : schoolName,
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editDevServerSchoolName(context),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: devServerUsernameNotifier,
                  builder: (context, username, _) => SettingsTile(
                    icon: Icons.person_rounded,
                    iconBackgroundColor: cs.surfaceContainerHighest,
                    iconColor: cs.onSurfaceVariant,
                    title: l.settingsDevModeUsername,
                    subtitle: username.isEmpty ? l.settingsDevModeUsernameDesc : username,
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editDevServerUsername(context),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: devServerPasswordNotifier,
                  builder: (context, password, _) => SettingsTile(
                    icon: Icons.lock_rounded,
                    iconBackgroundColor: cs.surfaceContainerHighest,
                    iconColor: cs.onSurfaceVariant,
                    title: l.settingsDevModePassword,
                    subtitle: password.isEmpty ? l.settingsDevModePasswordDesc : '•' * password.length,
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editDevServerPassword(context),
                  ),
                ),
                ValueListenableBuilder<DevModeNotificationStyle>(
                  valueListenable: devModeNotificationStyleNotifier,
                  builder: (context, style, _) => SettingsTile(
                    icon: Icons.notifications_rounded,
                    iconBackgroundColor: cs.surfaceContainerHighest,
                    iconColor: cs.onSurfaceVariant,
                    title: l.settingsDevModeNotificationStyle,
                    subtitle: _devModeNotificationStyleLabel(style, l),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _selectDevModeNotificationStyle(context),
                  ),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconBackgroundColor: cs.surfaceContainerHighest,
                  iconColor: cs.onSurfaceVariant,
                  title: l.settingsDevModeAbout,
                  subtitle: l.settingsDevModeAboutDesc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDevServerAboutSheet(context),
                ),
                SettingsTile(
                  icon: Icons.open_in_new_rounded,
                  iconBackgroundColor: cs.surfaceContainerHighest,
                  iconColor: cs.onSurfaceVariant,
                  title: l.settingsDevModeRepository,
                  subtitle: l.settingsDevModeRepositoryDesc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDevServerRepository(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
