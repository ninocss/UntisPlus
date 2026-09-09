part of '../main.dart';

String _studentCopy({
  required String de,
  required String en,
  required String fr,
  required String es,
}) => switch (appLocaleNotifier.value) {
  'en' => en,
  'fr' => fr,
  'es' => es,
  _ => de,
};

class StudentMorePage extends StatelessWidget {
  const StudentMorePage({super.key, required this.openAssistant});

  final VoidCallback openAssistant;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          AppL10n.of(appLocaleNotifier.value).aiMore,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.paddingOf(context).bottom + 132,
          ),
          children: [
            _MoreSection(
              title: _studentCopy(
                de: 'Schulalltag',
                en: 'School day',
                fr: 'Vie scolaire',
                es: 'Día escolar',
              ),
              children: [
                _MoreDestination(
                  icon: Icons.event_busy_rounded,
                  color: cs.error,
                  title: _studentCopy(
                    de: 'Abwesenheiten',
                    en: 'Absences',
                    fr: 'Absences',
                    es: 'Ausencias',
                  ),
                  subtitle: _studentCopy(
                    de: 'Fehlzeiten und Entschuldigungsstatus',
                    en: 'Missed lessons and excuse status',
                    fr: 'Cours manqués et statut des justificatifs',
                    es: 'Clases perdidas y estado de justificación',
                  ),
                  page: const AbsencesPage(),
                ),
                _MoreDestination(
                  icon: Icons.change_circle_rounded,
                  color: cs.tertiary,
                  title: _studentCopy(
                    de: 'Änderungen',
                    en: 'Changes',
                    fr: 'Modifications',
                    es: 'Cambios',
                  ),
                  subtitle: _studentCopy(
                    de: 'Ausfälle, Räume und Vertretungen',
                    en: 'Cancellations, rooms, and substitutions',
                    fr: 'Annulations, salles et remplacements',
                    es: 'Cancelaciones, aulas y sustituciones',
                  ),
                  page: const ChangeCenterPage(),
                ),
                _MoreDestination(
                  icon: Icons.analytics_rounded,
                  color: cs.secondary,
                  title: AppL10n.of(appLocaleNotifier.value).gradesTitle,
                  subtitle: _studentCopy(
                    de: 'Verlauf und transparente Berechnung',
                    en: 'History and transparent calculation',
                    fr: 'Historique et calcul transparent',
                    es: 'Historial y cálculo transparente',
                  ),
                  page: const GradesTrackerPage(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MoreSection(
              title: 'Untis+',
              children: [
                _MoreAction(
                  icon: Icons.auto_awesome_rounded,
                  color: cs.primary,
                  title: AppL10n.of(appLocaleNotifier.value).navAi,
                  subtitle: _studentCopy(
                    de: 'Optionaler Assistent für deinen Schulalltag',
                    en: 'Optional assistant for your school day',
                    fr: 'Assistant facultatif pour ta vie scolaire',
                    es: 'Asistente opcional para tu día escolar',
                  ),
                  onTap: openAssistant,
                ),
                _MoreDestination(
                  icon: Icons.settings_rounded,
                  color: cs.onSurfaceVariant,
                  title: AppL10n.of(appLocaleNotifier.value).settingsTitle,
                  subtitle: _studentCopy(
                    de: 'Darstellung, Konten, Widgets und Backup',
                    en: 'Appearance, accounts, widgets, and backup',
                    fr: 'Apparence, comptes, widgets et sauvegarde',
                    es: 'Apariencia, cuentas, widgets y copia',
                  ),
                  page: const SettingsHubPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          title,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    ],
  );
}

class _MoreAction extends StatelessWidget {
  const _MoreAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.14),
      child: Icon(icon, color: color),
    ),
    title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _MoreDestination extends StatelessWidget {
  const _MoreDestination({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.page,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) => _MoreAction(
    icon: icon,
    color: color,
    title: title,
    subtitle: subtitle,
    onTap: () => Navigator.of(context).push(_buildBouncyRoute(page)),
  );
}

class AbsencesPage extends ConsumerStatefulWidget {
  const AbsencesPage({super.key});

  @override
  ConsumerState<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends ConsumerState<AbsencesPage> {
  SyncState<List<Absence>> _state = const SyncState(data: []);
  AbsenceStatus? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accountId = activeUntisAccountId ?? 'legacy';
    bool isCurrentAccount() =>
        mounted && accountId == (activeUntisAccountId ?? 'legacy');
    final repository = AbsenceRepository(
      client: ref.read(webUntisClientProvider),
      sessionManager: ref.read(webUntisSessionManagerProvider),
      capabilities: ref.read(webUntisCapabilitiesProvider),
    );
    UntisAccount? activeAccount;
    for (final account in untisAccountsNotifier.value) {
      if (account.id == activeUntisAccountId) {
        activeAccount = account;
        break;
      }
    }
    final requestSchoolUrl = activeAccount?.schoolUrl ?? schoolUrl;
    final requestSchoolName = activeAccount?.schoolName ?? schoolName;
    final requestSessionId = activeAccount?.sessionId ?? sessionID;
    final cached = await repository.loadCached(accountId);
    if (isCurrentAccount()) {
      setState(
        () => _state = cached.copyWith(
          phase: cached.hasData ? SyncPhase.refreshing : SyncPhase.loading,
        ),
      );
    }
    final now = DateTime.now();
    final schoolYearStart = now.month >= 7
        ? DateTime(now.year, 7, 1)
        : DateTime(now.year - 1, 7, 1);
    final refreshed = await repository.refresh(
      accountId: accountId,
      context: WebUntisRequestContext(
        schoolUrl: requestSchoolUrl,
        schoolName: requestSchoolName,
        sessionId: requestSessionId,
      ),
      account: activeAccount == null
          ? null
          : WebUntisAccountLogin(
              accountId: activeAccount.id,
              username: activeAccount.username,
              schoolUrl: activeAccount.schoolUrl,
              schoolName: activeAccount.schoolName,
              personId: activeAccount.personId,
              personType: activeAccount.personType,
            ),
      start: schoolYearStart,
      end: now,
    );
    if (isCurrentAccount()) setState(() => _state = refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final values = _filter == null
        ? _state.data
        : _state.data.where((entry) => entry.status == _filter).toList();
    final filters = <(AbsenceStatus?, String)>[
      (null, _studentCopy(de: 'Alle', en: 'All', fr: 'Toutes', es: 'Todas')),
      (
        AbsenceStatus.open,
        _studentCopy(de: 'Offen', en: 'Open', fr: 'Ouvertes', es: 'Abiertas'),
      ),
      (
        AbsenceStatus.excused,
        _studentCopy(
          de: 'Entschuldigt',
          en: 'Excused',
          fr: 'Justifiées',
          es: 'Justificadas',
        ),
      ),
      (
        AbsenceStatus.unexcused,
        _studentCopy(
          de: 'Unentschuldigt',
          en: 'Unexcused',
          fr: 'Non justifiées',
          es: 'Sin justificar',
        ),
      ),
      (
        AbsenceStatus.unknown,
        _studentCopy(
          de: 'Unbekannt',
          en: 'Unknown',
          fr: 'Inconnu',
          es: 'Desconocido',
        ),
      ),
    ];
    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          _studentCopy(
            de: 'Abwesenheiten',
            en: 'Absences',
            fr: 'Absences',
            es: 'Ausencias',
          ),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: _AnimatedBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _SyncStatusBanner(state: _state),
              const SizedBox(height: 12),
              _AbsenceSummary(absences: _state.data),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final filter in filters)
                    ChoiceChip(
                      label: Text(filter.$2),
                      selected: _filter == filter.$1,
                      onSelected: (_) => setState(() => _filter = filter.$1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_state.phase == SyncPhase.loading && !_state.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (values.isEmpty)
                _FeatureEmptyState(
                  icon: Icons.event_available_rounded,
                  title: _studentCopy(
                    de: 'Keine Abwesenheiten',
                    en: 'No absences',
                    fr: 'Aucune absence',
                    es: 'Sin ausencias',
                  ),
                  message: _studentCopy(
                    de: 'Für diesen Zeitraum sind keine passenden Fehlzeiten vorhanden.',
                    en: 'There are no matching absences for this period.',
                    fr: 'Aucune absence correspondante pour cette période.',
                    es: 'No hay ausencias coincidentes en este período.',
                  ),
                )
              else
                ...values.map(_AbsenceTile.new),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeCenterPage extends StatefulWidget {
  const ChangeCenterPage({super.key});

  @override
  State<ChangeCenterPage> createState() => _ChangeCenterPageState();
}

class _ChangeCenterPageState extends State<ChangeCenterPage> {
  List<TimetableChange>? _changes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final changes = await ChangeRepository().loadChanges(
      activeUntisAccountId ?? 'legacy',
    );
    unreadTimetableChangesNotifier.value = changes
        .where((change) => !change.isRead)
        .length;
    if (mounted) setState(() => _changes = changes);
  }

  Future<void> _markRead() async {
    await ChangeRepository().markAllRead(activeUntisAccountId ?? 'legacy');
    unreadTimetableChangesNotifier.value = 0;
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: RoundedBlurAppBar(
      title: Text(
        _studentCopy(
          de: 'Änderungen',
          en: 'Changes',
          fr: 'Modifications',
          es: 'Cambios',
        ),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: _studentCopy(
            de: 'Alle als gelesen markieren',
            en: 'Mark all as read',
            fr: 'Tout marquer comme lu',
            es: 'Marcar todo como leído',
          ),
          onPressed: _changes?.any((entry) => !entry.isRead) == true
              ? _markRead
              : null,
          icon: const Icon(Icons.done_all_rounded),
        ),
      ],
    ),
    body: _AnimatedBackground(
      child: _changes == null
          ? const Center(child: CircularProgressIndicator())
          : _changes!.isEmpty
          ? _FeatureEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: _studentCopy(
                de: 'Keine neuen Änderungen',
                en: 'No new changes',
                fr: 'Aucune nouvelle modification',
                es: 'No hay cambios nuevos',
              ),
              message: _studentCopy(
                de: 'Nach dem nächsten Stundenplan-Update erscheinen Ausfälle, Raum- und Lehrerwechsel hier.',
                en: 'Cancellations, room, and teacher changes appear here after the next timetable update.',
                fr: 'Les annulations et changements de salle ou de professeur apparaîtront ici après la prochaine mise à jour.',
                es: 'Las cancelaciones y los cambios de aula o profesor aparecerán aquí tras la próxima actualización.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: _changes!.length,
              itemBuilder: (context, index) => _ChangeTile(_changes![index]),
            ),
    ),
  );
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.state});
  final SyncState<List<Absence>> state;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (failure == null &&
        !state.isRefreshing &&
        state.lastSuccessfulSync == null) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final isError = failure != null;
    final lastSync = state.lastSuccessfulSync;
    final failureText = switch (failure?.kind) {
      WebUntisFailureKind.offline => _studentCopy(
        de: 'Offline – der gespeicherte Stand bleibt sichtbar.',
        en: 'Offline — saved data remains visible.',
        fr: 'Hors ligne — les données enregistrées restent visibles.',
        es: 'Sin conexión — los datos guardados siguen visibles.',
      ),
      WebUntisFailureKind.timeout => _studentCopy(
        de: 'WebUntis antwortet zu langsam. Bitte erneut versuchen.',
        en: 'WebUntis is responding too slowly. Please try again.',
        fr: 'WebUntis répond trop lentement. Réessaie.',
        es: 'WebUntis responde demasiado lento. Inténtalo de nuevo.',
      ),
      WebUntisFailureKind.permission ||
      WebUntisFailureKind.unsupported => _studentCopy(
        de: 'Diese Schule oder dieses Konto stellt Abwesenheiten nicht bereit.',
        en: 'This school or account does not provide absences.',
        fr: 'Cette école ou ce compte ne fournit pas les absences.',
        es: 'Este centro o esta cuenta no ofrece ausencias.',
      ),
      null => null,
      _ => _studentCopy(
        de: 'Aktualisierung fehlgeschlagen. Der gespeicherte Stand bleibt sichtbar.',
        en: 'Update failed. Saved data remains visible.',
        fr: 'Échec de la mise à jour. Les données enregistrées restent visibles.',
        es: 'La actualización falló. Los datos guardados siguen visibles.',
      ),
    };
    final successText = lastSync == null
        ? null
        : _studentCopy(
            de: 'Zuletzt aktualisiert um ${DateFormat.Hm(_icuLocale(appLocaleNotifier.value)).format(lastSync.toLocal())}',
            en: 'Last updated at ${DateFormat.Hm(_icuLocale(appLocaleNotifier.value)).format(lastSync.toLocal())}',
            fr: 'Dernière mise à jour à ${DateFormat.Hm(_icuLocale(appLocaleNotifier.value)).format(lastSync.toLocal())}',
            es: 'Última actualización a las ${DateFormat.Hm(_icuLocale(appLocaleNotifier.value)).format(lastSync.toLocal())}',
          );
    return Material(
      color: (isError ? cs.errorContainer : cs.secondaryContainer).withValues(
        alpha: 0.8,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (state.isRefreshing)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isError
                    ? Icons.cloud_off_rounded
                    : state.isRefreshing
                    ? Icons.sync_rounded
                    : Icons.cloud_done_rounded,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                failureText ??
                    (!state.isRefreshing ? successText : null) ??
                    _studentCopy(
                      de: 'Gespeicherter Stand wird aktualisiert …',
                      en: 'Updating the saved data …',
                      fr: 'Mise à jour des données enregistrées…',
                      es: 'Actualizando los datos guardados…',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbsenceSummary extends StatelessWidget {
  const _AbsenceSummary({required this.absences});
  final List<Absence> absences;

  @override
  Widget build(BuildContext context) {
    final days = absences.map((absence) => absence.date).toSet().length;
    final excused = absences
        .where((absence) => absence.status == AbsenceStatus.excused)
        .length;
    final open = absences
        .where((absence) => absence.status == AbsenceStatus.open)
        .length;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _SummaryMetric(
              value: '$days',
              label: _studentCopy(
                de: 'Tage',
                en: 'Days',
                fr: 'Jours',
                es: 'Días',
              ),
            ),
            _SummaryMetric(
              value: '${absences.length}',
              label: _studentCopy(
                de: 'Einträge',
                en: 'Entries',
                fr: 'Entrées',
                es: 'Entradas',
              ),
            ),
            _SummaryMetric(
              value: '$excused',
              label: _studentCopy(
                de: 'Entschuldigt',
                en: 'Excused',
                fr: 'Justifiées',
                es: 'Justificadas',
              ),
            ),
            _SummaryMetric(
              value: '$open',
              label: _studentCopy(
                de: 'Offen',
                en: 'Open',
                fr: 'Ouvertes',
                es: 'Abiertas',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}

class _AbsenceTile extends StatelessWidget {
  const _AbsenceTile(this.absence);
  final Absence absence;

  @override
  Widget build(BuildContext context) {
    final dateText = absence.date.toString().padLeft(8, '0');
    final formattedDate =
        '${dateText.substring(6, 8)}.${dateText.substring(4, 6)}.${dateText.substring(0, 4)}';
    final status = switch (absence.status) {
      AbsenceStatus.excused => (
        _studentCopy(
          de: 'Entschuldigt',
          en: 'Excused',
          fr: 'Justifiée',
          es: 'Justificada',
        ),
        Icons.verified_rounded,
        Colors.green,
      ),
      AbsenceStatus.unexcused => (
        _studentCopy(
          de: 'Unentschuldigt',
          en: 'Unexcused',
          fr: 'Non justifiée',
          es: 'Sin justificar',
        ),
        Icons.error_rounded,
        Theme.of(context).colorScheme.error,
      ),
      AbsenceStatus.open => (
        _studentCopy(de: 'Offen', en: 'Open', fr: 'Ouverte', es: 'Abierta'),
        Icons.schedule_rounded,
        Colors.orange,
      ),
      AbsenceStatus.unknown => (
        _studentCopy(
          de: 'Unbekannt',
          en: 'Unknown',
          fr: 'Inconnu',
          es: 'Desconocido',
        ),
        Icons.help_rounded,
        Theme.of(context).colorScheme.outline,
      ),
    };
    return Card(
      elevation: 0,
      child: ListTile(
        minTileHeight: 72,
        leading: CircleAvatar(
          backgroundColor: status.$3.withValues(alpha: 0.14),
          child: Icon(status.$2, color: status.$3),
        ),
        title: Text(
          absence.subject.isEmpty ? formattedDate : absence.subject,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (absence.subject.isNotEmpty) formattedDate,
            '${_formatUntisTime('${absence.startTime}')}–${_formatUntisTime('${absence.endTime}')}',
            status.$1,
            if (absence.reason.isNotEmpty) absence.reason,
          ].join(' · '),
        ),
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  const _ChangeTile(this.change);
  final TimetableChange change;

  @override
  Widget build(BuildContext context) {
    final meta = switch (change.type) {
      TimetableChangeType.cancelled => (
        _studentCopy(
          de: 'Ausfall',
          en: 'Cancelled',
          fr: 'Annulé',
          es: 'Cancelada',
        ),
        Icons.event_busy_rounded,
      ),
      TimetableChangeType.restored => (
        _studentCopy(
          de: 'Findet wieder statt',
          en: 'Restored',
          fr: 'Rétabli',
          es: 'Restablecida',
        ),
        Icons.event_available_rounded,
      ),
      TimetableChangeType.room => (
        _studentCopy(
          de: 'Raumwechsel',
          en: 'Room change',
          fr: 'Changement de salle',
          es: 'Cambio de aula',
        ),
        Icons.meeting_room_rounded,
      ),
      TimetableChangeType.teacher => (
        _studentCopy(
          de: 'Lehrerwechsel',
          en: 'Teacher change',
          fr: 'Changement de professeur',
          es: 'Cambio de profesor',
        ),
        Icons.person_rounded,
      ),
      TimetableChangeType.time => (
        _studentCopy(
          de: 'Zeitänderung',
          en: 'Time change',
          fr: 'Changement d’heure',
          es: 'Cambio de hora',
        ),
        Icons.schedule_rounded,
      ),
      TimetableChangeType.subject => (
        _studentCopy(
          de: 'Fachänderung',
          en: 'Subject change',
          fr: 'Changement de matière',
          es: 'Cambio de asignatura',
        ),
        Icons.menu_book_rounded,
      ),
      TimetableChangeType.added => (
        _studentCopy(
          de: 'Neue Stunde',
          en: 'New lesson',
          fr: 'Nouveau cours',
          es: 'Nueva clase',
        ),
        Icons.add_circle_rounded,
      ),
      TimetableChangeType.removed => (
        _studentCopy(
          de: 'Stunde entfernt',
          en: 'Lesson removed',
          fr: 'Cours supprimé',
          es: 'Clase eliminada',
        ),
        Icons.remove_circle_rounded,
      ),
      TimetableChangeType.other => (
        _studentCopy(
          de: 'Änderung',
          en: 'Change',
          fr: 'Modification',
          es: 'Cambio',
        ),
        Icons.change_circle_rounded,
      ),
    };
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Badge(
          isLabelVisible: !change.isRead,
          child: CircleAvatar(child: Icon(meta.$2)),
        ),
        title: Text(
          '${meta.$1}${change.subject.isEmpty ? '' : ' · ${change.subject}'}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        subtitle: change.before != null || change.after != null
            ? Text('${change.before ?? '–'} → ${change.after ?? '–'}')
            : null,
      ),
    );
  }
}

class _FeatureEmptyState extends StatelessWidget {
  const _FeatureEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
