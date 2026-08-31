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
  }

  Future<void> _loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('customGrades') ?? [];
    setState(() {
      _grades = raw.map((e) => _Grade.fromJson(jsonDecode(e))).toList();
      _loading = false;
    });
  }

  Future<void> _saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'customGrades',
      _grades.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void showAddGradeDialog([_Grade? existing]) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    String selectedSubject = existing?.subject ??
        (knownSubjectsNotifier.value.isNotEmpty
            ? knownSubjectsNotifier.value.first
            : '');
    final valueController =
        TextEditingController(text: existing?.value.toString() ?? '');
    final weightController =
        TextEditingController(text: existing?.weight.toString() ?? '1.0');
    final typeController = TextEditingController(text: existing?.type ?? '');
    DateTime selectedDate = existing?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: _kBottomSheetAnimationStyle,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _glassContainer(
            context: ctx,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    existing == null ? l.gradesAddTitle : l.gradesEditTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: knownSubjectsNotifier.value.contains(selectedSubject)
                        ? selectedSubject
                        : null,
                    decoration: InputDecoration(
                      labelText: l.gradesSubjectLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: knownSubjectsNotifier.value
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDlg(() => selectedSubject = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: valueController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: l.gradesGradeLabel,
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: l.gradesWeightLabel,
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: l.gradesTypeLabel,
                      hintText: "z.B. Klausur, Mündlich...",
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd.MM.yyyy').format(selectedDate),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (existing != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _grades
                                  .removeWhere((g) => g.id == existing.id));
                              _saveGrades();
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.error,
                              side: BorderSide(color: cs.error),
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(l.examsDelete,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      if (existing != null) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            final val =
                                double.tryParse(valueController.text) ?? 0;
                            final weight =
                                double.tryParse(weightController.text) ?? 1.0;
                            if (val == 0 || selectedSubject.isEmpty) return;

                            final newGrade = _Grade(
                              id: existing?.id ??
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                              subject: selectedSubject,
                              value: val,
                              weight: weight,
                              type: typeController.text,
                              date: selectedDate,
                            );

                            setState(() {
                              if (existing != null) {
                                final idx = _grades
                                    .indexWhere((g) => g.id == existing.id);
                                _grades[idx] = newGrade;
                              } else {
                                _grades.add(newGrade);
                              }
                            });
                            _saveGrades();
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(l.examsSave,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subj = subjects[index];
                    final subjGrades = grouped[subj]!
                      ..sort((a, b) => b.date.compareTo(a.date));
                    final avg = _calculateAverage(subjGrades);
                    return _buildSubjectCard(cs, subj, subjGrades, avg);
                  },
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, AppL10n l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined,
              size: 80, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(l.gradesNone,
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(l.gradesNoneHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
      ColorScheme cs, String subject, List<_Grade> grades, double average) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _autoLessonColor(subject, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: color.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        subject.isNotEmpty ? subject[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "${grades.length} Noten",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      average.toStringAsFixed(2),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: color,
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
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final g = grades[index];
                return ListTile(
                  onTap: () => showAddGradeDialog(g),
                  title: Row(
                    children: [
                      Text(
                        g.value.toString(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.type.isNotEmpty ? g.type : "Note",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (g.weight != 1.0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "w=${g.weight}",
                            style: GoogleFonts.outfit(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    DateFormat('dd.MM.yyyy').format(g.date),
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
