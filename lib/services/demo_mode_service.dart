import 'package:intl/intl.dart';

class DemoModeService {
  static const int demoPersonType = 5;
  static const int demoPersonId = 999001;

  static Map<int, List<dynamic>> buildWeek(
    DateTime monday, {
    String locale = 'en',
  }) {
    final mon = DateTime(monday.year, monday.month, monday.day);
    final tue = mon.add(const Duration(days: 1));
    final wed = mon.add(const Duration(days: 2));
    final thu = mon.add(const Duration(days: 3));
    final fri = mon.add(const Duration(days: 4));

    return {
      0: [
        _lesson(
          mon,
          800,
          845,
          'MA',
          _subjectName('MA', locale),
          'Olivia Carter',
          'A101',
        ),
        _lesson(
          mon,
          850,
          935,
          'MA',
          _subjectName('MA', locale),
          'Olivia Carter',
          'A101',
        ),
        _lesson(
          mon,
          945,
          1030,
          'DE',
          _subjectName('DE', locale),
          'Daniel Reed',
          'Language Room',
        ),
        _lesson(
          mon,
          1035,
          1120,
          'EN',
          _subjectName('EN', locale),
          'Emily Miller',
          'English Studio',
        ),
        _lesson(
          mon,
          1035,
          1120,
          'IF',
          _subjectName('IF', locale),
          'Noah Bennett',
          'Tech Lab 3',
        ),
        _lesson(
          mon,
          1130,
          1215,
          'CH',
          _subjectName('CH', locale),
          'Dr. Harper',
          'Science Lab 1',
        ),
        _lesson(
          mon,
          1225,
          1310,
          'SP',
          _subjectName('SP', locale),
          'Coach Jordan',
          'Hall 2',
        ),
        _lesson(
          mon,
          1320,
          1405,
          'GE',
          _subjectName('GE', locale),
          'Marcus Hill',
          'History Hall',
          code: 'cancelled',
        ),
      ],
      1: [
        _lesson(
          tue,
          800,
          845,
          'BI',
          _subjectName('BI', locale),
          'Sophia Nguyen',
          'Science Lab 2',
        ),
        _lesson(
          tue,
          850,
          935,
          'BI',
          _subjectName('BI', locale),
          'Sophia Nguyen',
          'Science Lab 2',
        ),
        _lesson(
          tue,
          945,
          1030,
          'PH',
          _subjectName('PH', locale),
          'Dr. Ellis',
          'A210',
        ),
        _lesson(
          tue,
          1035,
          1120,
          'FR',
          _subjectName('FR', locale),
          'Claire Dubois',
          'C205',
        ),
        _lesson(
          tue,
          1135,
          1220,
          'KU',
          _subjectName('KU', locale),
          'Ava Collins',
          'Art Studio',
        ),
        _lesson(
          tue,
          1225,
          1310,
          'MU',
          _subjectName('MU', locale),
          'Maya Brooks',
          'Music Room',
          code: 'cancelled',
        ),
      ],
      2: [
        _lesson(
          wed,
          800,
          845,
          'EN',
          _subjectName('EN', locale),
          'Emily Miller',
          'English Studio',
        ),
        _lesson(
          wed,
          850,
          935,
          'MA',
          _subjectName('MA', locale),
          'Olivia Carter',
          'A101',
        ),
        _lesson(
          wed,
          945,
          1030,
          'PH',
          _subjectName('PH', locale),
          'Dr. Ellis',
          'A210',
        ),
        _lesson(
          wed,
          1035,
          1120,
          'PH',
          _subjectName('PH', locale),
          'Dr. Ellis',
          'A210',
        ),
        _lesson(
          wed,
          1135,
          1220,
          'DE',
          _subjectName('DE', locale),
          'Daniel Reed',
          'Language Room',
        ),
        _lesson(
          wed,
          1225,
          1310,
          'GE',
          _subjectName('GE', locale),
          'Marcus Hill',
          'History Hall',
        ),
        _lesson(
          wed,
          1320,
          1405,
          'IF',
          _subjectName('IF', locale),
          'Noah Bennett',
          'Tech Lab 3',
        ),
        _lesson(
          wed,
          1320,
          1405,
          'FO',
          _subjectName('FO', locale),
          'Emma Foster',
          'C006',
        ),
        _lesson(
          wed,
          1410,
          1455,
          'CH',
          _subjectName('CH', locale),
          'Dr. Harper',
          'Science Lab 1',
          code: 'cancelled',
        ),
      ],
      3: [
        _lesson(
          thu,
          800,
          845,
          'MA',
          _subjectName('MA', locale),
          'Olivia Carter',
          'A101',
        ),
        _lesson(
          thu,
          850,
          935,
          'EN',
          _subjectName('EN', locale),
          'Emily Miller',
          'English Studio',
        ),
        _lesson(
          thu,
          945,
          1030,
          'DE',
          _subjectName('DE', locale),
          'Daniel Reed',
          'Language Room',
        ),
        _lesson(
          thu,
          1035,
          1120,
          'GE',
          _subjectName('GE', locale),
          'Marcus Hill',
          'History Hall',
        ),
        _lesson(
          thu,
          1135,
          1220,
          'SP',
          _subjectName('SP', locale),
          'Coach Jordan',
          'Athletics Field',
        ),
        _lesson(
          thu,
          1225,
          1310,
          'SP',
          _subjectName('SP', locale),
          'Coach Jordan',
          'Athletics Field',
        ),
        _lesson(
          thu,
          1320,
          1405,
          'KU',
          _subjectName('KU', locale),
          'Ava Collins',
          'Art Studio',
        ),
      ],
      4: [
        _lesson(
          fri,
          800,
          845,
          'BI',
          _subjectName('BI', locale),
          'Sophia Nguyen',
          'Science Lab 2',
        ),
        _lesson(
          fri,
          850,
          935,
          'CH',
          _subjectName('CH', locale),
          'Dr. Harper',
          'Science Lab 1',
        ),
        _lesson(
          fri,
          945,
          1030,
          'IF',
          _subjectName('IF', locale),
          'Noah Bennett',
          'Tech Lab 3',
        ),
        _lesson(
          fri,
          1035,
          1120,
          'EN',
          _subjectName('EN', locale),
          'Emily Miller',
          'English Studio',
        ),
        _lesson(
          fri,
          1135,
          1220,
          'SO',
          _subjectName('SO', locale),
          'Hannah Price',
          'Civics Room',
        ),
        _lesson(
          fri,
          1225,
          1310,
          'KL',
          _subjectName('KL', locale),
          'Daniel Reed',
          'Language Room',
          code: 'cancelled',
        ),
      ],
    };
  }

