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
      label: 'widgetCurrent',
      icon: Icons.bolt_rounded,
      description: 'widgetCurrentDesc',
      size: 'widgetSmallMedium',
    ),
    (
      id: 'schedule',
      label: 'widgetSchedule',
      icon: Icons.view_agenda_rounded,
      description: 'widgetScheduleDesc',
      size: 'widgetMediumLarge',
    ),
    (
      id: 'homework',
      label: 'widgetHomework',
      icon: Icons.assignment_rounded,
      description: 'widgetHomeworkDesc',
      size: 'widgetSmallMedium',
    ),
    (
      id: 'notices',
      label: 'widgetNotices',
      icon: Icons.markunread_rounded,
      description: 'widgetNoticesDesc',
      size: 'widgetSmallMedium',
    ),
  ];

  String _selectedType = 'current';
  String? _accountId;
  WidgetPreviewData _previewData = const WidgetPreviewData();
  bool _loadingPreview = true;
  bool _pinning = false;

  String _typeText(AppL10n l, String key) => switch (key) {
    'widgetCurrent' => l.widgetCurrent,
    'widgetCurrentDesc' => l.widgetCurrentDesc,
    'widgetSchedule' => l.widgetSchedule,
    'widgetScheduleDesc' => l.widgetScheduleDesc,
    'widgetHomework' => l.widgetHomework,
    'widgetHomeworkDesc' => l.widgetHomeworkDesc,
    'widgetNotices' => l.widgetNotices,
    'widgetNoticesDesc' => l.widgetNoticesDesc,
    'widgetSmallMedium' => l.widgetSmallMedium,
    'widgetMediumLarge' => l.widgetMediumLarge,
    _ => key,
  };

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
    final l = appL10nFor(appLocaleNotifier.value);
    if (kIsWeb || !Platform.isAndroid || _pinning) return;
    final accountId = _accountId;
    if (accountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.widgetAddAccountFirst)));
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
            supported ? l.widgetPickerSent : l.widgetPickerHint,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.widgetPickerFailed)));
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
    final l = appL10nFor(appLocaleNotifier.value);
    final account = _account;
    final data = _previewData;
    final hasData = data.hasPublishedData;
    final accountLabel = data.accountLabel.trim().isNotEmpty
        ? data.accountLabel.trim()
        : account?.label ?? 'Untis+';
    final status = _loadingPreview
        ? l.widgetLoading
        : data.status.trim().isNotEmpty
        ? data.status.trim()
        : hasData
        ? l.widgetCurrentStatus
        : l.widgetPreviewStatus;
    final isCurrent = _selectedType == 'current';
    final isSchedule = _selectedType == 'schedule';
    final title = switch (_selectedType) {
      'schedule' => l.widgetToday,
      'homework' => l.widgetHomework,
      'notices' => l.widgetNotices,
      _ => accountLabel,
    };
    final headline = switch (_selectedType) {
      'schedule' =>
        data.dailySchedule.trim().isNotEmpty
            ? data.dailySchedule.trim()
            : l.widgetNoScheduleData,
      'homework' =>
        data.homeworkSummary.trim().isNotEmpty
            ? data.homeworkSummary.trim()
            : l.widgetNoOpenHomework,
      'notices' =>
        data.notificationSummary.trim().isNotEmpty
            ? data.notificationSummary.trim()
            : l.widgetNoNotices,
      _ =>
        data.currentLesson.trim().isNotEmpty
            ? data.currentLesson.trim()
            : l.widgetNoCurrentLesson,
    };
    final detail = data.nextLesson.trim().isNotEmpty
        ? data.nextLesson.trim()
        : l.widgetTimetableDetail;
    final footer = data.timeRemaining.trim().isNotEmpty
        ? data.timeRemaining.trim()
        : hasData
        ? 'Untis+'
        : l.widgetNotSynced;

    Widget statusPill(String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    TextStyle? widgetTextStyle({
      required double size,
      required Color color,
      required FontWeight weight,
      double height = 1.2,
    }) => Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );

    return Semantics(
      label:
          '${l.widgetPreview}: ${_typeText(l, _types.firstWhere((type) => type.id == _selectedType).label)}',
      child: AnimatedContainer(
        key: ValueKey('widget-preview-$_selectedType'),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 220,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: cs.outlineVariant),
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
                    style: widgetTextStyle(
                      size: 12,
                      color: isCurrent ? cs.onSurfaceVariant : cs.primary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrent)
                  statusPill(status)
                else
                  Flexible(
                    child: Text(
                      accountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: widgetTextStyle(
                        size: 12,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isCurrent ? 12 : 14),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
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
                        maxLines: isSchedule ? 3 : isCurrent ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: widgetTextStyle(
                          size: isCurrent ? 24 : isSchedule ? 15 : 17,
                          color: cs.onSurface,
                          weight: isSchedule ? FontWeight.w500 : FontWeight.w700,
                          height: isCurrent ? 1.15 : 1.3,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 5),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: widgetTextStyle(
                            size: 13,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isCurrent)
                  Flexible(child: statusPill(footer))
                else
                  statusPill(status),
                const Spacer(),
                if (isCurrent)
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
    final l = appL10nFor(appLocaleNotifier.value);
    if (isAndroid) {
      return SettingsGroup(
        title: l.widgetHome,
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
                  _pinning ? l.widgetPickerOpening : l.widgetAdd,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(l.widgetAndroidDialogDesc),
          ),
        ],
      );
    }
    if (isIOS) {
      return SettingsGroup(
        title: l.widgetHome,
        children: [
          SettingsTile(
            icon: Icons.looks_one_rounded,
            title: l.widgetHoldHome,
            subtitle: l.widgetHoldHomeDesc,
            trailing: null,
          ),
          SettingsTile(
            icon: Icons.looks_two_rounded,
            title: l.widgetSelectUntis,
            subtitle: l.widgetSelectUntisDesc,
            trailing: null,
          ),
          SettingsTile(
            icon: Icons.looks_3_rounded,
            title: l.widgetSetAccount,
            subtitle: l.widgetSetAccountDesc,
            trailing: null,
          ),
        ],
      );
    }
    return SettingsGroup(
      title: l.widgetHome,
      children: [
        SettingsTile(
          icon: Icons.devices_other_rounded,
          title: l.widgetHomeUnavailable,
          subtitle: l.widgetHomeSupported,
          trailing: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIOS = !kIsWeb && Platform.isIOS;
    final selected = _types.firstWhere((type) => type.id == _selectedType);
    return Scaffold(
      appBar: _settingsHeaderAppBar(
        context,
        l.widgetPreviewTitle,
        actions: [
          IconButton(
            tooltip: l.widgetRefresh,
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
                      l.widgetPreview,
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
                    ? l.widgetSyncedPreview
                    : l.widgetOpenTimetable,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            SettingsGroup(
              title: l.widgetOwn,
              children: [
                SettingsTile(
                  icon: Icons.dashboard_customize_rounded,
                  title: l.widgetEditorOpen,
                  subtitle: l.widgetEditorDesc,
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).push(_buildBouncyRoute(const CustomWidgetEditorPage())),
                ),
              ],
            ),
            SettingsGroup(
              title: l.widgetChoose,
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
                          label: Text(_typeText(l, type.label)),
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
                              _typeText(l, selected.description),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _typeText(l, selected.size),
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
                title: l.widgetAccount,
                children: accounts.isEmpty
                    ? [
                        SettingsTile(
                          icon: Icons.person_off_outlined,
                          title: l.widgetNoAccount,
                          subtitle: l.widgetAddAccountFirst,
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
