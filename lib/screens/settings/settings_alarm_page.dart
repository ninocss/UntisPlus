part of '../../main.dart';

class SettingsAlarmPage extends StatefulWidget {
  const SettingsAlarmPage({super.key});

  @override
  State<SettingsAlarmPage> createState() => _SettingsAlarmPageState();
}

class _SettingsAlarmPageState extends State<SettingsAlarmPage> {
  AlarmConfig _config = const AlarmConfig();
  AlarmReadiness? _readiness;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await AlarmService.instance.loadConfig();
    final readiness = await AlarmService.instance.readiness();
    if (!mounted) return;
    setState(() {
      _config = config;
      _readiness = readiness;
      _loading = false;
    });
  }

  Future<void> _save(
    AlarmConfig config, {
    bool refreshTimetable = false,
  }) async {
    setState(() => _config = config);
    await AlarmService.instance.saveConfig(config);
    if (refreshTimetable && config.smartEnabled) {
      await updateUntisData();
    }
    await _load();
  }

  Future<void> _chooseMinutes({
    required String title,
    required int current,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    String suffix = ' Min.',
  }) async {
    var value = current;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$value$suffix',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  label: '$value$suffix',
                  onChanged: (next) =>
                      setSheetState(() => value = next.round()),
                ),
                FilledButton(
                  onPressed: () {
                    onChanged(value);
                    Navigator.pop(context);
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addManualAlarm() async {
    final alarm = ManualAlarmConfig(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timeOfDayMinutes: 7 * 60,
      weekdays: const [1, 2, 3, 4, 5],
      label: 'Eigener Wecker',
    );
    await _save(
      _config.copyWith(manualAlarms: [..._config.manualAlarms, alarm]),
    );
  }

  Future<void> _editManualAlarm(ManualAlarmConfig alarm) async {
    var edited = alarm;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final time = TimeOfDay(
            hour: edited.timeOfDayMinutes ~/ 60,
            minute: edited.timeOfDayMinutes % 60,
          );
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewPadding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Eigener Wecker',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(time.format(context)),
                    subtitle: const Text('Weckzeit'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setSheetState(
                          () => edited = edited.copyWith(
                            timeOfDayMinutes: picked.hour * 60 + picked.minute,
                          ),
                        );
                      }
                    },
                  ),
                  Wrap(
                    spacing: 6,
                    children: const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                        .asMap()
                        .entries
                        .map((entry) {
                          final weekday = entry.key + 1;
                          return FilterChip(
                            label: Text(entry.value),
                            selected: edited.weekdays.contains(weekday),
                            onSelected: (selected) {
                              final days = edited.weekdays.toSet();
                              selected
                                  ? days.add(weekday)
                                  : days.remove(weekday);
                              setSheetState(
                                () => edited = edited.copyWith(
                                  weekdays: days.toList()..sort(),
                                ),
                              );
                            },
                          );
                        })
                        .toList(),
                  ),
                  SwitchListTile(
                    title: const Text('Aktiv'),
                    value: edited.enabled,
                    onChanged: (value) => setSheetState(
                      () => edited = edited.copyWith(enabled: value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Löschen'),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _save(
                            _config.copyWith(
                              manualAlarms: _config.manualAlarms
                                  .where((item) => item.id != alarm.id)
                                  .toList(),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: edited.weekdays.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(sheetContext);
                                final alarms = _config.manualAlarms
                                    .map(
                                      (item) =>
                                          item.id == alarm.id ? edited : item,
                                    )
                                    .toList();
                                await _save(
                                  _config.copyWith(manualAlarms: alarms),
                                );
                              },
                        child: const Text('Speichern'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final readiness = _readiness!;
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          'Wecker',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            SettingsGroup(
              title: 'Weckerbereit',
              children: [
                SettingsTile(
                  icon: readiness.isReady
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  iconColor: readiness.isReady ? cs.primary : cs.error,
                  title: readiness.isReady
                      ? 'Für zuverlässige Wecker bereit'
                      : 'Android-Freigaben fehlen',
                  subtitle: readiness.isReady
                      ? 'Exakte Alarme, Vollbild und Nicht stören sind aktiv.'
                      : 'Öffne die fehlenden Android-Systemeinstellungen.',
                  trailing: const SizedBox.shrink(),
                ),
                if (!readiness.exactAlarms)
                  SettingsTile(
                    icon: Icons.alarm_rounded,
                    title: 'Exakte Alarme erlauben',
                    subtitle:
                        'Erforderlich, damit Android den Weckzeitpunkt nicht verschiebt.',
                    onTap: () =>
                        AlarmService.instance.openPermissionSettings('exact'),
                  ),
                if (!readiness.notifications)
                  SettingsTile(
                    icon: Icons.notifications_off_rounded,
                    title: 'Benachrichtigungen erlauben',
                    subtitle:
                        'Erforderlich für den sichtbaren Vollbild-Wecker.',
                    onTap: () async {
                      await NotificationService().requestPermissions();
                      await _load();
                    },
                  ),
                if (!readiness.fullScreenIntent)
                  SettingsTile(
                    icon: Icons.fullscreen_rounded,
                    title: 'Vollbild-Wecker erlauben',
                    subtitle: 'Zeigt den Wecker auf dem Sperrbildschirm.',
                    onTap: () => AlarmService.instance.openPermissionSettings(
                      'fullscreen',
                    ),
                  ),
                if (!readiness.dndAccess)
                  SettingsTile(
                    icon: Icons.do_not_disturb_on_rounded,
                    title: 'Nicht stören umgehen',
                    subtitle:
                        'Erlaubt aktivierten Weckern, trotz „Nicht stören“ zu klingeln.',
                    onTap: () =>
                        AlarmService.instance.openPermissionSettings('dnd'),
                  ),
              ],
            ),
            SettingsGroup(
              title: 'Smart-Wecker',
              children: [
                SettingsSwitchTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Stundenplan-Wecker',
                  subtitle: 'Weckt vor der ersten nicht ausgefallenen Stunde.',
                  value: _config.smartEnabled,
                  onChanged: (value) => _save(
                    _config.copyWith(smartEnabled: value),
                    refreshTimetable: value,
                  ),
                ),
                SettingsTile(
                  icon: Icons.directions_walk_rounded,
                  title: 'Vorlauf',
                  subtitle: '${_config.leadMinutes} Min. vor der ersten Stunde',
                  onTap: () => _chooseMinutes(
                    title: 'Vorlauf',
                    current: _config.leadMinutes,
                    min: 0,
                    max: 180,
                    onChanged: (value) => _save(
                      _config.copyWith(leadMinutes: value),
                      refreshTimetable: _config.smartEnabled,
                    ),
                  ),
                ),
                const SettingsTile(
                  icon: Icons.sync_rounded,
                  title: 'Kurz vor dem Wecker aktualisieren',
                  subtitle:
                      'WebUntis wird 15 Minuten vorher noch einmal geprüft.',
                  trailing: SizedBox.shrink(),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Klingeln',
              children: [
                SettingsTile(
                  icon: Icons.snooze_rounded,
                  title: 'Schlummern',
                  subtitle:
                      '${_config.snoozeMinutes} Min. · nach links wischen',
                  onTap: () => _chooseMinutes(
                    title: 'Schlummerdauer',
                    current: _config.snoozeMinutes,
                    min: 1,
                    max: 30,
                    onChanged: (value) =>
                        _save(_config.copyWith(snoozeMinutes: value)),
                  ),
                ),
                SettingsTile(
                  icon: Icons.music_note_rounded,
                  title: 'Klingelton',
                  subtitle: _config.ringtoneUri == null
                      ? 'Android-Systemweckton'
                      : 'Ausgewählter Android-Weckton',
                  onTap: () async {
                    final uri = await AlarmService.instance.pickRingtone(
                      _config.ringtoneUri,
                    );
                    if (uri != null)
                      await _save(_config.copyWith(ringtoneUri: uri));
                  },
                ),
              ],
            ),
            SettingsGroup(
              title: 'Eigene Wecker',
              children: [
                for (final alarm in _config.manualAlarms)
                  SettingsTile(
                    icon: Icons.alarm_rounded,
                    title:
                        '${(alarm.timeOfDayMinutes ~/ 60).toString().padLeft(2, '0')}:${(alarm.timeOfDayMinutes % 60).toString().padLeft(2, '0')}',
                    subtitle: alarm.weekdays
                        .map(
                          (day) => const [
                            'Mo',
                            'Di',
                            'Mi',
                            'Do',
                            'Fr',
                            'Sa',
                            'So',
                          ][day - 1],
                        )
                        .join(' · '),
                    onTap: () => _editManualAlarm(alarm),
                  ),
                SettingsTile(
                  icon: Icons.add_alarm_rounded,
                  title: 'Wecker hinzufügen',
                  subtitle: 'Wiederholt sich an ausgewählten Wochentagen.',
                  onTap: _addManualAlarm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
