part of '../main.dart';

class CustomBackgroundEditorScreen extends StatefulWidget {
  const CustomBackgroundEditorScreen({super.key});

  @override
  State<CustomBackgroundEditorScreen> createState() =>
      _CustomBackgroundEditorScreenState();
}

class _CustomBackgroundEditorScreenState
    extends State<CustomBackgroundEditorScreen>
    with TickerProviderStateMixin {
  late CustomBackgroundSpec _draft;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _aiCtrl;
  late final TabController _tabController;
  late final AnimationController _previewCtrl;
  late final ScrollController _scrollController;

  final GlobalKey _previewSectionKey = GlobalKey();
  final GlobalKey _editSectionKey = GlobalKey();
  final GlobalKey _librarySectionKey = GlobalKey();

  final List<CustomBackgroundSpec> _history = [];
  int _historyIndex = -1;
  String _savedSnapshot = '';
  Offset _previewParallax = Offset.zero;

  bool _saving = false;
  bool _aiBusy = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _draft =
        _activeCustomBackgroundOrNull() ??
        CustomBackgroundSpec.defaults(name: 'Theme Aura');
    _nameCtrl = TextEditingController(text: _draft.name);
    _aiCtrl = TextEditingController();
    _savedSnapshot = jsonEncode(_draft.toJson());
    _history.add(_draft);
    _historyIndex = 0;
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _previewCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    customBackgroundsNotifier.addListener(_syncFromActive);
    selectedCustomBackgroundIdNotifier.addListener(_syncFromActive);
  }

  @override
  void dispose() {
    customBackgroundsNotifier.removeListener(_syncFromActive);
    selectedCustomBackgroundIdNotifier.removeListener(_syncFromActive);
    _tabController.dispose();
    _scrollController.dispose();
    _previewCtrl.dispose();
    _nameCtrl.dispose();
    _aiCtrl.dispose();
    super.dispose();
  }

  void _syncFromActive() {
    final active = _activeCustomBackgroundOrNull();
    if (active == null) return;
    if (_draft.id == active.id) return;
    if (!mounted) return;
    setState(() {
      _draft = active;
      _nameCtrl.text = active.name;
      _savedSnapshot = jsonEncode(active.toJson());
      _isDirty = false;
      _history
        ..clear()
        ..add(active);
      _historyIndex = 0;
    });
  }

  void _markDirty() {
    final dirty = jsonEncode(_draft.toJson()) != _savedSnapshot;
    if (dirty == _isDirty) return;
    setState(() => _isDirty = dirty);
  }

  void _pushHistory(CustomBackgroundSpec state) {
    if (_historyIndex >= 0 &&
        _historyIndex < _history.length &&
        jsonEncode(_history[_historyIndex].toJson()) ==
            jsonEncode(state.toJson())) {
      return;
    }
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(state);
    if (_history.length > 30) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
      return;
    }
    _historyIndex = _history.length - 1;
  }

  void _replaceDraft(CustomBackgroundSpec next, {bool syncName = false}) {
    setState(() {
      _draft = next;
      if (syncName) {
        _nameCtrl.text = next.name;
      }
    });
    _markDirty();
  }

  void _updateDraft(CustomBackgroundSpec next) {
    _pushHistory(next);
    _replaceDraft(next);
  }

  void _commitDraft(CustomBackgroundSpec next) {
    setState(() {
      _draft = next;
      _nameCtrl.text = next.name;
      _savedSnapshot = jsonEncode(next.toJson());
      _isDirty = false;
      _history
        ..clear()
        ..add(next);
      _historyIndex = 0;
    });
  }

  Future<void> _applyPreset(CustomBackgroundPreset preset) async {
    if (!await _confirmDiscardIfNeeded()) return;
    final spec = preset.create(name: preset.label);
    await upsertCustomBackground(spec);
    if (!mounted) return;
    _commitDraft(spec);
    _tabController.animateTo(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToSection(_editSectionKey);
      }
    });
  }

  // ignore: unused_element
  String _gradientSummary(CustomBackgroundGradient base) {
    final mode = base.type == CustomBackgroundGradientType.radial
        ? 'radial'
        : 'linear';
    final opacity = '${(base.opacity * 100).round()}%';
    final palette = base.useThemeColors
        ? 'Theme'
        : '${base.colors.length} colors';
    return '$mode · $opacity · $palette';
  }

  // ignore: unused_element
  String _orbsSummary(CustomBackgroundOrbs orbs) {
    if (!orbs.enabled) return 'off';
    final palette = orbs.useThemeColors
        ? 'Theme'
        : '${orbs.colors.length} colors';
    return '${orbs.count} orbs · $palette';
  }

  // ignore: unused_element
  String _patternSummary(CustomBackgroundPattern pattern) {
    if (pattern.type == CustomBackgroundPatternType.none) return 'none';
    return '${pattern.type.name} · ${(pattern.opacity * 100).round()}%';
  }

  // ignore: unused_element
  String _motionSummary() {
    final animate = _draft.animate ? 'anim' : 'static';
    return '$animate · ${_draft.animationSpeed.toStringAsFixed(1)}x';
  }

  // ignore: unused_element
  Color _sectionAccentFor(String key, ColorScheme cs) {
    switch (key) {
      case 'base':
        return cs.primary;
      case 'orbs':
        return cs.tertiary;
      case 'pattern':
        return cs.secondary;
      case 'effects':
        return cs.error;
      case 'motion':
        return cs.primaryContainer;
      case 'ai':
        return cs.tertiaryContainer;
      default:
        return cs.primary;
    }
  }

  // ignore: unused_element
  Widget _expressiveSectionCard({
    required ColorScheme cs,
    required Color accent,
    required String title,
    required String status,
    required IconData icon,
    required Widget child,
    double radius = 24,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            cs.surfaceContainerHighest.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.24), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
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
                        const SizedBox(height: 3),
                        Text(
                          status,
                          style: GoogleFonts.outfit(
                            fontSize: 12.2,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '•',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetCard(BuildContext context, CustomBackgroundPreset preset) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _applyPreset(preset),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: preset.accent.withValues(alpha: 0.35),
            width: 1.1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              preset.accent.withValues(alpha: 0.14),
              cs.surfaceContainerHighest.withValues(alpha: 0.60),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomBackgroundView(
                  spec: preset.create(name: preset.label),
                  t: _previewCtrl.value,
                  parallax: const Offset(0, 0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preset.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              preset.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.2,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStatChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      onPressed: onTap,
      label: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      avatar: Icon(icon, size: 16, color: cs.primary),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isDirty) return true;
    final l = AppL10n.of(appLocaleNotifier.value);
    final decision = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.bgEditorUnsavedTitle,
      subtitle: l.bgEditorUnsavedDesc,
      fitContentHeight: true,
      options: [
        _SheetOption(
          value: 'save',
          title: l.bgEditorSave,
          icon: Icons.save_rounded,
        ),
        _SheetOption(
          value: 'discard',
          title: l.bgEditorDiscard,
          icon: Icons.delete_forever_rounded,
          destructive: true,
        ),
        _SheetOption(
          value: 'cancel',
          title: l.settingsApiKeyCancel,
          icon: Icons.close_rounded,
        ),
      ],
    );
    if (decision == 'save') {
      await _saveDraft();
      return !_isDirty;
    }
    return decision == 'discard';
  }

  void _undoDraft() {
    if (_historyIndex <= 0) return;
    setState(() {
      _historyIndex--;
      _draft = _history[_historyIndex];
      _nameCtrl.text = _draft.name;
    });
    _markDirty();
  }

  void _redoDraft() {
    if (_historyIndex >= _history.length - 1) return;
    setState(() {
      _historyIndex++;
      _draft = _history[_historyIndex];
      _nameCtrl.text = _draft.name;
    });
    _markDirty();
  }

  CustomBackgroundSpec _randomSpec() {
    final rng = math.Random();
    final now = _nowMs();
    final palette = [
      Color.lerp(
        Colors.indigo,
        Colors.lightBlueAccent,
        rng.nextDouble(),
      )!.toARGB32(),
      Color.lerp(
        Colors.pinkAccent,
        Colors.deepOrangeAccent,
        rng.nextDouble(),
      )!.toARGB32(),
      Color.lerp(
        Colors.tealAccent,
        Colors.lightGreenAccent,
        rng.nextDouble(),
      )!.toARGB32(),
    ];
    return CustomBackgroundSpec(
      version: kCustomBackgroundSpecVersion,
      id: _newCustomBackgroundId(),
      name:
          '${AppL10n.of(appLocaleNotifier.value).bgEditorNewName} ${now % 1000}',
      createdAtMs: now,
      updatedAtMs: now,
      base: CustomBackgroundGradient(
        type: rng.nextBool()
            ? CustomBackgroundGradientType.radial
            : CustomBackgroundGradientType.linear,
        useThemeColors: rng.nextDouble() > 0.4,
        colors: palette,
        opacity: 0.18 + rng.nextDouble() * 0.28,
        angleDeg: rng.nextDouble() * 360,
        centerX: -0.6 + rng.nextDouble() * 1.2,
        centerY: -0.6 + rng.nextDouble() * 1.2,
        radius: 0.95 + rng.nextDouble() * 0.8,
      ),
      orbs: CustomBackgroundOrbs(
        enabled: rng.nextDouble() > 0.12,
        seed: rng.nextInt(1 << 31),
        count: 4 + rng.nextInt(6),
        size: 140 + rng.nextDouble() * 160,
        sizeVariance: 0.15 + rng.nextDouble() * 0.45,
        opacity: 0.12 + rng.nextDouble() * 0.28,
        softness: 0.55 + rng.nextDouble() * 0.35,
        useThemeColors: rng.nextDouble() > 0.45,
        colors: palette,
      ),
      pattern: CustomBackgroundPattern(
        type: rng.nextDouble() > 0.72
            ? CustomBackgroundPatternType.lines
            : CustomBackgroundPatternType.none,
        opacity: 0.03 + rng.nextDouble() * 0.16,
        scale: 0.9 + rng.nextDouble() * 1.0,
        angleDeg: rng.nextDouble() * 360,
      ),
      noise: 0.02 + rng.nextDouble() * 0.12,
      vignette: 0.12 + rng.nextDouble() * 0.18,
      animate: true,
      animationSpeed: 0.8 + rng.nextDouble() * 1.1,
      parallaxStrength: 0.28 + rng.nextDouble() * 0.42,
    );
  }

  Future<void> _saveDraft() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final now = _nowMs();
      final trimmedName = _nameCtrl.text.trim();
      final normalized = _draft.copyWith(
        name: trimmedName.isNotEmpty ? trimmedName : _draft.name,
        updatedAtMs: now,
      );
      await upsertCustomBackground(normalized);
      if (!mounted) return;
      _commitDraft(normalized);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(appLocaleNotifier.value).bgEditorSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(appLocaleNotifier.value).bgEditorSaveFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _applyToApp() async {
    if (_isDirty) {
      await _saveDraft();
    }
    final prefs = await SharedPreferences.getInstance();
    await selectCustomBackground(_draft.id);

    backgroundAnimationsNotifier.value = true;
    backgroundAnimationStyleNotifier.value = 10;

    await prefs.setBool('backgroundAnimations', true);
    await prefs.setInt('backgroundAnimationStyle', 10);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppL10n.of(appLocaleNotifier.value).bgEditorApplied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _newBackground() async {
    final spec = CustomBackgroundSpec.defaults(
      name: AppL10n.of(appLocaleNotifier.value).bgEditorNewName,
    );
    await upsertCustomBackground(spec);
    if (!mounted) return;
    _commitDraft(spec);
  }

  Future<void> _duplicateBackground() async {
    final duplicated = duplicateCustomBackground(_draft);
    await upsertCustomBackground(duplicated);
    if (!mounted) return;
    _commitDraft(duplicated);
  }

  Future<void> _deleteBackground() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final confirm = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.bgEditorDeleteTitle,
      subtitle: l.bgEditorDeleteDesc,
      fitContentHeight: true,
      options: [
        _SheetOption(
          value: 'delete',
          title: l.bgEditorDeleteConfirm,
          icon: Icons.delete_rounded,
          destructive: true,
        ),
        _SheetOption(
          value: 'cancel',
          title: l.settingsApiKeyCancel,
          icon: Icons.close_rounded,
        ),
      ],
    );

    if (confirm != 'delete') return;
    await deleteCustomBackground(_draft.id);
  }

  Future<void> _exportSelected() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final jsonText = exportCustomBackgroundSpecPretty(_draft);
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.bgEditorExported),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportAll() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final jsonText = exportCustomBackgroundLibraryPretty(
      customBackgroundsNotifier.value,
    );
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.bgEditorExportedAll),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _importFromClipboard() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bgEditorImportClipboardEmpty),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final count = await importCustomBackgroundsFromJsonText(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bgEditorImportedCount(count)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bgEditorImportFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importFromFile() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('No bytes');
      }

      final text = utf8.decode(bytes);
      final count = await importCustomBackgroundsFromJsonText(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bgEditorImportedCount(count)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bgEditorImportFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showImportSheet() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final selected = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.bgEditorImportTitle,
      options: [
        _SheetOption(
          value: 'clipboard',
          title: l.bgEditorImportFromClipboard,
          icon: Icons.content_paste_rounded,
        ),
        _SheetOption(
          value: 'file',
          title: l.bgEditorImportFromFile,
          icon: Icons.upload_file_rounded,
        ),
      ],
      fitContentHeight: true,
    );

    if (selected == 'clipboard') {
      await _importFromClipboard();
    } else if (selected == 'file') {
      await _importFromFile();
    }
  }

  Future<void> _showExportSheet() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final selected = await _showUnifiedOptionSheet<String>(
      context: context,
      title: l.bgEditorExportTitle,
      options: [
        _SheetOption(
          value: 'selected',
          title: l.bgEditorExportSelected,
          icon: Icons.ios_share_rounded,
        ),
        _SheetOption(
          value: 'all',
          title: l.bgEditorExportAll,
          icon: Icons.copy_all_rounded,
        ),
      ],
      fitContentHeight: true,
    );

    if (selected == 'selected') {
      await _exportSelected();
    } else if (selected == 'all') {
      await _exportAll();
    }
  }

  Future<Color?> _pickRgbColor({
    required String title,
    required Color initial,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    double red = (initial.r * 255.0).round().clamp(0, 255).toDouble();
    double green = (initial.g * 255.0).round().clamp(0, 255).toDouble();
    double blue = (initial.b * 255.0).round().clamp(0, 255).toDouble();

    return _showUnifiedSheet<Color>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final preview = Color.fromARGB(
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l.settingsColorRed}: ${red.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: red,
                  min: 0,
                  max: 255,
                  activeColor: Colors.red,
                  onChanged: (v) => setStateDialog(() => red = v),
                ),
                Text(
                  '${l.settingsColorGreen}: ${green.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: green,
                  min: 0,
                  max: 255,
                  activeColor: Colors.green,
                  onChanged: (v) => setStateDialog(() => green = v),
                ),
                Text(
                  '${l.settingsColorBlue}: ${blue.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: blue,
                  min: 0,
                  max: 255,
                  activeColor: Colors.blue,
                  onChanged: (v) => setStateDialog(() => blue = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, preview),
                      child: Text(
                        l.settingsColorApply,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<int> _ensureAtLeastNColors(List<int> colors, int n, Color fallback) {
    final out = [...colors];
    while (out.length < n) {
      out.add(fallback.toARGB32());
    }
    return out;
  }

  Future<void> _editColorInList({
    required String title,
    required List<int> colors,
    required int index,
    required void Function(List<int> updated) onChanged,
    required Color fallback,
  }) async {
    final safe = _ensureAtLeastNColors(colors, index + 1, fallback);
    final initial = Color(safe[index]);
    final picked = await _pickRgbColor(title: title, initial: initial);
    if (picked == null) return;

    safe[index] = picked.toARGB32();
    onChanged(safe);
  }

  String _providerLabelForError(AppL10n l) {
    return _providerAwareMissingApiKeyMessage(
      l,
      _normalizeAiProvider(aiProvider),
    );
  }

  bool _providerUsesGeminiProtocol() {
    final provider = _normalizeAiProvider(aiProvider);
    if (provider == 'gemini') return true;
    if (provider == 'custom') {
      return _normalizeAiCustomCompatibility(aiCustomCompatibility) == 'gemini';
    }
    return false;
  }

  String _normalizedBaseUrl(String value) {
    var out = value.trim();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  String _openAiCompatibleEndpoint(String rawBaseUrl) {
    final base = _normalizedBaseUrl(rawBaseUrl);
    if (base.isEmpty) return '';
    if (base.endsWith('/chat/completions')) return base;
    if (base.endsWith('/v1')) return '$base/chat/completions';
    if (base.endsWith('/v1/chat')) return '$base/completions';
    return '$base/v1/chat/completions';
  }

  String _geminiCompatibleEndpoint(String rawBaseUrl, String model) {
    final base = _normalizedBaseUrl(rawBaseUrl);
    if (base.isEmpty) return '';
    if (base.contains('/models/')) return base;
    if (base.contains('/v1beta')) return '$base/models/$model:generateContent';
    if (base.contains('/v1')) return '$base/models/$model:generateContent';
    return '$base/v1beta/models/$model:generateContent';
  }

  Future<String> _requestGeminiText({
    required String endpoint,
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final endpointUri = Uri.parse(endpoint);
    final mergedParams = Map<String, String>.from(endpointUri.queryParameters)
      ..putIfAbsent('key', () => apiKey);
    final uri = endpointUri.replace(queryParameters: mergedParams);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1300, 'temperature': 0.25},
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: body,
    );

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload?['error']?['message'] ?? response.statusCode;
      throw Exception('API: $message');
    }

    var reply = '';
    final candidates = payload?['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = (content is Map<String, dynamic>) ? content['parts'] : null;
      if (parts is List) {
        reply = parts
            .map((p) => (p is Map<String, dynamic>) ? p['text'] : null)
            .whereType<String>()
            .join();
      }
    }

    reply = reply.trim();
    if (reply.isEmpty) {
      throw Exception('API: ${AppL10n.of(appLocaleNotifier.value).aiNoReply}');
    }
    return reply;
  }

  String _extractOpenAiCompatibleText(Map<String, dynamic> payload, AppL10n l) {
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception('API: ${l.aiNoReply}');
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw Exception('API: ${l.aiNoReply}');
    }

    final message = first['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      if (content is List) {
        final text = content
            .map((part) {
              if (part is Map<String, dynamic>) {
                return part['text']?.toString() ?? '';
              }
              return '';
            })
            .join()
            .trim();
        if (text.isNotEmpty) return text;
      }
    }

    final legacyText = first['text']?.toString().trim() ?? '';
    if (legacyText.isNotEmpty) return legacyText;
    throw Exception('API: ${l.aiNoReply}');
  }

  Future<String> _requestOpenAiCompatibleText({
    required String endpoint,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.25,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload?['error']?['message'] ?? response.statusCode;
      throw Exception('API: $message');
    }

    return _extractOpenAiCompatibleText(payload ?? const {}, l);
  }

  Future<String> _requestAiBackgroundSpec(String prompt) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final provider = _normalizeAiProvider(aiProvider);
    final isLocalProvider = provider == 'local';
    final apiKey = _activeAiApiKey().trim();
    if (!isLocalProvider && apiKey.isEmpty) {
      throw Exception('CONFIG: ${_providerLabelForError(l)}');
    }

    final model = aiModel.trim().isNotEmpty
        ? aiModel.trim()
        : _defaultModelForProvider(
            provider,
            customCompatibility: aiCustomCompatibility,
          );

    final systemPrompt = l.bgEditorAiSystem;
    final userPrompt =
        '${l.bgEditorAiUserPrefix}\n$prompt\n\n${l.bgEditorAiUserSchemaHint}';

    switch (provider) {
      case 'openai':
        return _requestOpenAiCompatibleText(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
      case 'mistral':
        return _requestOpenAiCompatibleText(
          endpoint: 'https://api.mistral.ai/v1/chat/completions',
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
      case 'custom':
        final baseUrl = aiCustomBaseUrl.trim();
        if (baseUrl.isEmpty) {
          throw Exception('CONFIG: ${l.aiCustomBaseUrlMissing}');
        }
        if (_providerUsesGeminiProtocol()) {
          return _requestGeminiText(
            endpoint: _geminiCompatibleEndpoint(baseUrl, model),
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
          );
        }
        return _requestOpenAiCompatibleText(
          endpoint: _openAiCompatibleEndpoint(baseUrl),
          apiKey: apiKey,
          model: model,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
      case 'local':
        return _requestLocalModelText(
          systemPrompt: systemPrompt,
          userQuery: userPrompt,
          modelPath: aiLocalModelPath,
        );
      case 'gemini':
      default:
        return _requestGeminiText(
          endpoint:
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          apiKey: apiKey,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
    }
  }

  Future<void> _generateWithAi() async {
    if (_aiBusy) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    final prompt = _aiCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _aiBusy = true);
    try {
      final text = await _requestAiBackgroundSpec(prompt);
      final specs = parseCustomBackgroundSpecsFromJsonText(text);
      if (specs.isEmpty) throw Exception('No spec');

      // Always create a new background from AI.
      final now = _nowMs();
      final created = CustomBackgroundSpec(
        version: specs.first.version,
        id: _newCustomBackgroundId(),
        name: specs.first.name.isNotEmpty
            ? specs.first.name
            : l.bgEditorAiGeneratedName,
        createdAtMs: now,
        updatedAtMs: now,
        base: specs.first.base,
        orbs: specs.first.orbs,
        pattern: specs.first.pattern,
        noise: specs.first.noise,
        vignette: specs.first.vignette,
        animate: specs.first.animate,
        animationSpeed: specs.first.animationSpeed,
        parallaxStrength: specs.first.parallaxStrength,
      );

      await upsertCustomBackground(created);

      if (!mounted) return;
      _commitDraft(created);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.bgEditorAiSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      final isApiError = message.contains('API:');
      final isConfigError = message.contains('CONFIG:');
      final detail = isConfigError
          ? message.replaceFirst('Exception: CONFIG: ', '')
          : isApiError
          ? '${l.aiApiError} ${message.replaceFirst('Exception: API: ', '')}'
          : '${l.aiConnectionError} $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.bgEditorAiError}$detail'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Widget _sectionCard({
    required Widget child,
    Key? key,
    Color? accent,
    double radius = 22,
  }) {
    final cs = Theme.of(context).colorScheme;
    final effectiveAccent = accent ?? cs.surfaceContainerHighest;
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(radius),
        sigma: 20,
        color: cs.surface.withValues(alpha: 0.46),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveAccent.withValues(alpha: 0.10),
            cs.surfaceContainerHighest.withValues(alpha: 0.70),
          ],
        ),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.18),
          width: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: child,
        ),
      ),
    );
  }

  Widget _header(String title, IconData icon, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required void Function(double v) onChanged,
    String Function(double v)? valueLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    final text = valueLabel != null
        ? valueLabel(value)
        : value.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final shouldPop = await _confirmDiscardIfNeeded();
        if (!shouldPop || !mounted) {
          return;
        }
        navigator.pop(result);
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: RoundedBlurAppBar(
          title: Text(
            l.bgEditorTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: l.bgEditorUndo,
              icon: const Icon(Icons.undo_rounded),
              onPressed: _historyIndex > 0 ? _undoDraft : null,
            ),
            IconButton(
              tooltip: l.bgEditorRedo,
              icon: const Icon(Icons.redo_rounded),
              onPressed: _historyIndex < _history.length - 1
                  ? _redoDraft
                  : null,
            ),
            IconButton(
              tooltip: l.bgEditorRandomize,
              icon: const Icon(Icons.casino_rounded),
              onPressed: () async {
                final spec = _randomSpec();
                await upsertCustomBackground(spec);
                if (!mounted) return;
                _commitDraft(spec);
              },
            ),
            IconButton(
              tooltip: l.bgEditorImportTitle,
              icon: const Icon(Icons.upload_file_rounded),
              onPressed: _showImportSheet,
            ),
            PopupMenuButton<String>(
              tooltip: l.bgEditorExportTitle,
              onSelected: (value) async {
                if (value == 'export') {
                  await _showExportSheet();
                } else if (value == 'new') {
                  await _newBackground();
                } else if (value == 'duplicate') {
                  await _duplicateBackground();
                } else if (value == 'delete') {
                  await _deleteBackground();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export',
                  child: Text(l.bgEditorExportTitle),
                ),
                PopupMenuItem(value: 'new', child: Text(l.bgEditorNew)),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l.bgEditorDuplicate),
                ),
                PopupMenuItem(value: 'delete', child: Text(l.bgEditorDelete)),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            indicator: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            labelColor: cs.onPrimaryContainer,
            unselectedLabelColor: cs.onSurfaceVariant,
            onTap: (index) {
              final target = switch (index) {
                0 => _previewSectionKey,
                1 => _editSectionKey,
                _ => _librarySectionKey,
              };
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _scrollToSection(target);
                }
              });
            },
            tabs: [
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(l.bgEditorLivePreview),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(l.bgEditorMeta),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.collections_bookmark_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(l.bgEditorLibrary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: _AnimatedBackground(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              const SizedBox(width: 8),
              Text(
                l.bgEditorLibraryTab,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kBuiltInBackgroundPresets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _presetCard(context, kBuiltInBackgroundPresets[index]),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.bgEditorStartPoints,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                key: _previewSectionKey,
                accent: cs.primary,
                radius: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorLivePreview,
                      Icons.visibility_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _previewParallax = Offset(
                              (_previewParallax.dx + details.delta.dx * 0.01)
                                  .clamp(-1.0, 1.0),
                              (_previewParallax.dy + details.delta.dy * 0.01)
                                  .clamp(-1.0, 1.0),
                            );
                          });
                        },
                        onPanEnd: (_) =>
                            setState(() => _previewParallax = Offset.zero),
                        child: SizedBox(
                          height: 360,
                          width: double.infinity,
                          child: AnimatedBuilder(
                            animation: _previewCtrl,
                            builder: (context, child) {
                              return CustomBackgroundView(
                                spec: _draft,
                                t: _previewCtrl.value,
                                parallax: _previewParallax,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickStatChip(
                            label: _draft.base.type.name,
                            icon: Icons.gradient_rounded,
                            onTap: () => _scrollToSection(_editSectionKey),
                          ),
                          const SizedBox(width: 8),
                          _quickStatChip(
                            label: '${_draft.orbs.count} orbs',
                            icon: Icons.blur_circular_rounded,
                            onTap: () => _scrollToSection(_editSectionKey),
                          ),
                          const SizedBox(width: 8),
                          _quickStatChip(
                            label:
                                '${_draft.animationSpeed.toStringAsFixed(1)}x',
                            icon: Icons.motion_photos_on_rounded,
                            onTap: () => _scrollToSection(_editSectionKey),
                          ),
                          const SizedBox(width: 8),
                          _quickStatChip(
                            label: '${(_draft.noise * 100).round()}%',
                            icon: Icons.grain_rounded,
                            onTap: () => _scrollToSection(_editSectionKey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _draft.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.bgEditorUpdatedAt} ${DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(_draft.updatedAtMs))}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveDraft,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.bgEditorSave,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_isDirty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.orangeAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _applyToApp,
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(
                              l.bgEditorUseInApp,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Library
              ValueListenableBuilder(
                valueListenable: customBackgroundsNotifier,
                builder: (context, specs, _) {
                  final selectedId = selectedCustomBackgroundIdNotifier.value;
                  return _sectionCard(
                    key: _librarySectionKey,
                    accent: cs.secondary,
                    radius: 26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(
                          l.bgEditorLibrary,
                          Icons.collections_bookmark_rounded,
                          color: cs.secondary,
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: specs.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.86,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemBuilder: (ctx, idx) {
                            if (idx == 0) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: _newBackground,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: cs.secondary.withValues(
                                        alpha: 0.45,
                                      ),
                                      width: 1.2,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        cs.secondary.withValues(alpha: 0.12),
                                        cs.surfaceContainerHighest.withValues(
                                          alpha: 0.55,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: cs.secondary.withValues(
                                              alpha: 0.16,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 32,
                                            color: cs.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          l.bgEditorNew,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l.bgEditorNewName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11.5,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final s = specs[idx - 1];
                            final selected = s.id == selectedId;
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                selectCustomBackground(s.id);
                              },
                              onLongPress: () async {
                                final choice =
                                    await _showUnifiedOptionSheet<String>(
                                      context: context,
                                      title: s.name,
                                      fitContentHeight: true,
                                      options: [
                                        _SheetOption(
                                          value: 'edit',
                                          title: l.bgEditorEdit,
                                          icon: Icons.edit_rounded,
                                        ),
                                        _SheetOption(
                                          value: 'duplicate',
                                          title: l.bgEditorDuplicate,
                                          icon: Icons.copy_rounded,
                                        ),
                                        _SheetOption(
                                          value: 'export',
                                          title: l.bgEditorExportSelected,
                                          icon: Icons.ios_share_rounded,
                                        ),
                                        _SheetOption(
                                          value: 'delete',
                                          title: l.bgEditorDelete,
                                          icon: Icons.delete_rounded,
                                          destructive: true,
                                        ),
                                      ],
                                    );
                                if (choice == 'edit') {
                                  _commitDraft(s);
                                  _tabController.animateTo(1);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      _scrollToSection(_editSectionKey);
                                    }
                                  });
                                } else if (choice == 'duplicate') {
                                  final duplicated = duplicateCustomBackground(
                                    s,
                                  );
                                  await upsertCustomBackground(duplicated);
                                  if (!mounted) return;
                                  _commitDraft(duplicated);
                                } else if (choice == 'export') {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: exportCustomBackgroundSpecPretty(s),
                                    ),
                                  );
                                } else if (choice == 'delete') {
                                  await deleteCustomBackground(s.id);
                                }
                              },
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(
                                    alpha: 0.38,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: selected
                                        ? cs.primary.withValues(alpha: 0.6)
                                        : cs.outlineVariant.withValues(
                                            alpha: 0.45,
                                          ),
                                    width: selected ? 1.6 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              CustomBackgroundView(
                                                spec: s,
                                                t: selected
                                                    ? _previewCtrl.value
                                                    : 0.18,
                                                parallax: const Offset(0, 0),
                                              ),
                                              if (selected)
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: cs.primary
                                                          .withValues(
                                                            alpha: 0.85,
                                                          ),
                                                      width: 2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd.MM').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            s.updatedAtMs,
                                          ),
                                        ),
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _duplicateBackground,
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: Text(
                                  l.bgEditorDuplicate,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _deleteBackground,
                                icon: Icon(
                                  Icons.delete_rounded,
                                  size: 18,
                                  color: cs.error,
                                ),
                                label: Text(
                                  l.bgEditorDelete,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    color: cs.error,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Name
              _sectionCard(
                key: _editSectionKey,
                accent: cs.primary,
                radius: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorMeta,
                      Icons.edit_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l.bgEditorName,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      onChanged: (v) => _updateDraft(_draft.copyWith(name: v)),
                    ),
                  ],
                ),
              ),

              // Base gradient
              _sectionCard(
                accent: cs.primary,
                radius: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorBase,
                      Icons.gradient_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.bgEditorUseThemeColors,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        l.bgEditorUseThemeColorsDesc,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      value: _draft.base.useThemeColors,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        _updateDraft(
                          _draft.copyWith(
                            base: _draft.base.copyWith(useThemeColors: v),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<CustomBackgroundGradientType>(
                      segments: [
                        ButtonSegment(
                          value: CustomBackgroundGradientType.linear,
                          label: Text(l.bgEditorGradientLinear),
                          icon: const Icon(
                            Icons.linear_scale_rounded,
                            size: 18,
                          ),
                        ),
                        ButtonSegment(
                          value: CustomBackgroundGradientType.radial,
                          label: Text(l.bgEditorGradientRadial),
                          icon: const Icon(
                            Icons.radio_button_unchecked_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                      selected: {_draft.base.type},
                      onSelectionChanged: (v) {
                        if (v.isEmpty) return;
                        HapticFeedback.selectionClick();
                        _updateDraft(
                          _draft.copyWith(
                            base: _draft.base.copyWith(type: v.first),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _slider(
                      label: l.bgEditorBaseOpacity,
                      value: _draft.base.opacity,
                      min: 0.0,
                      max: 0.65,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            base: _draft.base.copyWith(opacity: v),
                          ),
                        );
                      },
                      valueLabel: (v) => '${(v * 100).round()}%',
                    ),
                    if (_draft.base.type == CustomBackgroundGradientType.linear)
                      _slider(
                        label: l.bgEditorGradientAngle,
                        value: _draft.base.angleDeg,
                        min: 0,
                        max: 360,
                        onChanged: (v) {
                          _updateDraft(
                            _draft.copyWith(
                              base: _draft.base.copyWith(angleDeg: v),
                            ),
                          );
                        },
                        valueLabel: (v) => '${v.round()}°',
                      ),
                    if (_draft.base.type ==
                        CustomBackgroundGradientType.radial) ...[
                      _slider(
                        label: l.bgEditorRadialCenterX,
                        value: _draft.base.centerX,
                        min: -1,
                        max: 1,
                        onChanged: (v) {
                          _updateDraft(
                            _draft.copyWith(
                              base: _draft.base.copyWith(centerX: v),
                            ),
                          );
                        },
                      ),
                      _slider(
                        label: l.bgEditorRadialCenterY,
                        value: _draft.base.centerY,
                        min: -1,
                        max: 1,
                        onChanged: (v) {
                          _updateDraft(
                            _draft.copyWith(
                              base: _draft.base.copyWith(centerY: v),
                            ),
                          );
                        },
                      ),
                      _slider(
                        label: l.bgEditorRadialRadius,
                        value: _draft.base.radius,
                        min: 0.4,
                        max: 2.0,
                        onChanged: (v) {
                          _updateDraft(
                            _draft.copyWith(
                              base: _draft.base.copyWith(radius: v),
                            ),
                          );
                        },
                      ),
                    ],
                    if (!_draft.base.useThemeColors) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(3, (index) {
                          final baseColors = _ensureAtLeastNColors(
                            _draft.base.colors,
                            3,
                            cs.primaryContainer,
                          );
                          final c = Color(baseColors[index]);
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _editColorInList(
                              title: l.bgEditorColorN(index + 1),
                              colors: _draft.base.colors,
                              index: index,
                              fallback: cs.primaryContainer,
                              onChanged: (updated) {
                                _updateDraft(
                                  _draft.copyWith(
                                    base: _draft.base.copyWith(
                                      colors: updated.take(4).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),

              // Orbs
              _sectionCard(
                accent: cs.tertiary,
                radius: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorOrbs,
                      Icons.blur_circular_rounded,
                      color: cs.tertiary,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.bgEditorOrbsEnabled,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      value: _draft.orbs.enabled,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        _updateDraft(
                          _draft.copyWith(
                            orbs: _draft.orbs.copyWith(enabled: v),
                          ),
                        );
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.bgEditorUseThemeColors,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        l.bgEditorOrbsThemeDesc,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      value: _draft.orbs.useThemeColors,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        _updateDraft(
                          _draft.copyWith(
                            orbs: _draft.orbs.copyWith(useThemeColors: v),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              final seed = math.Random().nextInt(1 << 31);
                              _updateDraft(
                                _draft.copyWith(
                                  orbs: _draft.orbs.copyWith(seed: seed),
                                ),
                              );
                            },
                            icon: const Icon(Icons.casino_rounded, size: 18),
                            label: Text(
                              l.bgEditorRandomizeSeed,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _slider(
                      label: l.bgEditorOrbsCount,
                      value: _draft.orbs.count.toDouble(),
                      min: 0,
                      max: 14,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            orbs: _draft.orbs.copyWith(count: v.round()),
                          ),
                        );
                      },
                      valueLabel: (v) => '${v.round()}',
                    ),
                    _slider(
                      label: l.bgEditorOrbsSize,
                      value: _draft.orbs.size,
                      min: 40,
                      max: 420,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(orbs: _draft.orbs.copyWith(size: v)),
                        );
                      },
                      valueLabel: (v) => '${v.round()}px',
                    ),
                    _slider(
                      label: l.bgEditorOrbsVariance,
                      value: _draft.orbs.sizeVariance,
                      min: 0,
                      max: 1,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            orbs: _draft.orbs.copyWith(sizeVariance: v),
                          ),
                        );
                      },
                    ),
                    _slider(
                      label: l.bgEditorOrbsOpacity,
                      value: _draft.orbs.opacity,
                      min: 0,
                      max: 0.65,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            orbs: _draft.orbs.copyWith(opacity: v),
                          ),
                        );
                      },
                      valueLabel: (v) => '${(v * 100).round()}%',
                    ),
                    _slider(
                      label: l.bgEditorOrbsSoftness,
                      value: _draft.orbs.softness,
                      min: 0,
                      max: 1,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            orbs: _draft.orbs.copyWith(softness: v),
                          ),
                        );
                      },
                    ),
                    if (!_draft.orbs.useThemeColors) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(3, (index) {
                          final orbColors = _ensureAtLeastNColors(
                            _draft.orbs.colors,
                            3,
                            cs.tertiaryContainer,
                          );
                          final c = Color(orbColors[index]);
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _editColorInList(
                              title: l.bgEditorOrbColorN(index + 1),
                              colors: _draft.orbs.colors,
                              index: index,
                              fallback: cs.tertiaryContainer,
                              onChanged: (updated) {
                                _updateDraft(
                                  _draft.copyWith(
                                    orbs: _draft.orbs.copyWith(
                                      colors: updated.take(4).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),

              // Pattern + effects
              _sectionCard(
                accent: cs.secondary,
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorEffects,
                      Icons.auto_fix_high_rounded,
                      color: cs.secondary,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<CustomBackgroundPatternType>(
                      segments: [
                        ButtonSegment(
                          value: CustomBackgroundPatternType.none,
                          label: Text(l.bgEditorPatternNone),
                          icon: const Icon(Icons.block_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: CustomBackgroundPatternType.lines,
                          label: Text(l.bgEditorPatternLines),
                          icon: const Icon(
                            Icons.horizontal_rule_rounded,
                            size: 18,
                          ),
                        ),
                        ButtonSegment(
                          value: CustomBackgroundPatternType.grid,
                          label: Text(l.bgEditorPatternGrid),
                          icon: const Icon(Icons.grid_on_rounded, size: 18),
                        ),
                      ],
                      selected: {_draft.pattern.type},
                      onSelectionChanged: (v) {
                        if (v.isEmpty) return;
                        HapticFeedback.selectionClick();
                        _updateDraft(
                          _draft.copyWith(
                            pattern: _draft.pattern.copyWith(type: v.first),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _slider(
                      label: l.bgEditorPatternOpacity,
                      value: _draft.pattern.opacity,
                      min: 0,
                      max: 0.45,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            pattern: _draft.pattern.copyWith(opacity: v),
                          ),
                        );
                      },
                      valueLabel: (v) => '${(v * 100).round()}%',
                    ),
                    _slider(
                      label: l.bgEditorPatternScale,
                      value: _draft.pattern.scale,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (v) {
                        _updateDraft(
                          _draft.copyWith(
                            pattern: _draft.pattern.copyWith(scale: v),
                          ),
                        );
                      },
                    ),
                    if (_draft.pattern.type ==
                        CustomBackgroundPatternType.lines)
                      _slider(
                        label: l.bgEditorPatternAngle,
                        value: _draft.pattern.angleDeg,
                        min: 0,
                        max: 360,
                        onChanged: (v) {
                          _updateDraft(
                            _draft.copyWith(
                              pattern: _draft.pattern.copyWith(angleDeg: v),
                            ),
                          );
                        },
                        valueLabel: (v) => '${v.round()}°',
                      ),
                    const SizedBox(height: 6),
                    _slider(
                      label: l.bgEditorNoise,
                      value: _draft.noise,
                      min: 0,
                      max: 0.30,
                      onChanged: (v) => _updateDraft(_draft.copyWith(noise: v)),
                      valueLabel: (v) => '${(v * 100).round()}%',
                    ),
                    _slider(
                      label: l.bgEditorVignette,
                      value: _draft.vignette,
                      min: 0,
                      max: 0.70,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(vignette: v)),
                      valueLabel: (v) => '${(v * 100).round()}%',
                    ),
                  ],
                ),
              ),

              // Motion
              _sectionCard(
                accent: cs.primaryContainer,
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorMotion,
                      Icons.motion_photos_on_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.bgEditorAnimate,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      value: _draft.animate,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        _updateDraft(_draft.copyWith(animate: v));
                      },
                    ),
                    _slider(
                      label: l.bgEditorSpeed,
                      value: _draft.animationSpeed,
                      min: 0,
                      max: 2.5,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(animationSpeed: v)),
                    ),
                    _slider(
                      label: l.bgEditorParallax,
                      value: _draft.parallaxStrength,
                      min: 0,
                      max: 1,
                      onChanged: (v) =>
                          _updateDraft(_draft.copyWith(parallaxStrength: v)),
                      valueLabel: (v) => '${(v * 100).round()}%',
                    ),
                  ],
                ),
              ),

              // AI
              _sectionCard(
                accent: cs.tertiary,
                radius: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(
                      l.bgEditorAiTitle,
                      Icons.auto_awesome_rounded,
                      color: cs.tertiary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.bgEditorAiDesc,
                      style: GoogleFonts.outfit(
                        fontSize: 12.8,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aiCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l.bgEditorAiHint,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _aiBusy ? null : _generateWithAi,
                        icon: _aiBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          l.bgEditorAiGenerate,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
