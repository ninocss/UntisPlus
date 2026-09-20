part of '../../main.dart';

class SettingsCalendarPage extends StatefulWidget {
  const SettingsCalendarPage({super.key});

  @override
  State<SettingsCalendarPage> createState() => _SettingsCalendarPageState();
}

class _SettingsCalendarPageState extends State<SettingsCalendarPage> {
  bool _hasCalendarPermissions = false;
  List<SystemCalendar> _availableCalendars = [];
  bool _loadingCalendars = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPerms = await NativeCalendar.hasCalendarPermissions();
    if (mounted) {
      setState(() => _hasCalendarPermissions = hasPerms);
    }
    if (hasPerms) {
      await _loadCalendars();
    }
  }

  Future<void> _loadCalendars() async {
    setState(() => _loadingCalendars = true);
    final repo = CalendarSyncRepository(await SharedPreferences.getInstance());
    final calendars = await repo.fetchSystemCalendars();
    if (mounted) {
      setState(() {
        _availableCalendars = calendars;
        _loadingCalendars = false;
      });
    }
  }

  Future<void> _requestCalendarPermissions() async {
    final granted = await NativeCalendar.requestCalendarPermissions();
    if (mounted) {
      setState(() => _hasCalendarPermissions = granted);
      if (granted) {
        showCalendarEventsNotifier.value = true;
        await _loadCalendars();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsSectionCalendar)),
      body: _AnimatedBackground(
        child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 120,
            ),
            children: [
              // Calendar visibility
              SettingsGroup(
                title: l.settingsSectionCalendar,
                children: [
                  SettingsTile(
                    icon: Icons.calendar_month_rounded,
                    iconBackgroundColor:
                        colors.tertiaryContainer.withValues(alpha: 0.7),
                    iconColor: colors.onTertiaryContainer,
                    title: l.settingsShowCalendarEvents,
                    subtitle: l.settingsShowCalendarEventsDesc,
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: showCalendarEventsNotifier,
                      builder: (context, value, _) {
                        return Switch(
                          value: value,
                          onChanged: (v) {
                            showCalendarEventsNotifier.value = v;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calendar sync
              SettingsGroup(
                title: l.settingsCalendarSync,
                children: [
                  // Permission / Connection status
                  ValueListenableBuilder<bool>(
                    valueListenable: showCalendarEventsNotifier,
                    builder: (context, showEvents, _) {
                      return SettingsTile(
                        icon: Icons.sync_rounded,
                        iconBackgroundColor:
                            colors.primaryContainer.withValues(alpha: 0.7),
                        iconColor: colors.onPrimaryContainer,
                        title: l.settingsCalendarPermission,
                        subtitle: l.settingsCalendarPermissionDesc,
                        trailing: _hasCalendarPermissions
                            ? FilledButton.tonal(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'To revoke calendar access, please go to system settings.',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(l.settingsCalendarRevokeAccess),
                              )
                            : FilledButton(
                                onPressed: _requestCalendarPermissions,
                                child: Text(l.settingsCalendarGrantAccess),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Sync now button
                  SettingsTile(
                    icon: Icons.refresh_rounded,
                    iconBackgroundColor:
                        colors.secondaryContainer.withValues(alpha: 0.7),
                    iconColor: colors.onSecondaryContainer,
                    title: l.settingsCalendarSyncNow,
                    subtitle: l.settingsCalendarSyncDesc,
                    onTap: () async {
                      if (!_hasCalendarPermissions) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please grant calendar permissions first.',
                            ),
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.settingsCalendarSyncNow)),
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      final syncService = await CalendarSyncService.create();
                      final result = await syncService.syncAll();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sync complete: ${result.created} created, ${result.updated} updated'
                              '${result.error != null ? ' - Error: ${result.error}' : ''}',
                            ),
                          ),
                        );
                      }
                    },
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(height: 12),
                  // Automatic sync after every timetable refresh
                  ValueListenableBuilder<bool>(
                    valueListenable: calendarAutoSyncNotifier,
                    builder: (context, autoSync, _) {
                      return SettingsTile(
                        icon: Icons.event_repeat_rounded,
                        iconBackgroundColor: colors.secondaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        iconColor: colors.onSecondaryContainer,
                        title: l.settingsCalendarAutoSync,
                        subtitle: l.settingsCalendarAutoSyncDesc,
                        trailing: Switch(
                          value: autoSync,
                          onChanged: (v) {
                            calendarAutoSyncNotifier.value = v;
                            SharedPreferences.getInstance().then(
                              (p) => p.setBool('calendarAutoSync', v),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Event types to sync with sub-calendar configuration
              SettingsGroup(
                title: l.settingsCalendarEventTypes,
                children: [
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _calendarSyncEventTypesNotifier,
                    builder: (context, selectedTypes, _) {
                      final eventTypes = [
                        (
                          'tests',
                          Icons.quiz_rounded,
                          l.onboardingCalendarEventTests,
                          l.onboardingCalendarEventTestsDesc,
                          const Color(0xFFEF5350), // red
                        ),
                        (
                          'homework',
                          Icons.assignment_rounded,
                          l.onboardingCalendarEventHomework,
                          l.onboardingCalendarEventHomeworkDesc,
                          const Color(0xFFFFA726), // orange
                        ),
                        (
                          'conversations',
                          Icons.forum_rounded,
                          l.onboardingCalendarEventConversations,
                          l.onboardingCalendarEventConversationsDesc,
                          const Color(0xFF26A69A), // teal
                        ),
                        (
                          'learning',
                          Icons.menu_book_rounded,
                          l.onboardingCalendarEventLearning,
                          l.onboardingCalendarEventLearningDesc,
                          const Color(0xFF66BB6A), // green
                        ),
                        (
                          'assignments',
                          Icons.event_available_rounded,
                          l.onboardingCalendarEventAssignments,
                          l.onboardingCalendarEventAssignmentsDesc,
                          const Color(0xFF5C6BC0), // indigo
                        ),
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ...eventTypes.map((e) {
                            final key = e.$1;
                            final selected = selectedTypes.contains(key);
                            final typeColor = e.$5;

                            return _EventTypeConfigTile(
                              eventKey: key,
                              title: e.$3,
                              subtitle: e.$4,
                              icon: e.$2,
                              typeColor: typeColor,
                              selected: selected,
                              availableCalendars: _availableCalendars,
                              loadingCalendars: _loadingCalendars,
                              onSelectionChanged: (v) async {
                                if (v == true) {
                                  _calendarSyncEventTypesNotifier.value = {
                                    ...selectedTypes,
                                    key,
                                  };
                                } else {
                                  _calendarSyncEventTypesNotifier.value =
                                      selectedTypes.where((t) => t != key).toSet();
                                }
                              },
                              onCalendarSelected: (calendarId, calendarName, calendarColor) async {
                                final repo = CalendarSyncRepository(await SharedPreferences.getInstance());
                                await repo.setSubCalendar(
                                  CalendarEventType.fromKey(key)!,
                                  calendarId: calendarId,
                                  name: calendarName,
                                  color: calendarColor,
                                );
                              },
                              onCreateCalendar: (name, color) async {
                                final repo = CalendarSyncRepository(await SharedPreferences.getInstance());
                                final calendarId = await repo.createCalendar(name, color);
                                if (calendarId != null) {
                                  await repo.setSubCalendar(
                                    CalendarEventType.fromKey(key)!,
                                    calendarId: calendarId,
                                    name: name,
                                    color: color.value.toRadixString(16).padLeft(8, '0'),
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _availableCalendars.add(SystemCalendar(
                                        id: calendarId,
                                        name: name,
                                        color: '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                                        isReadOnly: false,
                                        isDefault: false,
                                      ));
                                    });
                                  }
                                }
                                return calendarId;
                              },
                              onLoadCalendars: _loadCalendars,
                            );
                          }),
                        ],
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

class _EventTypeConfigTile extends StatefulWidget {
  final String eventKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color typeColor;
  final bool selected;
  final List<SystemCalendar> availableCalendars;
  final bool loadingCalendars;
  final ValueChanged<bool> onSelectionChanged;
  final Future<void> Function(String calendarId, String calendarName, String calendarColor) onCalendarSelected;
  final Future<String?> Function(String name, Color color) onCreateCalendar;
  final Future<void> Function() onLoadCalendars;

  const _EventTypeConfigTile({
    required this.eventKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.typeColor,
    required this.selected,
    required this.availableCalendars,
    required this.loadingCalendars,
    required this.onSelectionChanged,
    required this.onCalendarSelected,
    required this.onCreateCalendar,
    required this.onLoadCalendars,
  });

  @override
  State<_EventTypeConfigTile> createState() => _EventTypeConfigTileState();
}

class _EventTypeConfigTileState extends State<_EventTypeConfigTile> {
  String? _selectedCalendarId;
  String? _selectedCalendarName;
  String? _selectedCalendarColor;
  bool _creatingCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCalendar();
  }

  Future<void> _loadSavedCalendar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('calendarSyncSubCalendar_${widget.eventKey}');
    final savedName = prefs.getString('calendarSyncSubCalendarName_${widget.eventKey}');
    final savedColor = prefs.getString('calendarSyncSubCalendarColor_${widget.eventKey}');
    if (mounted && savedId != null && savedId.isNotEmpty) {
      setState(() {
        _selectedCalendarId = savedId;
        _selectedCalendarName = savedName;
        _selectedCalendarColor = savedColor;
      });
    }
  }

  Future<void> _saveCalendarSelection(String? calendarId, String? name, String? color) async {
    final prefs = await SharedPreferences.getInstance();
    if (calendarId != null && calendarId.isNotEmpty) {
      await prefs.setString('calendarSyncSubCalendar_${widget.eventKey}', calendarId);
      await prefs.setString('calendarSyncSubCalendarName_${widget.eventKey}', name ?? '');
      await prefs.setString('calendarSyncSubCalendarColor_${widget.eventKey}', color ?? '');
      setState(() {
        _selectedCalendarId = calendarId;
        _selectedCalendarName = name;
        _selectedCalendarColor = color;
      });
      await widget.onCalendarSelected(calendarId, name ?? '', color ?? '');
    } else {
      await prefs.remove('calendarSyncSubCalendar_${widget.eventKey}');
      await prefs.remove('calendarSyncSubCalendarName_${widget.eventKey}');
      await prefs.remove('calendarSyncSubCalendarColor_${widget.eventKey}');
      setState(() {
        _selectedCalendarId = null;
        _selectedCalendarName = null;
        _selectedCalendarColor = null;
      });
      await widget.onCalendarSelected('', '', '');
    }
  }

  Future<void> _createCalendar() async {
    setState(() => _creatingCalendar = true);
    try {
      final name = 'Untis+ ${widget.title}';
      final calendarId = await widget.onCreateCalendar(name, widget.typeColor);
      if (calendarId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created calendar: $name')),
        );
        await widget.onLoadCalendars();
      }
    } finally {
      if (mounted) setState(() => _creatingCalendar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;
    final selected = widget.selected;

    return Column(
      children: [
        CheckboxListTile(
          value: selected,
          onChanged: (v) => widget.onSelectionChanged(v ?? false),
          title: Text(widget.title),
          subtitle: Text(widget.subtitle),
          secondary: Icon(widget.icon, color: widget.typeColor),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (selected) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCalendarId?.isNotEmpty == true ? _selectedCalendarId : null,
                  decoration: InputDecoration(
                    labelText: 'Select Calendar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: Text(l.settingsCalendarUseDefault),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(l.settingsCalendarUseDefault),
                    ),
                    if (widget.loadingCalendars)
                      const DropdownMenuItem<String>(
                        value: 'loading',
                        enabled: false,
                        child: Text('Loading calendars...'),
                      )
                    else
                      ...widget.availableCalendars.map((cal) {
                        return DropdownMenuItem<String>(
                          value: cal.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: cal.colorValue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cal.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cal.isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '(Default)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                  onChanged: (value) async {
                    if (value == null || value == 'loading') return;
                    if (value.isEmpty) {
                      await _saveCalendarSelection(null, null, null);
                    } else {
                      final cal = widget.availableCalendars.firstWhere((c) => c.id == value);
                      await _saveCalendarSelection(cal.id, cal.name, cal.color);
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _creatingCalendar ? null : _createCalendar,
                  icon: _creatingCalendar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_creatingCalendar
                      ? 'Creating...'
                      : 'Create "Untis+ ${widget.title}" calendar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.typeColor,
                    side: BorderSide(color: widget.typeColor),
                  ),
                ),
                if (_selectedCalendarId != null && _selectedCalendarId!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _saveCalendarSelection(null, null, null),
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(l.settingsUseDefaultCalendar),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Divider(height: 1),
      ],
    );
  }
}