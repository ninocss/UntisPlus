part of '../../main.dart';

class SubjectPresentationsPage extends StatelessWidget {
  const SubjectPresentationsPage({super.key});

  Future<void> _edit(BuildContext context, String key) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final existing = subjectPresentationsNotifier.value[key];
    var name = existing?.name ?? '';
    var iconKey = existing?.icon ?? '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(l.settingsSubjectCustomizeFor(key)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: name,
                  onChanged: (value) => name = value,
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: l.settingsSubjectCustomName,
                    hintText: key,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.settingsSubjectIcon),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.settingsSubjectDefaultIcon),
                      selected: iconKey.isEmpty,
                      onSelected: (_) => update(() => iconKey = ''),
                    ),
                    for (final entry in subjectIconChoices.entries)
                      IconButton.filledTonal(
                        tooltip: l.settingsSubjectIcon,
                        onPressed: () => update(() => iconKey = entry.key),
                        style: IconButton.styleFrom(
                          backgroundColor: iconKey == entry.key
                              ? Theme.of(
                                  dialogContext,
                                ).colorScheme.primaryContainer
                              : null,
                        ),
                        icon: Icon(entry.value),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await _setSubjectPresentation(key, null);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: Text(l.settingsSubjectReset),
              ),
            FilledButton(
              onPressed: () async {
                await _setSubjectPresentation(
                  key,
                  SubjectPresentation(
                    name: name.trim(),
                    icon: iconKey,
                    aliases: _subjectAliases(key).toList(growable: false),
                  ),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(l.commonSaveChanges),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    return SettingsPageShell(
      title: l.settingsSubjectCustomize,
      children: [
        ValueListenableBuilder<Set<String>>(
          valueListenable: knownSubjectsNotifier,
          builder: (context, known, _) =>
              ValueListenableBuilder<Map<String, SubjectPresentation>>(
                valueListenable: subjectPresentationsNotifier,
                builder: (context, custom, _) {
                  final keys = {...known, ...custom.keys}.toList()..sort();
                  if (keys.isEmpty) return Text(l.settingsNoSubjectsLoaded);
                  return SettingsGroup(
                    children: [
                      for (final key in keys)
                        SettingsTile(
                          icon:
                              _customSubjectIcon(key) ??
                              Icons.menu_book_outlined,
                          title: _displaySubject(key),
                          subtitle: custom[key]?.name.isNotEmpty == true
                              ? key
                              : l.settingsSubjectCustomizeDesc,
                          onTap: () => _edit(context, key),
                        ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }
}

class SubjectColorsPage extends StatelessWidget {
  const SubjectColorsPage({super.key});

  void _showCustomColorPicker(
    BuildContext context,
    String subject,
    Color? current,
  ) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallback = _autoLessonColor(subject, isDark);

    double red = ((current ?? fallback).r * 255.0);
    double green = ((current ?? fallback).g * 255.0);
    double blue = ((current ?? fallback).b * 255.0);

    _showUnifiedSheet<void>(
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
                const SizedBox(height: 4),
                Text(
                  l.settingsColorFor(subject),
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
                HapticSlider(
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
                HapticSlider(
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
                HapticSlider(
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
                        l.cancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        _setSubjectColor(subject, preview.toARGB32());
                        Navigator.pop(ctx);
                      },
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

  void _showColorPicker(BuildContext context, String subject, Color? current) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final palette = _subjectColorPalette(cs);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                l.settingsColorFor(subject),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: palette.map((c) {
                  final isSelected =
                      current != null && current.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _setSubjectColor(subject, c.toARGB32());
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: cs.onSurface.withValues(alpha: 0.65),
                                width: 3,
                              )
                            : Border.all(color: Colors.transparent),
                        boxShadow:
                            isSelected &&
                                untisThemeTokensOf(context).glowEffectsEnabled
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color:
                                  ThemeData.estimateBrightnessForColor(c) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              size: 22,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCustomColorPicker(context, subject, current);
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  l.settingsColorCustomPicker,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: _legacyButtonShape(context, 14),
                ),
              ),
              if (current != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _clearSubjectColor(subject);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    l.settingsColorReset,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: _legacyButtonShape(context, 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionColors,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder(
          valueListenable: knownSubjectsNotifier,
          builder: (context, subjectsSet, _) {
            final subjects = subjectsSet.toList()..sort();
            if (subjects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoSubjectsLoaded,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.settingsNoSubjectsLoadedDesc,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: subjectColorsNotifier,
              builder: (context, colors, _) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    mq.padding.bottom + 120,
                  ),
                  children: [
                    SettingsGroup(
                      children: subjects.map((subj) {
                        final colorVal = colors[subj];
                        final subjectColor = colorVal != null
                            ? Color(colorVal)
                            : null;
                        return SettingsTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: subjectColor ?? cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: subjectColor != null
                                  ? Border.all(
                                      color: subjectColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: subjectColor == null
                                ? Icon(
                                    Icons.palette_outlined,
                                    color: cs.primary,
                                    size: 20,
                                  )
                                : null,
                          ),
                          title: subj,
                          subtitle: subjectColor != null
                              ? l.settingsCustomColor
                              : l.settingsDefaultColor,
                          onTap: () =>
                              _showColorPicker(context, subj, subjectColor),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Hidden Subjects Page ─────────────────────────────────────────────────────
class HiddenSubjectsPage extends StatelessWidget {
  const HiddenSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionHidden,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ValueListenableBuilder(
          valueListenable: hiddenSubjectsNotifier,
          builder: (context, hiddenSet, _) {
            final hidden = hiddenSet.toList()..sort();
            if (hidden.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsNoHidden,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.settingsNoHiddenDesc,
                      style: GoogleFonts.outfit(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
              children: [
                SettingsGroup(
                  children: hidden.map((subject) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                subject.isNotEmpty
                                    ? subject[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: cs.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              subject,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _unhideSubject(subject),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: _legacyButtonShape(context, 10),
                            ),
                            child: Text(
                              l.settingsUnhide,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
