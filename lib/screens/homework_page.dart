part of '../main.dart';

// --- HAUSAUFGABEN & PRÜFUNGEN ---

Widget _chip(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: fg,
    ),
  ),
);

List<DateTime> _findSubjectDates(String subject) {
  if (subject.isEmpty) return [];
  final week = currentWeekDataNotifier.value;
  final dates = <DateTime>{};
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
    final lessons = week[dayIndex] ?? [];
    for (final l in lessons) {
      final sShort = l['_subjectShort']?.toString() ?? '';
      final sLong = l['_subjectLong']?.toString() ?? '';
      if (sShort == subject || sLong == subject || l['subject'] == subject) {
        final dStr = l['date']?.toString() ?? '';
        if (dStr.length == 8) {
          final date = DateTime.parse(
            '${dStr.substring(0, 4)}-${dStr.substring(4, 6)}-${dStr.substring(6, 8)}',
          );
          if (!date.isBefore(today)) {
            dates.add(date);
          }
        }
      }
    }
  }
  final list = dates.toList()..sort();
  return list.take(4).toList();
}

Future<void> _showAddHomeworkDialog(
  BuildContext context, {
  Map<String, dynamic>? existing,
  int? editIndex,
  String? initialSubject,
}) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  String selectedSubject =
      (initialSubject?.isNotEmpty == true ? initialSubject! : null) ??
      existing?['subject']?.toString() ??
      (knownSubjectsNotifier.value.isNotEmpty
          ? knownSubjectsNotifier.value.first
          : '');
  final subjectCtrl = TextEditingController(text: selectedSubject);
  final taskCtrl = TextEditingController(
    text:
        existing?['text']?.toString() ??
        existing?['description']?.toString() ??
        '',
  );
  DateTime selectedDate = () {
    final s =
        existing?['dueDate']?.toString() ?? existing?['date']?.toString() ?? '';
    if (s.length == 8) {
      try {
        return DateTime.parse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
        );
      } catch (_) {}
    }
    return DateTime.now().add(const Duration(days: 1));
  }();

  await showUntisModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) {
        final cs = Theme.of(ctx).colorScheme;
        final subjects = knownSubjectsNotifier.value.toList()..sort();
        if (selectedSubject.isNotEmpty && !subjects.contains(selectedSubject)) {
          subjects.add(selectedSubject);
          subjects.sort();
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _sheetSurface(
            context: ctx,
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
                              existing == null
                                  ? l.homeworkAddTitle
                                  : l.homeworkEditTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              l.homeworkAddDesc,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.assignment_rounded,
                            color: cs.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l.homeworkSubjectLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (subjects.isNotEmpty)
                    _m3SelectionMenu(
                      context: ctx,
                      value: selectedSubject,
                      entries: subjects,
                      icon: Icons.book_rounded,
                      onSelected: (value) => setDlg(() {
                        selectedSubject = value;
                        subjectCtrl.text = selectedSubject;
                      }),
                    )
                  else
                    TextField(
                      controller: subjectCtrl,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.book_rounded),
                        hintText: l.homeworkSubjectLabel,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l.homeworkTaskLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: taskCtrl,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.assignment_rounded),
                      ),
                      hintText: l.homeworkTaskLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.homeworkDueDateLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final suggested = _findSubjectDates(selectedSubject);
                      if (suggested.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggested.map((d) {
                              final isSelected =
                                  d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    DateFormat(
                                      'E, dd.MM.',
                                      appLocaleNotifier.value,
                                    ).format(d),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setDlg(() => selectedDate = d);
                                  },
                                  selectedColor: cs.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlg(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat(
                              'dd. MMMM yyyy',
                              _icuLocale(appLocaleNotifier.value),
                            ).format(selectedDate),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (existing != null && editIndex != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final list = List<Map<String, dynamic>>.from(
                                customHomeworkNotifier.value,
                              );
                              if (editIndex >= 0 && editIndex < list.length) {
                                list.removeAt(editIndex);
                                await saveCustomHomework(list);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.error,
                              side: BorderSide(
                                color: cs.error.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              minimumSize: const Size(0, 60),
                            ),
                            child: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      if (existing != null && editIndex != null)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: FilledButton(
                          onPressed: () async {
                            final subj = subjectCtrl.text.trim();
                            final text = taskCtrl.text.trim();
                            if (subj.isEmpty || text.isEmpty) return;
                            final dateInt = int.parse(
                              DateFormat('yyyyMMdd').format(selectedDate),
                            );
                            final list = List<Map<String, dynamic>>.from(
                              customHomeworkNotifier.value,
                            );
                            final item = <String, dynamic>{
                              'id':
                                  existing?['id'] ??
                                  'hw_${DateTime.now().millisecondsSinceEpoch}',
                              'subject': subj,
                              'text': text,
                              'dueDate': dateInt,
                              'isDone': existing?['isDone'] ?? false,
                              '_custom': true,
                            };
                            if (editIndex != null &&
                                editIndex >= 0 &&
                                editIndex < list.length) {
                              list[editIndex] = item;
                            } else {
                              list.add(item);
                            }
                            await saveCustomHomework(list);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 60),
                          ),
                          child: Text(
                            l.homeworkSave,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _importHomeworkWithAI(BuildContext context) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  final providerUsesGeminiProtocol = _providerUsesGeminiProtocolGlobal();
  final provider = _normalizeAiProvider(aiProvider);
  final isLocalProvider = provider == 'local';
  if (!isLocalProvider && _activeAiApiKey().trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_providerAwareMissingApiKeyMessage(l, provider))),
    );
    return;
  }

  final source = await _showUnifiedOptionSheet<String>(
    context: context,
    title: l.homeworkImportTitle,
    options: [
      _SheetOption(
        value: 'camera',
        title: l.examsImportCamera,
        icon: Icons.camera_alt_rounded,
      ),
      _SheetOption(
        value: 'gallery',
        title: l.examsImportGallery,
        icon: Icons.image_rounded,
      ),
      _SheetOption(
        value: 'file',
        title: l.examsImportFile,
        icon: Icons.picture_as_pdf_rounded,
      ),
    ],
  );

  if (source == null) return;

  Uint8List? fileBytes;
  String? mimeType;

  if (source == 'camera' || source == 'gallery') {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null) return;
    fileBytes = await picked.readAsBytes();
    mimeType = picked.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
  } else {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: providerUsesGeminiProtocol
          ? ['pdf', 'png', 'jpg', 'jpeg']
          : ['png', 'jpg', 'jpeg'],
    );
    if (picked == null) return;
    fileBytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    mimeType = ext == 'pdf'
        ? 'application/pdf'
        : (ext == 'png' ? 'image/png' : 'image/jpeg');
  }

  if (!context.mounted) return;

  var loadingVisible = true;
  showUntisDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final prompt = l.uiFormat('aiHomeworkVisionPrompt', {
      'fileKind': providerUsesGeminiProtocol ? l.ui('aiFileKindPdf') : '',
    });

    final text = await _requestAiVisionAnalysisGlobal(
      prompt: prompt,
      fileBytes: fileBytes,
      mimeType: mimeType,
    );

    if (!context.mounted) return;
    if (loadingVisible) {
      Navigator.pop(context);
      loadingVisible = false;
    }

    final jsonStart = text.indexOf('[');
    final jsonEnd = text.lastIndexOf(']');
    if (jsonStart != -1 && jsonEnd != -1) {
      final jsonStr = text.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) throw Exception(l.examsImportInvalidJson);

      final items = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final current = List<Map<String, dynamic>>.from(
        customHomeworkNotifier.value,
      );
      for (var e in items) {
        current.add({
          'id': 'hw_${DateTime.now().millisecondsSinceEpoch}_${current.length}',
          'subject': e['subject']?.toString() ?? 'Unbekannt',
          'text': e['text']?.toString() ?? '',
          'dueDate': (e['dueDate']?.toString() ?? '').replaceAll('-', ''),
          'isDone': false,
          '_custom': true,
        });
      }
      await saveCustomHomework(current);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.homeworkImportSuccess)));
    } else {
      throw Exception(l.examsImportInvalidJson);
    }
  } catch (e) {
    if (!context.mounted) return;
    if (loadingVisible) {
      Navigator.pop(context);
      loadingVisible = false;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l.homeworkImportError}$e')));
  }
}

