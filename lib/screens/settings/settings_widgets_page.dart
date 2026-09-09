part of '../../main.dart';

class SettingsWidgetsPage extends StatefulWidget {
  const SettingsWidgetsPage({super.key});

  @override
  State<SettingsWidgetsPage> createState() => _SettingsWidgetsPageState();
}

class _SettingsWidgetsPageState extends State<SettingsWidgetsPage> {
  static const _types = [
    (
      id: 'current',
      label: 'Jetzt',
      icon: Icons.bolt_rounded,
      description: 'Aktuelle Stunde, nächste Stunde und verbleibende Zeit',
      size: 'Klein oder mittel',
    ),
    (
      id: 'schedule',
      label: 'Tagesplan',
      icon: Icons.view_agenda_rounded,
      description: 'Die nächsten Einträge deines heutigen Stundenplans',
      size: 'Mittel oder groß',
    ),
    (
      id: 'homework',
      label: 'Aufgaben',
      icon: Icons.assignment_rounded,
      description: 'Eine kompakte Übersicht deiner offenen Aufgaben',
      size: 'Klein oder mittel',
    ),
    (
      id: 'notices',
      label: 'Mitteilungen',
      icon: Icons.markunread_rounded,
      description: 'Die neuesten Mitteilungen auf deinem Homescreen',
      size: 'Klein oder mittel',
    ),
  ];

  String _selectedType = 'current';
  String? _accountId;
  WidgetPreviewData _previewData = const WidgetPreviewData();
  bool _loadingPreview = true;
  bool _pinning = false;

  @override
  void initState() {
    super.initState();
    _accountId = activeUntisAccountId;
    untisAccountsNotifier.addListener(_handleAccountsChanged);
    unawaited(_reloadPreview());
  }

  @override
  void dispose() {
    untisAccountsNotifier.removeListener(_handleAccountsChanged);
    super.dispose();
  }

  void _handleAccountsChanged() {
    if (!mounted) return;
    final accounts = untisAccountsNotifier.value;
    final selectedStillExists = accounts.any(
      (account) => account.id == _accountId,
    );
    final activeStillExists = accounts.any(
      (account) => account.id == activeUntisAccountId,
    );
    final nextAccountId = selectedStillExists
        ? _accountId
        : activeStillExists
        ? activeUntisAccountId
        : accounts.isEmpty
        ? null
        : accounts.first.id;
    if (nextAccountId == _accountId) return;
    setState(() => _accountId = nextAccountId);
    unawaited(_reloadPreview());
  }

  UntisAccount? get _account {
    for (final account in untisAccountsNotifier.value) {
      if (account.id == _accountId) return account;
    }
    final accounts = untisAccountsNotifier.value;
    return accounts.isEmpty ? null : accounts.first;
  }

  Future<void> _selectAccount(String accountId) async {
    if (_accountId == accountId) return;
    HapticFeedback.selectionClick();
    setState(() => _accountId = accountId);
    await _reloadPreview();
  }

