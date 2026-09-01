part of '../main.dart';

class GradesTrackerPage extends StatefulWidget {
  const GradesTrackerPage({super.key});

  @override
  State<GradesTrackerPage> createState() => _GradesTrackerPageState();
}

class _Grade {
  final String id;
  final String subject;
  final double value;
  final double weight;
  final String type;
  final DateTime date;

  _Grade({
    required this.id,
    required this.subject,
    required this.value,
    required this.weight,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'value': value,
        'weight': weight,
        'type': type,
        'date': date.toIso8601String(),
      };

  factory _Grade.fromJson(Map<String, dynamic> json) => _Grade(
        id: json['id'],
        subject: json['subject'],
        value: (json['value'] as num).toDouble(),
        weight: (json['weight'] as num).toDouble(),
        type: json['type'] ?? '',
        date: DateTime.parse(json['date']),
      );
}

class _GradesTrackerPageState extends State<GradesTrackerPage> {
  List<_Grade> _grades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
    customGradesNotifier.addListener(_onCustomGradesChanged);
  }

  @override
  void dispose() {
    customGradesNotifier.removeListener(_onCustomGradesChanged);
    super.dispose();
  }

  void _onCustomGradesChanged() {
    if (!mounted) return;
    setState(() {
      _grades = customGradesNotifier.value
          .map((e) => _Grade.fromJson(e))
          .toList();
    });
  }

