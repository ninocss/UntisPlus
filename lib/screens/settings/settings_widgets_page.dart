part of '../../main.dart';

class SettingsWidgetsPage extends StatefulWidget {
  const SettingsWidgetsPage({super.key});

  @override
  State<SettingsWidgetsPage> createState() => _SettingsWidgetsPageState();
}

class _SettingsWidgetsPageState extends State<SettingsWidgetsPage> {
  static const _types = [
    ('current', 'Jetzt', Icons.bolt_rounded),
    ('schedule', 'Tagesplan', Icons.view_agenda_rounded),
    ('homework', 'Aufgaben', Icons.assignment_rounded),
    ('notices', 'Mitteilungen', Icons.markunread_rounded),
  ];
  String _selectedType = 'current';
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = activeUntisAccountId;
  }

  UntisAccount? get _account {
    for (final account in untisAccountsNotifier.value) {
      if (account.id == _accountId) return account;
    }
    return untisAccountsNotifier.value.isEmpty
        ? null
        : untisAccountsNotifier.value.first;
  }

  Future<void> _pinSelectedWidget() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final name = switch (_selectedType) {
      'schedule' => 'UntisWidgetDailySchedule',
      'homework' => 'UntisWidgetHomework',
      'notices' => 'UntisWidgetNotifications',
      _ => 'UntisWidgetCurrentLesson',
    };
    final supported = await WidgetService.requestPinWidget(
      name: name,
      qualifiedAndroidName: 'com.ninocss.untisplus.$name',
    );
    if (!supported || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dieses Gerät öffnet den Widget-Picker über den Homescreen.',
          ),
        ),
      );
      return;
    }
  }

  Widget _preview(BuildContext context, ColorScheme cs) {
    final account = _account;
    final headline = switch (_selectedType) {
      'schedule' => '08:00 · Mathe\n09:45 · Englisch\n11:30 · Biologie',
      'homework' => '2 offen · Mathe',
      'notices' => 'Vertretungsplan aktualisiert',
      _ => 'Mathematik',
    };
    final detail = switch (_selectedType) {
      'schedule' => 'Noch 2 Stunden',
      'homework' => 'Morgen fällig',
      'notices' => 'Eine neue Mitteilung',
      _ => 'Raum 204 · bis 10:30',
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 330, minHeight: 180),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(42),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(42),
        ),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.16),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  account?.label ?? 'Untis+',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 19),
            ],
          ),
          const Spacer(),
          Text(
            headline,
            maxLines: _selectedType == 'schedule' ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIOS = !kIsWeb && Platform.isIOS;
    return Scaffold(
      appBar: RoundedBlurAppBar(title: const Text('Widgets & Vorschau')),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 40),
          children: [
            Center(child: _preview(context, cs)),
            const SizedBox(height: 20),
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
                          avatar: Icon(type.$3, size: 18),
                          label: Text(type.$2),
                          selected: _selectedType == type.$1,
                          onSelected: (_) =>
                              setState(() => _selectedType = type.$1),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<List<UntisAccount>>(
              valueListenable: untisAccountsNotifier,
              builder: (context, accounts, _) => SettingsGroup(
                title: 'Konto',
                children: [
                  for (final account in accounts)
                    SettingsTile(
                      icon: account.id == _accountId
                          ? Icons.check_circle_rounded
                          : Icons.account_circle_outlined,
                      title: account.label,
                      subtitle: account.schoolName,
                      trailing: account.id == _accountId
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => setState(() => _accountId = account.id),
                    ),
                ],
              ),
            ),
            SettingsGroup(
              title: 'Zum Homescreen',
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: FilledButton.icon(
                    onPressed: isAndroid ? _pinSelectedWidget : null,
                    icon: const Icon(Icons.add_to_home_screen_rounded),
                    label: Text(
                      isIOS
                          ? 'Im iOS-Widget-Picker hinzufügen'
                          : 'Widget hinzufügen',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Beim Hinzufügen legst du das Konto für diese Widget-Instanz fest.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
