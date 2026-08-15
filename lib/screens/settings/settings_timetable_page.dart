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
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.settingsCancelledColor,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l.settingsColorRed}: ${red.round()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: red,
                  min: 0,
                  max: 255,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => red = v),
                ),
                Text(
                  '${l.settingsColorGreen}: ${green.round()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: green,
                  min: 0,
                  max: 255,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => green = v),
                ),
                Text(
                  '${l.settingsColorBlue}: ${blue.round()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: blue,
                  min: 0,
                  max: 255,
                  activeColor: Colors.blue,
                  onChanged: (v) => setState(() => blue = v),
                ),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 8),
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
    final mq = MediaQuery.of(context);

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
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            SettingsGroup(
              title: l.settingsSectionTimetable,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: showCancelledNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.event_busy_rounded,
                      iconBackgroundColor: cs.errorContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onErrorContainer,
                      title: l.settingsShowCancelled,
                      subtitle: l.settingsShowCancelledDesc,
                      value: value,
                      onChanged: _settingsSetShowCancelled,
                    );
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: cancelledLessonColorNotifier,
                  builder: (context, colorValue, _) {
                    final cancelledColor = Color(colorValue);
                    return SettingsTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cancelledColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                      title: l.settingsCancelledColor,
                      subtitle: l.settingsCancelledColorDesc,
                      onTap:
                          () => _showCancelledColorPicker(
                            context,
                            cancelledColor,
                          ),
                    );
                  },
                ),
              ],
            ),
            SettingsGroup(
              title: l.settingsRefreshPushWidgetNow,
              children: [
                SettingsTile(
                  icon: Icons.sync_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsRefreshPushWidgetNow,
                  subtitle: l.settingsRefreshPushWidgetNowDesc,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