  static List<Map<String, dynamic>> demoExams() {
    final now = DateTime.now();
    final y = now.year;
    return [
      {
        'subject': 'Mathematics',
        'examType': 'Midterm Exam',
        'date': _dateInt(
          DateTime(y, now.month, now.day).add(const Duration(days: 3)),
        ),
        'description': 'Functions, derivatives, and graph analysis.',
      },
      {
        'subject': 'English Language Arts',
        'examType': 'Vocabulary Quiz',
        'date': _dateInt(
          DateTime(y, now.month, now.day).add(const Duration(days: 8)),
        ),
        'description': 'Unit 6: persuasive writing and reading comprehension.',
      },
      {
        'subject': 'Biology',
        'examType': 'Lab Assessment',
        'date': _dateInt(
          DateTime(y, now.month, now.day).add(const Duration(days: 12)),
        ),
        'description': 'Microscopy report and cell structure analysis.',
      },
    ];
  }

  /// Returns the same shape as [HomeworkService.fetchHomeworkAndNotes].
  /// Keeping demo data in the WebUntis-shaped model means every consumer uses
  /// its normal rendering and interaction path without needing an account.
  static Map<String, List<Map<String, dynamic>>> buildHomeworkAndNotes(
    DateTime monday, {
    String locale = 'de',
  }) {
    final week = buildWeek(monday, locale: locale);
    final math = Map<String, dynamic>.from(week[0]!.first as Map);
    final english = Map<String, dynamic>.from(week[2]!.first as Map);
    final chemistry = Map<String, dynamic>.from(week[4]![1] as Map);

    return {
      'homeworks': [
        {
          'id': 9001,
          'lessonId': math['id'],
          'text': 'Übung 5 auf Seite 12 bearbeiten.',
          'dueDate': math['date'],
          'isDone': false,
          '_lesson': math,
        },
        {
          'id': 9002,
          'lessonId': english['id'],
          'text': 'Die Vokabeln für die nächste Stunde wiederholen.',
          'dueDate': english['date'],
          'isDone': false,
          '_lesson': english,
        },
        {
          'id': 9003,
          'lessonId': chemistry['id'],
          'text': 'Das Laborprotokoll fertigstellen.',
          'dueDate': chemistry['date'],
          'isDone': false,
          '_lesson': chemistry,
        },
      ],
      'lessonNotes': [
        {
          'id': 9101,
          'lessonId': math['id'],
          'date': math['date'],
          'text': 'Arbeitsblatt in der Stunde ausgeteilt.',
          '_lesson': math,
        },
        {
          'id': 9102,
          'lessonId': chemistry['id'],
          'date': chemistry['date'],
          'text': 'Für den Versuch bitte Schutzbrille mitbringen.',
          '_lesson': chemistry,
        },
      ],
    };
  }

  /// Locally supplied notification payloads follow the public WebUntis
  /// response format and therefore use the standard notification mapper.
  static List<Map<String, dynamic>> demoNotifications({String locale = 'de'}) {
    final today = DateTime.now();
    return [
      {
        'id': 'demo-notice-1',
        'title': 'Willkommen bei Untis+',
        'message': 'Im Demo-Modus werden alle Funktionen mit lokalen Beispieldaten gezeigt.',
        'date': _dateInt(today),
        'author': 'Untis+',
      },
      {
        'id': 'demo-notice-2',
        'title': 'Stundenplan aktualisiert',
        'message': 'Der Chemieunterricht am Freitag findet regulär statt.',
        'date': _dateInt(today.subtract(const Duration(days: 1))),
        'author': 'Sekretariat',
      },
    ];
  }

