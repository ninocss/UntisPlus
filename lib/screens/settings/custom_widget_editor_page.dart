part of '../../main.dart';

class CustomWidgetEditorPage extends StatefulWidget {
  const CustomWidgetEditorPage({super.key});

  @override
  State<CustomWidgetEditorPage> createState() => _CustomWidgetEditorPageState();
}

class _CustomWidgetEditorPageState extends State<CustomWidgetEditorPage> {
  static const _blocks = <String, (String, IconData)>{
    'current': ('blockCurrent', Icons.play_circle_fill_rounded),
    'next': ('blockNext', Icons.skip_next_rounded),
    'schedule': ('blockSchedule', Icons.view_agenda_rounded),
    'homework': ('blockHomework', Icons.assignment_rounded),
    'exams': ('blockExams', Icons.event_note_rounded),
    'notices': ('blockNotices', Icons.markunread_rounded),
    'account': ('blockAccount', Icons.account_circle_rounded),
    'status': ('blockStatus', Icons.schedule_rounded),
  };

  List<WidgetConfiguration> _configurations = const [];
  String? _selectedId;
  bool _loading = true;
  bool _pinning = false;
  int _toolIndex = 1;
  double _previewScale = 1.0;
  final List<WidgetConfiguration> _history = [];
  int _historyIndex = -1;

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
      loaded.add(
        _newConfiguration(
          name: AppL10n.of(appLocaleNotifier.value).ui('editorDefaultName'),
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _configurations = loaded;
      _selectedId = loaded.first.id;
      _loading = false;
      _history
        ..clear()
        ..add(loaded.first);
      _historyIndex = 0;
    });
    unawaited(_persist());
  }

  WidgetConfiguration _newConfiguration({String? name}) => WidgetConfiguration(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    name: name ?? AppL10n.of(appLocaleNotifier.value).ui('editorNewWidget'),
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

  void _replace(WidgetConfiguration value, {bool recordHistory = true}) {
    if (recordHistory && _historyIndex >= 0) {
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      final current = _selected;
      if (jsonEncode(current.toJson()) != jsonEncode(value.toJson())) {
        _history.add(value);
        if (_history.length > 40) _history.removeAt(0);
        _historyIndex = _history.length - 1;
      }
    }
    setState(() {
      _configurations = _configurations
          .map((item) => item.id == value.id ? value : item)
          .toList(growable: false);
    });
    unawaited(_persist());
  }

  void _selectConfiguration(String id) {
    final selected = _configurations.firstWhere((item) => item.id == id);
    setState(() {
      _selectedId = id;
      _history
        ..clear()
        ..add(selected);
      _historyIndex = 0;
    });
  }

  void _undo() {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    _replace(_history[_historyIndex], recordHistory: false);
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) return;
    _historyIndex++;
    _replace(_history[_historyIndex], recordHistory: false);
  }

  void _resetDesign() {
    final current = _selected;
    final defaults = WidgetConfiguration(
      id: current.id,
      name: current.name,
      accountId: current.accountId,
      layout: current.layout,
      blocks: current.blocks,
      colorMode: 'system',
      opacity: 0.94,
      cornerRadius: 24,
      textScale: 1,
      showIcons: true,
    );
    _replace(defaults);
  }

  void _randomizeDesign() {
    final current = _selected;
    final presets = <WidgetConfiguration>[
      current.copyWith(
        colorMode: 'system',
        opacity: 0.96,
        cornerRadius: 28,
        textScale: 1.0,
        showIcons: true,
      ),
      current.copyWith(
        colorMode: 'custom',
        backgroundColor: 0xFF111827,
        accentColor: 0xFF7DD3FC,
        textColor: 0xFFF8FAFC,
        opacity: 0.96,
        cornerRadius: 30,
        textScale: 1.05,
        showIcons: true,
      ),
      current.copyWith(
        colorMode: 'custom',
        backgroundColor: 0xFFF7F3FF,
        accentColor: 0xFF6750A4,
        textColor: 0xFF1D192B,
        opacity: 0.98,
        cornerRadius: 22,
        textScale: 0.95,
        showIcons: false,
      ),
    ];
    final index = DateTime.now().millisecond % presets.length;
    _replace(presets[index]);
  }

  void _applyStylePreset(int index) {
    final current = _selected;
    final next = switch (index) {
      0 => current.copyWith(
          colorMode: 'system',
          opacity: 0.96,
          cornerRadius: 28,
          textScale: 1,
          showIcons: true,
        ),
      1 => current.copyWith(
          colorMode: 'custom',
          backgroundColor: 0xFF101828,
          accentColor: 0xFF84CAFF,
          textColor: 0xFFF5F7FA,
          opacity: 0.97,
          cornerRadius: 24,
          textScale: 1,
          showIcons: true,
        ),
      _ => current.copyWith(
          colorMode: 'custom',
          backgroundColor: 0xFFFDF8F3,
          accentColor: 0xFF8D4A3B,
          textColor: 0xFF2A1914,
          opacity: 1,
          cornerRadius: 32,
          textScale: 1.05,
          showIcons: false,
        ),
    };
    _replace(next);
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
    final l = AppL10n.of(appLocaleNotifier.value);
    var color = Color(current);
    await showUntisModalBottomSheet<void>(
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
              for (final channel in <String>[
                'colorRed',
                'colorGreen',
                'colorBlue',
              ])
                Row(
                  children: [
                    SizedBox(width: 42, child: Text(l.ui(channel))),
                    Expanded(
                      child: Slider(
                        value: channel == 'colorRed'
                            ? color.r * 255
                            : channel == 'colorGreen'
                            ? color.g * 255
                            : color.b * 255,
                        min: 0,
                        max: 255,
                        onChanged: (value) => setSheetState(() {
                          color = Color.fromARGB(
                            255,
                            channel == 'colorRed'
                                ? value.round()
                                : (color.r * 255).round(),
                            channel == 'colorGreen'
                                ? value.round()
                                : (color.g * 255).round(),
                            channel == 'colorBlue'
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
                child: Text(l.ui('editorApplyColor')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _content(WidgetConfiguration config, String block) {
    final l = AppL10n.of(appLocaleNotifier.value);
    switch (block) {
      case 'current':
        return l.ui('previewCurrent');
      case 'next':
        return l.ui('previewNext');
      case 'schedule':
        return l.ui('previewSchedule');
      case 'homework':
        return l.ui('previewHomework');
      case 'exams':
        return l.ui('previewExams');
      case 'notices':
        return l.ui('previewNotices');
      case 'account':
        return untisAccountsNotifier.value
                .where((item) => item.id == config.accountId)
                .firstOrNull
                ?.label ??
            'Untis+';
      case 'status':
        return l.ui('previewStatus');
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
            ok ? l.ui('widgetPickerSent') : l.ui('widgetPickerHint'),
          ),
        ),
      );
    }
  }

  void _createConfiguration() {
    final value = _newConfiguration();
    setState(() {
      _configurations = [..._configurations, value];
      _selectedId = value.id;
    });
    unawaited(_persist());
  }

  void _duplicateSelected(AppL10n l) {
    final config = _selected;
    final copy = WidgetConfiguration(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${config.name} ${l.ui('editorCopySuffix')}',
      accountId: config.accountId,
      layout: config.layout,
      blocks: config.blocks,
      backgroundColor: config.backgroundColor,
      accentColor: config.accentColor,
      textColor: config.textColor,
      colorMode: config.colorMode,
      opacity: config.opacity,
      cornerRadius: config.cornerRadius,
      textScale: config.textScale,
      showIcons: config.showIcons,
    );
    setState(() {
      _configurations = [..._configurations, copy];
      _selectedId = copy.id;
    });
    unawaited(_persist());
  }

  void _deleteSelected() {
    if (_configurations.length <= 1) return;
    final current = _selected.id;
    final next = _configurations.where((item) => item.id != current).toList();
    setState(() {
      _configurations = next;
      _selectedId = next.first.id;
    });
    unawaited(_persist());
  }

  Widget _editorPanel({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    Color? accent,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tone = accent ?? cs.primary;
    return ThemedSurface(
      borderRadius: BorderRadius.circular(
        _expressiveRadius(context, 24, expressiveRadius: 32),
      ),
      color: cs.surfaceContainerLow.withValues(alpha: 0.74),
      border: Border.all(color: tone.withValues(alpha: 0.16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: tone, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _valueSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String valueText,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  valueText,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _previewStage(BuildContext context, WidgetConfiguration config) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final accent = Color(config.accentColor);
    final isSystem = config.colorMode == 'system';

    return ThemedSurface(
      borderRadius: BorderRadius.circular(
        _expressiveRadius(context, 28, expressiveRadius: 38),
      ),
      color: cs.surfaceContainerLow.withValues(alpha: 0.76),
      border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.widgets_rounded,
                    color: cs.primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSystem
                            ? l.ui('widgetSystemColors')
                            : l.ui('widgetCustomColors'),
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    config.layout == 'compact'
                        ? l.ui('editorCompact')
                        : config.layout == 'timeline'
                        ? l.ui('editorTimeline')
                        : l.ui('editorStacked'),
                    style: GoogleFonts.outfit(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: _previewScale,
                      child: _preview(config),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.zoom_out_rounded, size: 18, color: cs.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: _previewScale,
                    min: 0.75,
                    max: 1.15,
                    onChanged: (value) => setState(() => _previewScale = value),
                  ),
                ),
                Icon(Icons.zoom_in_rounded, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _previewMetric(
                    icon: Icons.layers_rounded,
                    label: '${config.blocks.length}/${WidgetConfiguration.maxBlocks}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _previewMetric(
                    icon: Icons.rounded_corner_rounded,
                    label: config.cornerRadius.round().toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _previewMetric(
                    icon: Icons.text_fields_rounded,
                    label: '${(config.textScale * 100).round()}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewMetric({required IconData icon, required String label}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stylePresetButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolSelector(AppL10n l) {
    final cs = Theme.of(context).colorScheme;
    const icons = [
      Icons.dashboard_customize_rounded,
      Icons.view_quilt_rounded,
      Icons.palette_rounded,
    ];
    final labels = [
      l.ui('editorYourWidgets'),
      l.ui('editorContentLayout'),
      l.ui('editorDesign'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final selected = _toolIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _toolIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? cs.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 19,
                      color: selected
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _editorPanels(
    BuildContext context,
    WidgetConfiguration config,
    AppL10n l,
  ) {
    final cs = Theme.of(context).colorScheme;
    final accounts = untisAccountsNotifier.value;

    final panels = <Widget>[
      _editorPanel(
        context: context,
        title: l.ui('editorYourWidgets'),
        icon: Icons.dashboard_customize_rounded,
        subtitle: config.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _configurations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _configurations[index];
                  return ChoiceChip(
                    avatar: Icon(
                      item.id == config.id
                          ? Icons.check_circle_rounded
                          : Icons.widgets_rounded,
                      size: 17,
                    ),
                    label: Text(item.name),
                    selected: item.id == config.id,
                    onSelected: (_) => _selectConfiguration(item.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createConfiguration,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.ui('editorNew')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateSelected(l),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l.ui('editorDuplicate')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: l.ui('alarmDelete'),
                  onPressed: _configurations.length > 1 ? _deleteSelected : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _editorPanel(
        context: context,
        title: l.ui('editorContentLayout'),
        icon: Icons.view_quilt_rounded,
        accent: cs.tertiary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: ValueKey('widget-name-${config.id}'),
              initialValue: config.name,
              decoration: InputDecoration(
                labelText: l.ui('editorName'),
                prefixIcon: const Icon(Icons.edit_rounded),
                filled: true,
              ),
              onFieldSubmitted: (value) {
                final name = value.trim();
                if (name.isNotEmpty) _replace(config.copyWith(name: name));
              },
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: accounts.any((item) => item.id == config.accountId)
                    ? config.accountId
                    : null,
                decoration: InputDecoration(
                  labelText: l.ui('widgetAccount'),
                  prefixIcon: const Icon(Icons.account_circle_rounded),
                  filled: true,
                ),
                items: accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(
                          account.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _replace(config.copyWith(accountId: value));
                  }
                },
              ),
            ],
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'compact',
                  icon: const Icon(Icons.view_agenda_outlined),
                  label: Text(l.ui('editorCompact')),
                ),
                ButtonSegment(
                  value: 'stacked',
                  icon: const Icon(Icons.view_stream_rounded),
                  label: Text(l.ui('editorStacked')),
                ),
                ButtonSegment(
                  value: 'timeline',
                  icon: const Icon(Icons.timeline_rounded),
                  label: Text(l.ui('editorTimeline')),
                ),
              ],
              selected: {config.layout},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) {
                  _replace(config.copyWith(layout: value.first));
                }
              },
            ),
            const SizedBox(height: 14),
            Text(
              l.ui('editorContentLayout'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blocks.entries.map((entry) {
                final active = config.blocks.contains(entry.key);
                return FilterChip(
                  avatar: Icon(entry.value.$2, size: 16),
                  label: Text(l.ui(entry.value.$1)),
                  selected: active,
                  onSelected: (selected) {
                    final blocks = [...config.blocks];
                    if (selected &&
                        blocks.length < WidgetConfiguration.maxBlocks) {
                      blocks.add(entry.key);
                    } else if (!selected && blocks.length > 1) {
                      blocks.remove(entry.key);
                    }
                    _replace(config.copyWith(blocks: blocks));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            for (final entry in config.blocks.asMap().entries)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _blocks[entry.value]?.$2,
                      size: 18,
                      color: cs.tertiary,
                    ),
                  ),
                  title: Text(
                    l.ui(_blocks[entry.value]?.$1 ?? entry.value),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 19),
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
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.arrow_downward_rounded, size: 19),
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
      ),
      const SizedBox(height: 14),
      _editorPanel(
        context: context,
        title: l.ui('editorDesign'),
        icon: Icons.palette_rounded,
        accent: cs.secondary,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _stylePresetButton(
                    label: 'Material',
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => _applyStylePreset(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _stylePresetButton(
                    label: 'Night',
                    icon: Icons.dark_mode_rounded,
                    onTap: () => _applyStylePreset(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _stylePresetButton(
                    label: 'Paper',
                    icon: Icons.article_rounded,
                    onTap: () => _applyStylePreset(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'system',
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(l.ui('widgetSystemColors')),
                ),
                ButtonSegment(
                  value: 'custom',
                  icon: const Icon(Icons.color_lens_rounded),
                  label: Text(l.ui('widgetCustomColors')),
                ),
              ],
              selected: {config.colorMode},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) {
                  _replace(config.copyWith(colorMode: value.first));
                }
              },
            ),
            if (config.colorMode == 'custom') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final item in <(String, int, ValueChanged<int>)>[
                    (
                      'editorBackground',
                      config.backgroundColor,
                      (value) => _replace(config.copyWith(backgroundColor: value)),
                    ),
                    (
                      'editorAccent',
                      config.accentColor,
                      (value) => _replace(config.copyWith(accentColor: value)),
                    ),
                    (
                      'editorText',
                      config.textColor,
                      (value) => _replace(config.copyWith(textColor: value)),
                    ),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              _pickColor(current: item.$2, onChanged: item.$3),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.52,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Color(item.$2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  l.ui(item.$1),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: config.showIcons,
              title: Text(
                l.ui('editorShowIcons'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              onChanged: (value) =>
                  _replace(config.copyWith(showIcons: value)),
            ),
            _valueSlider(
              label: l.ui('editorTransparency'),
              value: config.opacity,
              min: .35,
              max: 1,
              valueText: '${(config.opacity * 100).round()}%',
              onChanged: (value) =>
                  _replace(config.copyWith(opacity: value)),
            ),
            _valueSlider(
              label: l.ui('editorRounding'),
              value: config.cornerRadius,
              min: 0,
              max: 40,
              valueText: config.cornerRadius.round().toString(),
              onChanged: (value) =>
                  _replace(config.copyWith(cornerRadius: value)),
            ),
            _valueSlider(
              label: l.ui('editorFontSize'),
              value: config.textScale,
              min: .75,
              max: 1.35,
              valueText: '${(config.textScale * 100).round()}%',
              onChanged: (value) =>
                  _replace(config.copyWith(textScale: value)),
            ),
          ],
        ),
      ),
    ];
    return [
      _toolSelector(l),
      const SizedBox(height: 14),
      panels[_toolIndex.clamp(0, panels.length - 1)],
      if (!kIsWeb && Platform.isAndroid) ...[
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
          onPressed: _pinning ? null : _pin,
          icon: _pinning
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_to_home_screen_rounded),
          label: Text(
            l.ui('editorAddWidget'),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
        ),
      ],
      if (!kIsWeb && Platform.isIOS) ...[
        const SizedBox(height: 14),
        _editorPanel(
          context: context,
          title: l.ui('editorAddWidget'),
          icon: Icons.ios_share_rounded,
          child: Text(
            l.ui('editorIosHint'),
            style: GoogleFonts.outfit(color: cs.onSurfaceVariant),
          ),
        ),
      ]
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return Scaffold(
        appBar: RoundedBlurAppBar(title: Text(l.ui('editor'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final config = _selected;
    return Scaffold(
      appBar: RoundedBlurAppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.widgets_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 9),
            Text(
              l.ui('editor'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _historyIndex > 0 ? _undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _historyIndex < _history.length - 1 ? _redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: 'Randomize',
            onPressed: _randomizeDesign,
            icon: const Icon(Icons.casino_rounded),
          ),
          _untisDropdownMenu(
            context: context,
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.add_rounded),
                onPressed: _createConfiguration,
                child: Text(l.ui('editorNew')),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.copy_rounded),
                onPressed: () => _duplicateSelected(l),
                child: Text(l.ui('editorDuplicate')),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.restart_alt_rounded),
                onPressed: _resetDesign,
                child: const Text('Reset design'),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ],
      ),
      body: _AnimatedBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;

            if (wide) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _previewStage(context, config),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 6,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: _editorPanels(context, config, l),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                MediaQuery.paddingOf(context).bottom + 36,
              ),
              children: [
                SizedBox(
                  height: 470,
                  child: _previewStage(context, config),
                ),
                const SizedBox(height: 16),
                ..._editorPanels(context, config, l),
              ],
            );
          },
        ),
      ),
    );
  }
}
