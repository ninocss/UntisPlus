part of '../../main.dart';

class SettingsCalendarPage extends StatefulWidget {
  const SettingsCalendarPage({super.key});

  @override
  State<SettingsCalendarPage> createState() => _SettingsCalendarPageState();
}

class _SettingsCalendarPageState extends State<SettingsCalendarPage> {
  List<Map<String, dynamic>> _availableCalendars = [];
  bool _loadingCalendars = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    try {
      dynamic calendars;
      try {
        calendars = await (NativeCalendar as dynamic).getCalendars();
      } catch (_) {
        calendars = <dynamic>[];
      }
      if (mounted) {
        setState(() {
          _availableCalendars = List<Map<String, dynamic>>.from(calendars as List);
          _loadingCalendars = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCalendars = false);
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
        child: _loadingCalendars
            ? const Center(child: CircularProgressIndicator())
            : ListView(
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
                            return Switch.adaptive(
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
                            trailing: showEvents
                                ? FilledButton.tonal(
                                    onPressed: () {
                                      showCalendarEventsNotifier.value = false;
                                    },
                                    child: Text(l.settingsCalendarRevokeAccess),
                                  )
                                : FilledButton(
                                    onPressed: () {
                                      showCalendarEventsNotifier.value = true;
                                    },
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
                        onTap: () {
                          // TODO: Trigger calendar sync
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.settingsCalendarSyncNow)),
                          );
                        },
                        trailing: const Icon(Icons.chevron_right_rounded),
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
                              Text(
                                l.settingsCalendarEventTypesDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
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
                                  onSelectionChanged: (v) {
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
  final List<Map<String, dynamic>> availableCalendars;
  final ValueChanged<bool> onSelectionChanged;

  const _EventTypeConfigTile({
    required this.eventKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.typeColor,
    required this.selected,
    required this.availableCalendars,
    required this.onSelectionChanged,
  });

  @override
  State<_EventTypeConfigTile> createState() => _EventTypeConfigTileState();
}

class _EventTypeConfigTileState extends State<_EventTypeConfigTile> {
  String? _selectedCalendarId;
  bool _creatingCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadCalendarId();
  }

  Future<void> _loadCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('calendarSyncSubCalendar_${widget.eventKey}');
    if (mounted && saved != null && saved.isNotEmpty) {
      setState(() => _selectedCalendarId = saved);
    }
  }

  Future<void> _saveCalendarId(String? calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    if (calendarId != null && calendarId.isNotEmpty) {
      await prefs.setString(
          'calendarSyncSubCalendar_${widget.eventKey}', calendarId);
    } else {
      await prefs.remove('calendarSyncSubCalendar_${widget.eventKey}');
    }
  }

  Future<void> _createAndSelectCalendar() async {
    setState(() => _creatingCalendar = true);
    try {
      final name = 'Untis+ ${widget.title}';
      final colorHex = widget.typeColor.value.toRadixString(16).padLeft(8, '0');
      String? calendarId;
      try {
        calendarId = await (NativeCalendar as dynamic).createCalendar(
          name: name,
          color: colorHex,
        );
      } catch (_) {
        calendarId = null;
      }
      if (calendarId != null) {
        setState(() => _selectedCalendarId = calendarId);
        await _saveCalendarId(calendarId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created calendar: $name')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create calendar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingCalendar = false);
    }
  }

  Future<void> _selectExistingCalendar(String calendarId) async {
    setState(() => _selectedCalendarId = calendarId);
    await _saveCalendarId(calendarId);
  }

  void _clearCalendar() async {
    setState(() => _selectedCalendarId = null);
    await _saveCalendarId(null);
  }

  @override
  Widget build(BuildContext context) {
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
                // Sub-calendar selection
                Text(
                  'Sub-Calendar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedCalendarId,
                  decoration: InputDecoration(
                    labelText: 'Calendar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: const Text('Use default calendar'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Default calendar'),
                    ),
                    ...widget.availableCalendars.map((cal) {
                      final calId = cal['id']?.toString() ?? '';
                      final calName = cal['name']?.toString() ?? 'Unknown';
                      final calColorStr = cal['color']?.toString() ?? '#000000';
                      Color calColor;
                      try {
                        calColor = Color(int.parse(
                          calColorStr.replaceFirst('#', '0xFF'),
                        ));
                      } catch (_) {
                        calColor = Colors.grey;
                      }

                      return DropdownMenuItem<String>(
                        value: calId,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: calColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                calName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value == null || value.isEmpty) {
                      _clearCalendar();
                    } else {
                      _selectExistingCalendar(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Create dedicated calendar button
                OutlinedButton.icon(
                  onPressed: _creatingCalendar ? null : _createAndSelectCalendar,
                  icon: _creatingCalendar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_creatingCalendar
                      ? 'Creating...'
                      : 'Create dedicated "Untis+ ${widget.title}" calendar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.typeColor,
                    side: BorderSide(color: widget.typeColor),
                  ),
                ),
                if (_selectedCalendarId != null && _selectedCalendarId!.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearCalendar,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Use default calendar instead'),
                  ),
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