bool _providerUsesGeminiProtocolGlobal() {
  final provider = _normalizeAiProvider(aiProvider);
  if (provider == 'gemini') return true;
  if (provider == 'custom') {
    return _normalizeAiCustomCompatibility(aiCustomCompatibility) == 'gemini';
  }
  return false;
}

Future<String> _requestAiVisionAnalysisGlobal({
  required String prompt,
  required Uint8List fileBytes,
  required String mimeType,
}) async {
  final l = AppL10n.of(appLocaleNotifier.value);
  final provider = _normalizeAiProvider(aiProvider);
  final apiKey = _activeAiApiKey().trim();
  if (apiKey.isEmpty) {
    throw Exception(
      'CONFIG: ${_providerAwareMissingApiKeyMessage(l, provider)}',
    );
  }

  final model = aiModel.trim().isNotEmpty
      ? aiModel.trim()
      : _defaultModelForProvider(
          provider,
          customCompatibility: aiCustomCompatibility,
        );

  if (provider == 'gemini') {
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
    final endpointUri = Uri.parse(endpoint);
    final mergedParams = Map<String, String>.from(endpointUri.queryParameters)
      ..putIfAbsent('key', () => apiKey);
    final uri = endpointUri.replace(queryParameters: mergedParams);

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(fileBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 2200},
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final candidates = decoded['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = candidates.first['content']?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        return parts.map((p) => p['text']?.toString() ?? '').join();
      }
    }
    throw Exception(l.aiNoReply);
  }

  throw Exception('Unsupported provider for vision: $provider');
}