  static List<Map<String, dynamic>> demoClasses() => const [
        {'id': 999001, 'name': 'Demo 10A', 'longName': 'Demo-Klasse 10A'},
        {'id': 999002, 'name': 'Demo 10B', 'longName': 'Demo-Klasse 10B'},
        {'id': 999003, 'name': 'Demo Q1', 'longName': 'Demo-Jahrgang Q1'},
      ];

  static List<String> demoFreeRooms(int rangeIndex) {
    const rooms = [
      ['A102', 'B201', 'Bibliothek'],
      ['A102', 'C104', 'Medienraum'],
      ['B201', 'Sporthalle klein'],
      ['C104', 'Musikraum'],
    ];
    return List<String>.from(rooms[rangeIndex % rooms.length]);
  }

  static Map<String, dynamic> _lesson(
    DateTime date,
    int startTime,
    int endTime,
    String subjectShort,
    String subjectLong,
    String teacher,
    String room, {
    String code = '',
  }) {
    final id = _dateInt(date) * 10000 + startTime;
    return {
      'id': id,
      'lsid': id,
      'date': _dateInt(date),
      'startTime': startTime,
      'endTime': endTime,
      '_subjectShort': subjectShort,
      '_subjectLong': subjectLong,
      '_teacher': teacher,
      '_room': room,
      'su': [
        {'name': subjectShort, 'longname': subjectLong},
      ],
      'code': code,
      'lstext': startTime == 800 ? 'Please bring your textbooks.' : '',
      'homework': startTime == 800 ? 'Complete exercise 5 on page 12.' : '',
    };
  }

  static int _dateInt(DateTime date) {
    return int.parse(DateFormat('yyyyMMdd').format(date));
  }

  static String _subjectName(String code, String locale) {
    final normalized = locale.toLowerCase();
    final lang = const {'de', 'en', 'fr', 'es', 'el'}.contains(normalized)
        ? normalized
        : 'de';

    const map = <String, Map<String, String>>{
      'MA': {
        'de': 'Mathematik',
        'en': 'Mathematics',
        'fr': 'Mathematiques',
        'es': 'Matematicas',
        'el': 'Μαθηματικά',
      },
      'DE': {
        'de': 'Deutsch',
        'en': 'German Language',
        'fr': 'Allemand',
        'es': 'Aleman',
        'el': 'Γερμανικά',
      },
      'EN': {
        'de': 'Englisch',
        'en': 'English Language Arts',
        'fr': 'Anglais',
        'es': 'Ingles',
        'el': 'Αγγλικά',
      },
      'IF': {
        'de': 'Informatik',
        'en': 'Computer Science',
        'fr': 'Informatique',
        'es': 'Informatica',
        'el': 'Πληροφορική',
      },
      'CH': {
        'de': 'Chemie',
        'en': 'Chemistry',
        'fr': 'Chimie',
        'es': 'Quimica',
        'el': 'Χημεία',
      },
      'SP': {
        'de': 'Sport',
        'en': 'Physical Education',
        'fr': 'Sport',
        'es': 'Educacion Fisica',
        'el': 'Γυμναστική',
      },
      'GE': {
        'de': 'Geschichte',
        'en': 'History',
        'fr': 'Histoire',
        'es': 'Historia',
        'el': 'Ιστορία',
      },
      'BI': {
        'de': 'Biologie',
        'en': 'Biology',
        'fr': 'Biologie',
        'es': 'Biologia',
        'el': 'Βιολογία',
      },
      'PH': {
        'de': 'Physik',
        'en': 'Physics',
        'fr': 'Physique',
        'es': 'Fisica',
        'el': 'Φυσική',
      },
      'FR': {
        'de': 'Franzosisch',
        'en': 'French',
        'fr': 'Francais',
        'es': 'Frances',
        'el': 'Γαλλικά',
      },
      'KU': {
        'de': 'Kunst',
        'en': 'Art',
        'fr': 'Arts plastiques',
        'es': 'Arte',
        'el': 'Καλλιτεχνικά',
      },
      'MU': {
        'de': 'Musik',
        'en': 'Music',
        'fr': 'Musique',
        'es': 'Musica',
        'el': 'Μουσική',
      },
      'FO': {
        'de': 'Forderung',
        'en': 'Enrichment Seminar',
        'fr': 'Approfondissement',
        'es': 'Refuerzo Avanzado',
        'el': 'Ενισχυτική Διδασκαλία',
      },
      'SO': {
        'de': 'Sozialkunde',
        'en': 'Social Studies',
        'fr': 'Sciences sociales',
        'es': 'Ciencias Sociales',
        'el': 'Κοινωνικές Επιστήμες',
      },
      'KL': {
        'de': 'Klassenleiterstunde',
        'en': 'Advisory Period',
        'fr': 'Heure de professeur principal',
        'es': 'Hora de tutor',
        'el': 'Ώρα υπευθύνου τμήματος',
      },
    };

    return map[code]?[lang] ?? map[code]?['de'] ?? code;
  }
}