  Future<void> _loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('customGrades') ?? [];
    final loaded = raw.map((e) => _Grade.fromJson(jsonDecode(e))).toList();
    setState(() {
      _grades = loaded;
      _loading = false;
    });
    customGradesNotifier.value = loaded.map((e) => e.toJson()).toList();
  }

  Future<void> _saveGrades() async {
    await saveCustomGrades(_grades.map((e) => e.toJson()).toList());
  }

  void showAddGradeDialog([dynamic subjectOrGrade, _Grade? existing]) {
    String? initialSubject;
    _Grade? grade;
    if (subjectOrGrade is String) {
      initialSubject = subjectOrGrade;
      grade = existing;
    } else if (subjectOrGrade is _Grade) {
      grade = subjectOrGrade;
    }

    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    String selectedSubject = (initialSubject?.isNotEmpty == true ? initialSubject! : null) ??
        grade?.subject ??
        (knownSubjectsNotifier.value.isNotEmpty
            ? knownSubjectsNotifier.value.first
            : '');
    final valueController =
        TextEditingController(text: grade?.value.toString() ?? '');
    final weightController =
        TextEditingController(text: grade?.weight.toString() ?? '1.0');
    final typeController = TextEditingController(text: grade?.type ?? '');
    final subjectController = TextEditingController(text: selectedSubject);
    DateTime selectedDate = grade?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final double? previewValue = double.tryParse(valueController.text.replaceAll(',', '.'));
          final Color previewColor = previewValue != null 
              ? _colorForGrade(previewValue)
              : cs.primary;
          final subjects = knownSubjectsNotifier.value.toList()..sort();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: _glassContainer(
              context: ctx,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                existing == null ? l.gradesAddTitle : l.gradesEditTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                l.gradesAddDesc,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (previewValue != null)
                          _springEntry(
                            key: ValueKey(previewValue),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: previewColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: previewColor.withValues(alpha: 0.4), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  previewValue.toString().replaceAll('.0', ''),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    color: previewColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l.gradesSubjectLabel.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (subjects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: subjects.contains(selectedSubject)
                            ? selectedSubject
                            : null,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.book_rounded),
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: subjects
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setDlg(() {
                            selectedSubject = v ?? '';
                            subjectController.text = selectedSubject;
                          });
                        },
                      )
                    else
                      TextField(
                        controller: subjectController,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.book_rounded),
                          hintText: "z.B. Mathematik",
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.gradesGradeLabel.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: valueController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDlg(() {}),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.star_rounded),
                                  filled: true,
                                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.gradesWeightLabel.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.scale_rounded),
                                  filled: true,
                                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.gradesTypeLabel.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: typeController,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.label_important_rounded),
                        hintText: "z.B. Klausur, Mündlich...",
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "DATUM",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setDlg(() => selectedDate = picked);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd. MMMM yyyy', _icuLocale(appLocaleNotifier.value)).format(selectedDate),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        if (existing != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _grades.removeWhere((g) => g.id == existing.id));
                                _saveGrades();
                                Navigator.pop(ctx);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                                side: BorderSide(color: cs.error.withValues(alpha: 0.5), width: 1.5),
                                minimumSize: const Size(0, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        if (existing != null) const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: FilledButton(
                            onPressed: () {
                              final val = double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0;
                              final weight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 1.0;
                              final subj = subjectController.text.trim();
                              if (val <= 0 || subj.isEmpty) return;

                              final newGrade = _Grade(
                                id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                subject: subj,
                                value: val,
                                weight: weight,
                                type: typeController.text,
                                date: selectedDate,
                              );

                              setState(() {
                                if (existing != null) {
                                  final idx = _grades.indexWhere((g) => g.id == existing.id);
                                  _grades[idx] = newGrade;
                                } else {
                                  _grades.add(newGrade);
                                }
                              });
                              _saveGrades();
                              Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 8,
                              shadowColor: cs.primary.withValues(alpha: 0.4),
                            ),
                            child: Text(
                              existing == null ? l.examsSave : "Änderungen speichern",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, List<_Grade>> get _groupedGrades {
    final map = <String, List<_Grade>>{};
    for (var g in _grades) {
      (map[g.subject] ??= []).add(g);
    }
    return map;
  }

  double _calculateAverage(List<_Grade> grades) {
    if (grades.isEmpty) return 0;
    double sum = 0;
    double weightSum = 0;
    for (var g in grades) {
      sum += g.value * g.weight;
      weightSum += g.weight;
    }
    return sum / weightSum;
  }

  double get _overallAverage {
    if (_grades.isEmpty) return 0;
    return _calculateAverage(_grades);
  }

  Color _colorForGrade(double value) {
    if (value <= 1.5) return const Color(0xFF4CAF50);
    if (value <= 2.5) return const Color(0xFF8BC34A);
    if (value <= 3.5) return const Color(0xFFFFC107);
    if (value <= 4.5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupedGrades;
    final subjects = grouped.keys.toList()..sort();

    return _AnimatedBackground(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grades.isEmpty
              ? _buildEmptyState(cs, l)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // Stats
                          _buildStatBadge(
                            cs,
                            l.gradesAverage,
                            _overallAverage.toStringAsFixed(2),
                            Icons.analytics_rounded,
                            _colorForGrade(_overallAverage),
                          ),
                          const SizedBox(width: 8),
                          _buildStatBadge(
                            cs,
                            l.gradesTotal,
                            _grades.length.toString(),
                            Icons.numbers_rounded,
                            cs.primary,
                          ),
                          
                          // Best Subject (if any)
                          ...(() {
                            final grouped = _groupedGrades;
                            if (grouped.length < 2) return <Widget>[];
                            String bestSubject = "";
                            double bestAvg = 99;
                            grouped.forEach((s, g) {
                              final a = _calculateAverage(g);
                              if (a < bestAvg) {
                                bestAvg = a;
                                bestSubject = s;
                              }
                            });
                            if (bestSubject.isEmpty) return <Widget>[];
                            return [
                              const SizedBox(width: 8),
                              _buildStatBadge(
                                cs,
                                l.gradesBestSubject,
                                bestSubject,
                                Icons.workspace_premium_rounded,
                                Colors.amber,
                              ),
                            ];
                          })(),

                          // Subject quick filters
                          if (subjects.length > 2) ...[
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 16,
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 16),
                            ...subjects.map((s) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              final color = _autoLessonColor(s, isDark);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _glassContainer(
                                  context: context,
                                  borderRadius: BorderRadius.circular(12),
                                  color: color.withValues(alpha: 0.1),
                                  border: Border.all(color: color.withValues(alpha: 0.2)),
                                  child: InkWell(
                                    onTap: () => HapticFeedback.selectionClick(),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.book_rounded, size: 13, color: color),
                                          const SizedBox(width: 6),
                                          Text(
                                            s,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                              color: isDark ? color.withValues(alpha: 0.9) : color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...subjects.asMap().entries.map((entry) {
                      final index = entry.key;
                      final subj = entry.value;
                      final subjGrades = grouped[subj]!
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final avg = _calculateAverage(subjGrades);
                      return _springEntry(
                        key: ValueKey('grade_subject_$subj'),
                        duration: Duration(milliseconds: 400 + (index * 80)),
                        offsetY: 20,
                        child: _buildSubjectCard(cs, subj, subjGrades, avg),
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildStatBadge(
      ColorScheme cs, String label, String value, IconData icon, Color color) {
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(12),
      color: cs.surfaceContainerLow.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              "$label: ",
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, AppL10n l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l.gradesNone,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.gradesNoneHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () => showAddGradeDialog(),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l.gradesAddTitle,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
      ColorScheme cs, String subject, List<_Grade> grades, double average) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _autoLessonColor(subject, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        subject.isNotEmpty ? subject[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          grades.length == 1 ? "1 Note" : "${grades.length} ${l.gradesCountPlural}",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _glassContainer(
                    context: context,
                    borderRadius: BorderRadius.circular(16),
                    color: color.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        average.toStringAsFixed(2),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grades.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 24,
                endIndent: 24,
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final g = grades[index];
                final gradeColor = _colorForGrade(g.value);
                return Dismissible(
                  key: Key(g.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.8),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => _grades.removeWhere((item) => item.id == g.id));
                    _saveGrades();
                    HapticFeedback.mediumImpact();
                  },
                  child: ListTile(
                    onTap: () => showAddGradeDialog(g),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: gradeColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          g.value.toString().replaceAll('.0', ''),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: gradeColor,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.type.isNotEmpty ? g.type : "Einzelnote",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (g.weight != 1.0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                            "${l.gradesWeightLabelShort}: ${g.weight}",
                            style: GoogleFonts.outfit(
                                fontSize: 11, fontWeight: FontWeight.w800, color: cs.primary),
                          ),
                          ),
                      ],
                    ),
                      subtitle: Text(
                      DateFormat('dd. MMMM yyyy', _icuLocale(appLocaleNotifier.value)).format(g.date),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Icon(Icons.edit_note_rounded, size: 22, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
