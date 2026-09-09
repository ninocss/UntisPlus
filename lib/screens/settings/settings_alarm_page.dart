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
    String? suffix,
  }) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final effectiveSuffix = suffix ?? l.ui('alarmMinutesSuffix');
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
                  '$value$effectiveSuffix',
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
                  label: '$value$effectiveSuffix',
                  onChanged: (next) =>
                      setSheetState(() => value = next.round()),
                ),
                FilledButton(
                  onPressed: () {
                    onChanged(value);
                    Navigator.pop(context);
                  },
                  child: Text(l.ui('alarmApply')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addManualAlarm() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final alarm = ManualAlarmConfig(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timeOfDayMinutes: 7 * 60,
      weekdays: const [1, 2, 3, 4, 5],
      label: l.ui('alarmOwn'),
    );
    await _save(
      _config.copyWith(manualAlarms: [..._config.manualAlarms, alarm]),
    );
  }

  Future<void> _editManualAlarm(ManualAlarmConfig alarm) async {
    final l = AppL10n.of(appLocaleNotifier.value);
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
                    l.ui('alarmOwn'),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(time.format(context)),
                    subtitle: Text(l.ui('alarmTime')),
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
                    children: l.weekDayShort.asMap().entries.map((entry) {
                      final weekday = entry.key + 1;
                      return FilterChip(
                        label: Text(entry.value),
                        selected: edited.weekdays.contains(weekday),
                        onSelected: (selected) {
                          final days = edited.weekdays.toSet();
                          selected ? days.add(weekday) : days.remove(weekday);
                          setSheetState(
                            () => edited = edited.copyWith(
                              weekdays: days.toList()..sort(),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  SwitchListTile(
                    title: Text(l.ui('alarmActive')),
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
                        label: Text(l.ui('alarmDelete')),
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
                        child: Text(l.ui('alarmSave')),
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
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final readiness = _readiness!;
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.ui('alarmTitle'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            SettingsGroup(
              title: l.ui('alarmReady'),
              children: [
                SettingsTile(
                  icon: readiness.isReady
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  iconColor: readiness.isReady ? cs.primary : cs.error,
                  title: readiness.isReady
                      ? l.ui('alarmReadyYes')
                      : l.ui('alarmReadyNo'),
                  subtitle: readiness.isReady
                      ? l.ui('alarmReadyDescYes')
                      : l.ui('alarmReadyDescNo'),
                  trailing: const SizedBox.shrink(),
                ),
                if (!readiness.exactAlarms)
                  SettingsTile(
                    icon: Icons.alarm_rounded,
                    title: l.ui('alarmExact'),
                    subtitle: l.ui('alarmExactDesc'),
                    onTap: () =>
                        AlarmService.instance.openPermissionSettings('exact'),
                  ),
                if (!readiness.notifications)
                  SettingsTile(
                    icon: Icons.notifications_off_rounded,
                    title: l.ui('alarmNotifications'),
                    subtitle: l.ui('alarmNotificationsDesc'),
                    onTap: () async {
                      await NotificationService().requestPermissions();
                      await _load();
                    },
                  ),
                if (!readiness.fullScreenIntent)
                  SettingsTile(
                    icon: Icons.fullscreen_rounded,
                    title: l.ui('alarmFullscreen'),
                    subtitle: l.ui('alarmFullscreenDesc'),
                    onTap: () => AlarmService.instance.openPermissionSettings(
                      'fullscreen',
                    ),
                  ),
                if (!readiness.dndAccess)
                  SettingsTile(
                    icon: Icons.do_not_disturb_on_rounded,
                    title: l.ui('alarmDnd'),
                    subtitle: l.ui('alarmDndDesc'),
                    onTap: () =>
                        AlarmService.instance.openPermissionSettings('dnd'),
                  ),
              ],
            ),
            SettingsGroup(
              title: l.ui('alarmSmart'),
              children: [
                SettingsSwitchTile(
                  icon: Icons.auto_awesome_rounded,
                  title: l.ui('alarmSchedule'),
                  subtitle: l.ui('alarmScheduleDesc'),
                  value: _config.smartEnabled,
                  onChanged: (value) => _save(
                    _config.copyWith(smartEnabled: value),
                    refreshTimetable: value,
                  ),
                ),
                SettingsTile(
                  icon: Icons.directions_walk_rounded,
                  title: l.ui('alarmLead'),
                  subtitle: l
                      .ui('alarmLeadValue')
                      .replaceAll('{n}', '${_config.leadMinutes}'),
                  onTap: () => _chooseMinutes(
                    title: l.ui('alarmLead'),
                    current: _config.leadMinutes,
                    min: 0,
                    max: 180,
                    onChanged: (value) => _save(
                      _config.copyWith(leadMinutes: value),
                      refreshTimetable: _config.smartEnabled,
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.sync_rounded,
                  title: l.ui('alarmUpdate'),
                  subtitle: l.ui('alarmUpdateDesc'),
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
            SettingsGroup(
              title: l.ui('alarmRing'),
              children: [
                SettingsTile(
                  icon: Icons.snooze_rounded,
                  title: l.ui('alarmSnooze'),
                  subtitle: l
                      .ui('alarmSnoozeValue')
                      .replaceAll('{n}', '${_config.snoozeMinutes}'),
                  onTap: () => _chooseMinutes(
                    title: l.ui('alarmSnoozeDuration'),
                    current: _config.snoozeMinutes,
                    min: 1,
                    max: 30,
                    onChanged: (value) =>
                        _save(_config.copyWith(snoozeMinutes: value)),
                  ),
                ),
                SettingsTile(
                  icon: Icons.music_note_rounded,
                  title: l.ui('alarmRingtone'),
                  subtitle: _config.ringtoneUri == null
                      ? l.ui('alarmSystemTone')
                      : l.ui('alarmSelectedTone'),
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
              title: l.ui('alarmOwnAlarms'),
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
                  title: l.ui('alarmAdd'),
                  subtitle: l.ui('alarmAddDesc'),
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