class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: RoundedBlurAppBar(
        title: Text(
          l.homeworkTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddHomeworkDialog(context),
            tooltip: l.homeworkAddTitle,
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            onPressed: () => _importHomeworkWithAI(context),
            tooltip: l.homeworkActionImport,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _AnimatedBackground(child: const SizedBox.expand()),
          ),
          const Positioned.fill(child: _HomeworkView()),
        ],
      ),
    );
  }
}

class _HomeworkView extends StatefulWidget {
  const _HomeworkView();

  @override
  State<_HomeworkView> createState() => _HomeworkViewState();
}

class _HomeworkViewState extends State<_HomeworkView> {
  int _filterIndex = 0; // 0 = Alle, 1 = Offen, 2 = Bald, 3 = Erledigt

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: homeworksNotifier,
      builder: (context, apiHw, _) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: customHomeworkNotifier,
          builder: (context, customHw, _) {
            final allItems = <Map<String, dynamic>>[];

            for (final hw in apiHw) {
              final id = hw['id']?.toString() ?? '';
              final subject =
                  hw['_lesson']?['su']?.first?['longname'] ??
                  hw['_lesson']?['su']?.first?['name'] ??
                  'Unbekannt';
              allItems.add({
                'id': id,
                'subject': subject,
                'text': hw['text'] ?? '',
                'dueDate': hw['dueDate'] ?? hw['date'] ?? 0,
                'isDone': (hw['isDone'] == true) || (hw['_done'] == true),
                '_source': 'untis',
                '_raw': hw,
              });
            }

            for (final hw in customHw) {
              allItems.add({
                'id': hw['id']?.toString() ?? '',
                'subject': hw['subject'] ?? 'Unbekannt',
                'text': hw['text'] ?? hw['description'] ?? '',
                'dueDate': hw['dueDate'] ?? hw['date'] ?? 0,
                'isDone': hw['isDone'] == true,
                '_source': 'custom',
                '_raw': hw,
              });
            }

            allItems.sort((a, b) {
              final aOpen = a['isDone'] != true ? 0 : 1;
              final bOpen = b['isDone'] != true ? 0 : 1;
              if (aOpen != bOpen) return aOpen.compareTo(bOpen);
              final da = int.tryParse(a['dueDate'].toString()) ?? 0;
              final db = int.tryParse(b['dueDate'].toString()) ?? 0;
              return da.compareTo(db);
            });

            final openItems = allItems
                .where((e) => e['isDone'] != true)
                .toList();
            final doneItems = allItems
                .where((e) => e['isDone'] == true)
                .toList();
            final dueSoonItems = openItems.where((entry) {
              final dueDate = int.tryParse(entry['dueDate'].toString()) ?? 0;
              return isHomeworkDueSoon(dueDate);
            }).toList();

            final filtered = _filterIndex == 1
                ? openItems
                : _filterIndex == 2
                ? dueSoonItems
                : (_filterIndex == 3 ? doneItems : allItems);

            return ExpressiveRefreshIndicator(
              onRefresh: () async {
                final requestAccountId = activeUntisAccountId;
                final account = activeUntisAccount;
                final res = demoModeNotifier.value
                    ? DemoModeService.buildHomeworkAndNotes(
                        resolveDefaultTimetableMonday(DateTime.now()),
                        locale: appLocaleNotifier.value,
                      )
                    : await HomeworkService.fetchHomeworkAndNotes(
                        schoolUrl: schoolUrl,
                        schoolName: schoolName,
                        sessionId: sessionID,
                        personId: personId,
                        personType: personType,
                        accountId: activeUntisAccountId,
                        account: account == null
                            ? null
                            : WebUntisAccountLogin(
                                accountId: account.id,
                                username: account.username,
                                schoolUrl: account.schoolUrl,
                                schoolName: account.schoolName,
                                personId: account.personId,
                                personType: account.personType,
                              ),
                      );
                if (requestAccountId != activeUntisAccountId) return;
                homeworksNotifier.value = res['homeworks']!;
                lessonNotesNotifier.value = res['lessonNotes']!;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  _buildHomeworkSummaryCard(
                    context,
                    cs,
                    openCount: openItems.length,
                    dueSoonCount: dueSoonItems.length,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _filterChip(
                          context,
                          cs,
                          '${l.homeworkFilterAll} (${allItems.length})',
                          Icons.clear_all_rounded,
                          0,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          context,
                          cs,
                          '${l.homeworkFilterOpen} (${openItems.length})',
                          Icons.radio_button_unchecked_rounded,
                          1,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          context,
                          cs,
                          '${_studentCopy(de: 'Bald fällig', en: 'Due soon', fr: 'Bientôt dues', es: 'Próximas')} (${dueSoonItems.length})',
                          Icons.upcoming_rounded,
                          2,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          context,
                          cs,
                          '${l.homeworkFilterDone} (${doneItems.length})',
                          Icons.check_circle_rounded,
                          3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 56,
                              color: cs.primary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.homeworkNone,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.homeworkNoneHint,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...filtered.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final hw = entry.value;
                      return _springEntry(
                        key: ValueKey('hw_${hw['id']}_$idx'),
                        duration: Duration(milliseconds: 380 + idx * 60),
                        offsetY: 24,
                        startScale: 0.94,
                        curve: _kSmoothBounce,
                        child: _buildHomeworkCard(context, cs, l, hw),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(
    BuildContext context,
    ColorScheme cs,
    String label,
    IconData icon,
    int index,
  ) {
    final selected = _filterIndex == index;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(14),
      color: selected
          ? cs.primary
          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      border: Border.all(
        color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
        width: 1,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterIndex = index);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkSummaryCard(
    BuildContext context,
    ColorScheme cs, {
    required int openCount,
    required int dueSoonCount,
  }) {
    final title = _studentCopy(
      de: openCount == 1 ? '1 offene Aufgabe' : '$openCount offene Aufgaben',
      en: openCount == 1 ? '1 open task' : '$openCount open tasks',
      fr: openCount == 1 ? '1 tâche ouverte' : '$openCount tâches ouvertes',
      es: openCount == 1 ? '1 tarea pendiente' : '$openCount tareas pendientes',
    );
    final detail = dueSoonCount == 0
        ? _studentCopy(
            de: 'Nichts ist bald fällig',
            en: 'Nothing is due soon',
            fr: 'Rien n’est bientôt dû',
            es: 'No hay nada próximo',
          )
        : _studentCopy(
            de: dueSoonCount == 1
                ? '1 Aufgabe ist bald fällig'
                : '$dueSoonCount Aufgaben sind bald fällig',
            en: dueSoonCount == 1
                ? '1 task is due soon'
                : '$dueSoonCount tasks are due soon',
            fr: dueSoonCount == 1
                ? '1 tâche est bientôt due'
                : '$dueSoonCount tâches sont bientôt dues',
            es: dueSoonCount == 1
                ? '1 tarea vence pronto'
                : '$dueSoonCount tareas vencen pronto',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _glowShadows(context, [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.upcoming_rounded,
                          size: 13,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(
    BuildContext context,
    ColorScheme cs,
    AppL10n l,
    Map<String, dynamic> hw,
  ) {
    final isDone = hw['isDone'] == true;
    final isCustom = hw['_source'] == 'custom';
    final subject = hw['subject']?.toString() ?? 'Unbekannt';
    final text = hw['text']?.toString() ?? '';
    final dueDateRaw = hw['dueDate']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _autoLessonColor(subject, isDark);

    String formatDate(String d) {
      if (d.length != 8) return d;
      return '${d.substring(6, 8)}.${d.substring(4, 6)}.${d.substring(0, 4)}';
    }

    Future<void> setDone(bool value) async {
      final hwId = hw['id'];
      if (isCustom) {
        final list = customHomeworkNotifier.value
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
        final idx = list.indexWhere(
          (entry) => entry['id']?.toString() == hwId?.toString(),
        );
        if (idx != -1) {
          list[idx]['isDone'] = value;
          await saveCustomHomework(list);
        }
        return;
      }

      final numericId = int.tryParse(hwId.toString());
      if (numericId == null) return;
      await HomeworkService.toggleDone(
        numericId,
        value,
        accountId: activeUntisAccountId,
      );
      final currentApi = homeworksNotifier.value
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      for (final item in currentApi) {
        if (item['id']?.toString() == numericId.toString()) {
          item['_done'] = value;
        }
      }
      homeworksNotifier.value = currentApi;
    }

    Future<void> toggleDone() async {
      HapticFeedback.selectionClick();
      await setDone(!isDone);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            !isDone
                ? _studentCopy(
                    de: 'Aufgabe als erledigt markiert.',
                    en: 'Task marked as done.',
                    fr: 'Tâche marquée comme terminée.',
                    es: 'Tarea marcada como completada.',
                  )
                : _studentCopy(
                    de: 'Aufgabe wieder geöffnet.',
                    en: 'Task reopened.',
                    fr: 'Tâche rouverte.',
                    es: 'Tarea reabierta.',
                  ),
          ),
          action: SnackBarAction(
            label: _studentCopy(
              de: 'Rückgängig',
              en: 'Undo',
              fr: 'Annuler',
              es: 'Deshacer',
            ),
            onPressed: () => unawaited(setDone(isDone)),
          ),
        ),
      );
    }

    Future<void> openHomework() async {
      HapticFeedback.selectionClick();
      if (!isCustom) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.ui('homeworkManaged'))));
        return;
      }
      final list = List<Map<String, dynamic>>.from(
        customHomeworkNotifier.value,
      );
      final editIndex = list.indexWhere(
        (item) => item['id']?.toString() == hw['id']?.toString(),
      );
      if (editIndex == -1) return;
      await _showAddHomeworkDialog(
        context,
        existing: list[editIndex],
        editIndex: editIndex,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: isDone
            ? cs.surfaceContainerLowest.withValues(alpha: 0.35)
            : accent.withValues(alpha: isDark ? 0.14 : 0.08),
        border: Border.all(
          color: isDone
              ? cs.outlineVariant.withValues(alpha: 0.25)
              : accent.withValues(alpha: 0.4),
          width: 1.2,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: openHomework,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkResponse(
                    onTap: toggleDone,
                    radius: 22,
                    containedInkWell: true,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isDone ? cs.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDone
                              ? cs.primary
                              : accent.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow:
                            isDone &&
                                untisThemeTokensOf(context).glowEffectsEnabled
                            ? [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isDone
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: cs.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _chip(
                              subject,
                              accent.withValues(alpha: 0.2),
                              accent,
                            ),
                            if (isCustom) ...[
                              const SizedBox(width: 6),
                              _chip(
                                l.examsOwn,
                                cs.tertiaryContainer,
                                cs.tertiary,
                              ),
                            ],
                            const Spacer(),
                            if (dueDateRaw.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? cs.surfaceContainerHighest.withValues(
                                          alpha: 0.5,
                                        )
                                      : cs.primaryContainer.withValues(
                                          alpha: 0.45,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_rounded,
                                      size: 12,
                                      color: isDone
                                          ? cs.onSurfaceVariant
                                          : cs.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDate(dueDateRaw),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDone
                                            ? cs.onSurfaceVariant
                                            : cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: isDone
                                ? cs.onSurface.withValues(alpha: 0.45)
                                : cs.onSurface,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddExamDialog(
  BuildContext context, {
  Map<String, dynamic>? existing,
  int? editIndex,
  String? initialSubject,
}) async {
  String selectedSubject =
      (initialSubject?.isNotEmpty == true ? initialSubject! : null) ??
      existing?['subject']?.toString() ??
      (knownSubjectsNotifier.value.isNotEmpty
          ? knownSubjectsNotifier.value.first
          : '');
  final subjectCtrl = TextEditingController(text: selectedSubject);
  final typeCtrl = TextEditingController(
    text: existing?['examType']?.toString() ?? '',
  );
  final descCtrl = TextEditingController(
    text: existing?['description']?.toString() ?? '',
  );
  DateTime selectedDate = () {
    final s = existing?['date']?.toString() ?? '';
    if (s.length == 8) {
      try {
        return DateTime.parse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
        );
      } catch (_) {}
    }
    return DateTime.now();
  }();

  await showUntisModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) {
        final cs = Theme.of(ctx).colorScheme;
        final l = AppL10n.of(appLocaleNotifier.value);
        final subjects = knownSubjectsNotifier.value.toList()..sort();
        if (selectedSubject.isNotEmpty && !subjects.contains(selectedSubject)) {
          subjects.add(selectedSubject);
          subjects.sort();
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _sheetSurface(
            context: ctx,
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
                              existing == null
                                  ? l.examsAddTitle
                                  : l.examsEditTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              l.examsAddDesc,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit_calendar_rounded,
                            color: cs.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l.examsSubjectLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (subjects.isNotEmpty)
                    _m3SelectionMenu(
                      context: ctx,
                      value: selectedSubject,
                      entries: subjects,
                      icon: Icons.book_rounded,
                      onSelected: (value) => setDlg(() {
                        selectedSubject = value;
                        subjectCtrl.text = selectedSubject;
                      }),
                    )
                  else
                    TextField(
                      controller: subjectCtrl,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.book_rounded),
                        hintText: l.examsSubjectLabel,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l.examsTypeLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeCtrl,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.label_important_rounded),
                      hintText: l.examsTypeLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.gradesDateLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final suggested = _findSubjectDates(selectedSubject);
                      if (suggested.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggested.map((d) {
                              final isSelected =
                                  d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    DateFormat(
                                      'E, dd.MM.',
                                      appLocaleNotifier.value,
                                    ).format(d),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setDlg(() => selectedDate = d);
                                  },
                                  selectedColor: cs.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlg(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat(
                              'dd. MMMM yyyy',
                              _icuLocale(appLocaleNotifier.value),
                            ).format(selectedDate),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.examsNotesLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.notes_rounded),
                      ),
                      hintText: l.examsNotesLabel,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (existing != null && editIndex != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final list = List<Map<String, dynamic>>.from(
                                customExamsNotifier.value,
                              );
                              if (editIndex >= 0 && editIndex < list.length) {
                                list.removeAt(editIndex);
                                await saveCustomExams(list);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.error,
                              side: BorderSide(
                                color: cs.error.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              minimumSize: const Size(0, 60),
                            ),
                            child: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      if (existing != null && editIndex != null)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: FilledButton(
                          onPressed: () async {
                            final subj = subjectCtrl.text.trim();
                            if (subj.isEmpty) return;
                            final dateInt = int.parse(
                              DateFormat('yyyyMMdd').format(selectedDate),
                            );
                            final newExam = <String, dynamic>{
                              'id':
                                  existing?['id'] ??
                                  'exam_${DateTime.now().millisecondsSinceEpoch}',
                              'subject': subj,
                              'examType': typeCtrl.text.trim(),
                              'date': dateInt,
                              'description': descCtrl.text.trim(),
                              '_custom': true,
                            };
                            final list = List<Map<String, dynamic>>.from(
                              customExamsNotifier.value,
                            );
                            if (editIndex != null &&
                                editIndex >= 0 &&
                                editIndex < list.length) {
                              list[editIndex] = newExam;
                            } else {
                              list.add(newExam);
                            }
                            await saveCustomExams(list);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 60),
                          ),
                          child: Text(
                            l.examsSave,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