  Future<void> _reloadPreview() async {
    final accountId = _accountId;
    if (accountId == null ||
        kIsWeb ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      if (mounted) {
        setState(() {
          _previewData = const WidgetPreviewData();
          _loadingPreview = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loadingPreview = true);
    final data = await WidgetService.readPreviewData(accountId);
    if (!mounted || accountId != _accountId) return;
    setState(() {
      _previewData = data;
      _loadingPreview = false;
    });
  }

  Future<void> _pinSelectedWidget() async {
    if (kIsWeb || !Platform.isAndroid || _pinning) return;
    final accountId = _accountId;
    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wähle zuerst ein Konto aus.')),
      );
      return;
    }
    final name = switch (_selectedType) {
      'schedule' => 'UntisWidgetDailySchedule',
      'homework' => 'UntisWidgetHomework',
      'notices' => 'UntisWidgetNotifications',
      _ => 'UntisWidgetCurrentLesson',
    };
    setState(() => _pinning = true);
    try {
      final supported = await WidgetService.requestPinWidget(
        name: name,
        qualifiedAndroidName: 'com.ninocss.untisplus.$name',
        preferredAccountId: accountId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            supported
                ? 'Widget-Anfrage wurde an den Homescreen gesendet.'
                : 'Öffne den Widget-Picker über deinen Homescreen.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Das Widget konnte nicht hinzugefügt werden. Öffne den Widget-Picker über den Homescreen.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  Widget _statusPill(BuildContext context, ColorScheme cs, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, ColorScheme cs) {
    final account = _account;
    final data = _previewData;
    final hasData = data.hasPublishedData;
    final accountLabel = data.accountLabel.trim().isNotEmpty
        ? data.accountLabel.trim()
        : account?.label ?? 'Untis+';
    final status = _loadingPreview
        ? 'LÄDT'
        : data.status.trim().isNotEmpty
        ? data.status.trim()
        : hasData
        ? 'AKTUELL'
        : 'VORSCHAU';
    final isSchedule = _selectedType == 'schedule';
    final title = switch (_selectedType) {
      'schedule' => 'HEUTE',
      'homework' => 'AUFGABEN',
      'notices' => 'MITTEILUNGEN',
      _ => accountLabel,
    };
    final headline = switch (_selectedType) {
      'schedule' =>
        data.dailySchedule.trim().isNotEmpty
            ? data.dailySchedule.trim()
            : 'Noch keine Tagesdaten',
      'homework' =>
        data.homeworkSummary.trim().isNotEmpty
            ? data.homeworkSummary.trim()
            : 'Keine offenen Aufgaben synchronisiert',
      'notices' =>
        data.notificationSummary.trim().isNotEmpty
            ? data.notificationSummary.trim()
            : 'Keine Mitteilungen synchronisiert',
      _ =>
        data.currentLesson.trim().isNotEmpty
            ? data.currentLesson.trim()
            : 'Keine aktuelle Stunde',
    };
    final detail = data.nextLesson.trim().isNotEmpty
        ? data.nextLesson.trim()
        : 'Stundenplan öffnen, um Daten zu laden';
    final footer = data.timeRemaining.trim().isNotEmpty
        ? data.timeRemaining.trim()
        : hasData
        ? 'Untis+'
        : 'Noch nicht synchronisiert';

    return Semantics(
      label:
          'Vorschau für ${_types.firstWhere((type) => type.id == _selectedType).label}',
      child: AnimatedContainer(
        key: ValueKey('widget-preview-$_selectedType'),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        // All preview variants share the taller canvas.  Switching from a
        // compact preview to the four-line schedule used to animate from 190
        // to 220 px while the schedule copy appeared immediately, briefly
        // leaving the text column too short.
        height: 220,
        constraints: BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(40),
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _selectedType == 'current'
                          ? cs.onSurfaceVariant
                          : cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: _selectedType == 'current' ? 0 : 0.8,
                    ),
                  ),
                ),
                if (_selectedType != 'current') ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      accountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else
                  _statusPill(context, cs, status),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(
                      'widget-preview-copy-$_selectedType-$accountLabel',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        maxLines: isSchedule ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: isSchedule
                            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: cs.onSurface,
                                height: 1.42,
                                fontWeight: FontWeight.w700,
                              )
                            : Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: cs.onSurface,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                      ),
                      if (_selectedType == 'current') ...[
                        const SizedBox(height: 7),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_selectedType == 'current')
                  Flexible(child: _statusPill(context, cs, footer))
                else
                  _statusPill(context, cs, status),
                const Spacer(),
                if (_selectedType == 'current')
                  Icon(
                    Icons.more_horiz_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformInstructions(bool isAndroid, bool isIOS) {
    if (isAndroid) {
      return SettingsGroup(
        title: 'Zum Homescreen',
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _accountId == null || _pinning
                    ? null
                    : _pinSelectedWidget,
                icon: _pinning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_to_home_screen_rounded),
                label: Text(
                  _pinning
                      ? 'Widget-Picker wird geöffnet …'
                      : 'Widget hinzufügen',
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Das ausgewählte Konto wird im Android-Dialog vorausgewählt. Dort kannst du es vor dem Hinzufügen noch ändern.',
            ),
          ),
        ],
      );
    }
    if (isIOS) {
      return const SettingsGroup(
        title: 'Zum Homescreen',
        children: [
          SettingsTile(
            icon: Icons.looks_one_rounded,
            title: 'Homescreen gedrückt halten',
            subtitle:
                'Tippe danach oben auf „Bearbeiten“ und auf „Widget hinzufügen“.',
            trailing: null,
          ),
          SettingsTile(
            icon: Icons.looks_two_rounded,
            title: 'Untis+ auswählen',
            subtitle: 'Wähle die gewünschte Variante und Größe aus.',
            trailing: null,
          ),
          SettingsTile(
            icon: Icons.looks_3_rounded,
            title: 'Konto festlegen',
            subtitle:
                'Halte das Widget gedrückt und wähle „Widget bearbeiten“.',
            trailing: null,
          ),
        ],
      );
    }
    return const SettingsGroup(
      title: 'Zum Homescreen',
      children: [
        SettingsTile(
          icon: Icons.devices_other_rounded,
          title: 'Auf diesem Gerät nicht verfügbar',
          subtitle:
              'Homescreen-Widgets werden auf Android und iOS unterstützt.',
          trailing: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIOS = !kIsWeb && Platform.isIOS;
    final selected = _types.firstWhere((type) => type.id == _selectedType);
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: const Text('Widgets & Vorschau'),
        actions: [
          IconButton(
            tooltip: 'Vorschau aktualisieren',
            onPressed: _loadingPreview ? null : _reloadPreview,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vorschau',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_loadingPreview)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Center(child: _preview(context, cs)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: Text(
                _previewData.hasPublishedData
                    ? 'Die Vorschau verwendet die zuletzt für dieses Konto synchronisierten Widget-Daten.'
                    : 'Öffne einmal den Stundenplan, damit echte Widget-Daten synchronisiert werden.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            SettingsGroup(
              title: 'Widget auswählen',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in _types)
                        ChoiceChip(
                          avatar: Icon(type.icon, size: 18),
                          label: Text(type.label),
                          selected: _selectedType == type.id,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedType = type.id);
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(selected.icon, size: 20, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selected.size,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<List<UntisAccount>>(
              valueListenable: untisAccountsNotifier,
              builder: (context, accounts, _) => SettingsGroup(
                title: 'Konto für die Vorschau',
                children: accounts.isEmpty
                    ? const [
                        SettingsTile(
                          icon: Icons.person_off_outlined,
                          title: 'Kein Konto verfügbar',
                          subtitle: 'Füge zuerst ein WebUntis-Konto hinzu.',
                          trailing: null,
                        ),
                      ]
                    : [
                        for (final account in accounts)
                          SettingsTile(
                            icon: account.id == _accountId
                                ? Icons.check_circle_rounded
                                : Icons.account_circle_outlined,
                            iconBackgroundColor: account.id == _accountId
                                ? cs.primaryContainer
                                : null,
                            iconColor: account.id == _accountId
                                ? cs.onPrimaryContainer
                                : null,
                            title: account.label,
                            subtitle: account.schoolName,
                            trailing: account.id == _accountId
                                ? const Icon(Icons.check_rounded)
                                : null,
                            onTap: () => _selectAccount(account.id),
                          ),
                      ],
              ),
            ),
            _platformInstructions(isAndroid, isIOS),
          ],
        ),
      ),
    );
  }
}
