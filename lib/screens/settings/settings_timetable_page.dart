// settings_timetable_page.dart
part of '../../main.dart';

class SettingsTimetablePage extends StatelessWidget {
  const SettingsTimetablePage({super.key});

  void _showCancelledColorPicker(BuildContext context, Color current) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    double red = current.r * 255.0;
    double green = current.g * 255.0;
    double blue = current.b * 255.0;

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setState) {
          final preview = Color.fromARGB(
            255, red.round(), green.round(), blue.round(),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42, height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsCancelledColor,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800, fontSize: 18,
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
                  value: red, min: 0, max: 255,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => red = v),
                ),
                Text(
                  '${l.settingsColorGreen}: ${green.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: green, min: 0, max: 255,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => green = v),
                ),
                Text(
                  '${l.settingsColorBlue}: ${blue.round()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: blue, min: 0, max: 255,
                  activeColor: Colors.blue,
                  onChanged: (v) => setState(() => blue = v),
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
                      onPressed: () {
                        _settingsSetCancelledLessonColor(preview.toARGB32());
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

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionTimetable,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: showCancelledNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetShowCancelled,
                    title: Text(
                      l.settingsShowCancelled,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsShowCancelledDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<int>(
                valueListenable: cancelledLessonColorNotifier,
                builder: (context, colorValue, _) {
                  final cancelledColor = Color(colorValue);
                  return ListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cancelledColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: Text(
                      l.settingsCancelledColor,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsCancelledColorDesc,
                      style: GoogleFonts.outfit(),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showCancelledColorPicker(context, cancelledColor),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: Text(
                  l.settingsRefreshPushWidgetNow,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsRefreshPushWidgetNowDesc,
                  style: GoogleFonts.outfit(),
                ),
                onTap: () async {
                  await updateUntisData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.settingsBackgroundLoading),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}