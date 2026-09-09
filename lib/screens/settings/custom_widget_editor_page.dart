part of '../../main.dart';

class CustomWidgetEditorPage extends StatefulWidget {
  const CustomWidgetEditorPage({super.key});

  @override
  State<CustomWidgetEditorPage> createState() => _CustomWidgetEditorPageState();
}

class _CustomWidgetEditorPageState extends State<CustomWidgetEditorPage> {
  static const _blocks = <String, (String, IconData)>{
    'current': ('Aktuelle Stunde', Icons.play_circle_fill_rounded),
    'next': ('Nächste Stunde', Icons.skip_next_rounded),
    'schedule': ('Tagesplan', Icons.view_agenda_rounded),
    'homework': ('Aufgaben', Icons.assignment_rounded),
    'exams': ('Prüfungen', Icons.event_note_rounded),
    'notices': ('Mitteilungen', Icons.markunread_rounded),
    'account': ('Konto', Icons.account_circle_rounded),
    'status': ('Status', Icons.schedule_rounded),
  };

  List<WidgetConfiguration> _configurations = const [];
  String? _selectedId;
  bool _loading = true;
  bool _pinning = false;

  @override
  void initState() {
    super.initState();
    untisAccountsNotifier.addListener(_onAccountsChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    untisAccountsNotifier.removeListener(_onAccountsChanged);
    super.dispose();
  }

  WidgetConfiguration get _selected => _configurations.firstWhere(
    (item) => item.id == _selectedId,
    orElse: () => _configurations.first,
  );

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(WidgetService.configurationsKey);
    final loaded = <WidgetConfiguration>[];
    try {
      final json = jsonDecode(raw ?? '[]');
      if (json is List) {
        for (final value in json.whereType<Map>()) {
          final config = WidgetConfiguration.fromJson(
            Map<String, dynamic>.from(value),
          );
          if (config.id.isNotEmpty) loaded.add(config);
        }
      }
    } catch (_) {}
    if (loaded.isEmpty) {
      loaded.add(_newConfiguration(name: 'Mein Widget'));
    }
    if (!mounted) return;
    setState(() {
      _configurations = loaded;
      _selectedId = loaded.first.id;
      _loading = false;
    });
    unawaited(_persist());
  }

  WidgetConfiguration _newConfiguration({String? name}) => WidgetConfiguration(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    name: name ?? 'Neues Widget',
    accountId: activeUntisAccountId ?? '',
  );

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      WidgetService.configurationsKey,
      jsonEncode(_configurations.map((item) => item.toJson()).toList()),
    );
    await WidgetService.publishConfigurations(_configurations);
  }

  void _replace(WidgetConfiguration value) {
    setState(() {
      _configurations = _configurations
          .map((item) => item.id == value.id ? value : item)
          .toList(growable: false);
    });
    unawaited(_persist());
  }

  void _onAccountsChanged() {
    final ids = untisAccountsNotifier.value
        .map((account) => account.id)
        .toSet();
    final kept = _configurations
        .where((item) => item.accountId.isEmpty || ids.contains(item.accountId))
        .toList();
    if (kept.length == _configurations.length) return;
    if (kept.isEmpty) kept.add(_newConfiguration());
    setState(() {
      _configurations = kept;
      _selectedId = kept.first.id;
    });
    unawaited(_persist());
  }

  Future<void> _pickColor({
    required int current,
    required ValueChanged<int> onChanged,
  }) async {
    var color = Color(current);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              for (final channel in <String>['Rot', 'Grün', 'Blau'])
                Row(
                  children: [
                    SizedBox(width: 42, child: Text(channel)),
                    Expanded(
                      child: Slider(
                        value: channel == 'Rot'
                            ? color.r * 255
                            : channel == 'Grün'
                            ? color.g * 255
                            : color.b * 255,
                        min: 0,
                        max: 255,
                        onChanged: (value) => setSheetState(() {
                          color = Color.fromARGB(
                            255,
                            channel == 'Rot'
                                ? value.round()
                                : (color.r * 255).round(),
                            channel == 'Grün'
                                ? value.round()
                                : (color.g * 255).round(),
                            channel == 'Blau'
                                ? value.round()
                                : (color.b * 255).round(),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              FilledButton(
                onPressed: () {
                  onChanged(color.toARGB32());
                  Navigator.pop(context);
                },
                child: const Text('Farbe übernehmen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _content(WidgetConfiguration config, String block) {
    switch (block) {
      case 'current':
        return 'Jetzt: Mathematik';
      case 'next':
        return 'Danach: Englisch · Raum 204';
      case 'schedule':
        return '08:00 Mathe\n09:45 Englisch\n11:30 Biologie';
      case 'homework':
        return '2 offene Aufgaben';
      case 'exams':
        return 'Nächste Prüfung: Freitag';
      case 'notices':
        return 'Neue Mitteilungen';
      case 'account':
        return untisAccountsNotifier.value
                .where((item) => item.id == config.accountId)
                .firstOrNull
                ?.label ??
            'Untis+';
      case 'status':
        return 'Aktualisiert um 12:30';
      default:
        return '';
    }
  }

  Widget _preview(WidgetConfiguration config) {
    final cs = Theme.of(context).colorScheme;
    final background = Color(
      config.backgroundColor,
    ).withValues(alpha: config.opacity);
    return Container(
      constraints: const BoxConstraints(maxWidth: 370),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(config.cornerRadius),
        border: Border.all(
          color: Color(config.accentColor).withValues(alpha: .55),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: config.blocks
            .map(
              (block) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (config.showIcons) ...[
                      Icon(
                        _blocks[block]?.$2 ?? Icons.widgets_rounded,
                        color: Color(config.accentColor),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _content(config, block),
                        maxLines: block == 'schedule' ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Color(config.textColor),
                          fontSize: 14 * config.textScale,
                          fontWeight: block == 'current'
                              ? FontWeight.w900
                              : FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _pin() async {
    if (kIsWeb || !Platform.isAndroid || _pinning) return;
    setState(() => _pinning = true);
    final ok = await WidgetService.requestPinCustomWidget(
      configurationId: _selected.id,
    );
    if (mounted) {
      setState(() => _pinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Widget-Picker geöffnet.'
                : 'Öffne den Widget-Picker über den Homescreen.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final config = _selected;
    return Scaffold(
      appBar: RoundedBlurAppBar(title: const Text('Widget-Editor')),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
          children: [
            Center(child: _preview(config)),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'Deine Widgets',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._configurations.map(
                        (item) => ChoiceChip(
                          label: Text(item.name),
                          selected: item.id == config.id,
                          onSelected: (_) =>
                              setState(() => _selectedId = item.id),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add_rounded),
                        label: const Text('Neu'),
                        onPressed: () {
                          final value = _newConfiguration();
                          setState(() {
                            _configurations = [..._configurations, value];
                            _selectedId = value.id;
                          });
                          unawaited(_persist());
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.copy_rounded),
                        label: const Text('Duplizieren'),
                        onPressed: () {
                          final value = WidgetConfiguration.fromJson(
                            config.toJson(),
                          ).copyWith(name: '${config.name} Kopie');
                          final copy = WidgetConfiguration(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            name: value.name,
                            accountId: value.accountId,
                            layout: value.layout,
                            blocks: value.blocks,
                            backgroundColor: value.backgroundColor,
                            accentColor: value.accentColor,
                            textColor: value.textColor,
                            opacity: value.opacity,
                            cornerRadius: value.cornerRadius,
                            textScale: value.textScale,
                            showIcons: value.showIcons,
                          );
                          setState(() {
                            _configurations = [..._configurations, copy];
                            _selectedId = copy.id;
                          });
                          unawaited(_persist());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Inhalt und Layout',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    initialValue: config.name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onFieldSubmitted: (value) => _replace(
                      config.copyWith(
                        name: value.trim().isEmpty ? config.name : value.trim(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: ['compact', 'stacked', 'timeline']
                        .map(
                          (layout) => ChoiceChip(
                            label: Text(
                              layout == 'compact'
                                  ? 'Kompakt'
                                  : layout == 'stacked'
                                  ? 'Gestapelt'
                                  : 'Zeitachse',
                            ),
                            selected: config.layout == layout,
                            onSelected: (_) =>
                                _replace(config.copyWith(layout: layout)),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _blocks.entries.map((entry) {
                      final active = config.blocks.contains(entry.key);
                      return FilterChip(
                        avatar: Icon(entry.value.$2, size: 17),
                        label: Text(entry.value.$1),
                        selected: active,
                        onSelected: (selected) {
                          final blocks = [...config.blocks];
                          if (selected &&
                              blocks.length < WidgetConfiguration.maxBlocks)
                            blocks.add(entry.key);
                          if (!selected) blocks.remove(entry.key);
                          if (blocks.isNotEmpty)
                            _replace(config.copyWith(blocks: blocks));
                        },
                      );
                    }).toList(),
                  ),
                ),
                ...config.blocks.asMap().entries.map(
                  (entry) => ListTile(
                    leading: Icon(_blocks[entry.value]?.$2),
                    title: Text(_blocks[entry.value]?.$1 ?? entry.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          onPressed: entry.key == 0
                              ? null
                              : () {
                                  final blocks = [...config.blocks];
                                  final item = blocks.removeAt(entry.key);
                                  blocks.insert(entry.key - 1, item);
                                  _replace(config.copyWith(blocks: blocks));
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          onPressed: entry.key == config.blocks.length - 1
                              ? null
                              : () {
                                  final blocks = [...config.blocks];
                                  final item = blocks.removeAt(entry.key);
                                  blocks.insert(entry.key + 1, item);
                                  _replace(config.copyWith(blocks: blocks));
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Design',
              children: [
                for (final item in <(String, int, ValueChanged<int>)>[
                  (
                    'Hintergrund',
                    config.backgroundColor,
                    (value) =>
                        _replace(config.copyWith(backgroundColor: value)),
                  ),
                  (
                    'Akzent',
                    config.accentColor,
                    (value) => _replace(config.copyWith(accentColor: value)),
                  ),
                  (
                    'Text',
                    config.textColor,
                    (value) => _replace(config.copyWith(textColor: value)),
                  ),
                ])
                  ListTile(
                    title: Text(item.$1),
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(item.$2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    trailing: const Icon(Icons.colorize_rounded),
                    onTap: () =>
                        _pickColor(current: item.$2, onChanged: item.$3),
                  ),
                SwitchListTile(
                  value: config.showIcons,
                  title: const Text('Icons anzeigen'),
                  onChanged: (value) =>
                      _replace(config.copyWith(showIcons: value)),
                ),
                ListTile(
                  title: Text(
                    'Transparenz ${(config.opacity * 100).round()} %',
                  ),
                  subtitle: Slider(
                    value: config.opacity,
                    min: .35,
                    max: 1,
                    onChanged: (value) =>
                        _replace(config.copyWith(opacity: value)),
                  ),
                ),
                ListTile(
                  title: Text('Rundung ${config.cornerRadius.round()}'),
                  subtitle: Slider(
                    value: config.cornerRadius,
                    min: 0,
                    max: 40,
                    onChanged: (value) =>
                        _replace(config.copyWith(cornerRadius: value)),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Schriftgröße ${(config.textScale * 100).round()} %',
                  ),
                  subtitle: Slider(
                    value: config.textScale,
                    min: .75,
                    max: 1.35,
                    onChanged: (value) =>
                        _replace(config.copyWith(textScale: value)),
                  ),
                ),
              ],
            ),
            if (!kIsWeb && Platform.isAndroid)
              FilledButton.icon(
                onPressed: _pinning ? null : _pin,
                icon: _pinning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_to_home_screen_rounded),
                label: const Text('Dieses Widget hinzufügen'),
              ),
            if (!kIsWeb && Platform.isIOS)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Füge Untis+ über den iOS-Widget-Picker hinzu und wähle anschließend dieses Profil in „Widget bearbeiten“.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
