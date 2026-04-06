import 'package:intl/intl.dart';

class DemoModeService {
  static const int demoPersonType = 5;
  static const int demoPersonId = 999001;

  static Map<int, List<dynamic>> buildWeek(
    DateTime monday, {
    String locale = 'de',
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
          'Frau Becker',
          'A101',
        ),
        _lesson(
          mon,
          850,
          935,
          'MA',
          _subjectName('MA', locale),
          'Frau Becker',
          'A101',
        ),
        _lesson(
          mon,
          945,
          1030,
          'DE',
          _subjectName('DE', locale),
          'Herr Lang',
          'B204',
        ),
        _lesson(
          mon,
          1035,
          1120,
          'EN',
          _subjectName('EN', locale),
          'Mrs. Miller',
          'C110',
        ),
        _lesson(
          mon,
          1035,
          1120,
          'IF',
          _subjectName('IF', locale),
          'Herr Weber',
          'IT 3',
        ),
        _lesson(
          mon,
          1130,
          1215,
          'CH',
          _subjectName('CH', locale),
          'Dr. Roth',
          'Lab 1',
        ),
        _lesson(
          mon,
          1225,
          1310,
          'SP',
          _subjectName('SP', locale),
          'Coach Ali',
          'Hall 2',
        ),
        _lesson(
          mon,
          1320,
          1405,
          'GE',
          _subjectName('GE', locale),
          'Herr Braun',
          'B018',
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
          'Frau Koch',
          'Lab 2',
        ),
        _lesson(
          tue,
          850,
          935,
          'BI',
          _subjectName('BI', locale),
          'Frau Koch',
          'Lab 2',
        ),
        _lesson(
          tue,
          945,
          1030,
          'PH',
          _subjectName('PH', locale),
          'Dr. Maier',
          'A210',
        ),
        _lesson(
          tue,
          1035,
          1120,
          'FR',
          _subjectName('FR', locale),
          'Mme Dubois',
          'C205',
        ),
        _lesson(
          tue,
          1135,
          1220,
          'KU',
          _subjectName('KU', locale),
          'Frau Stern',
          'Art 1',
        ),
        _lesson(
          tue,
          1225,
          1310,
          'MU',
          _subjectName('MU', locale),
          'Frau Vogel',
          'M012',
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
          'Mrs. Miller',
          'C110',
        ),
        _lesson(
          wed,
          850,
          935,
          'MA',
          _subjectName('MA', locale),
          'Frau Becker',
          'A101',
        ),
        _lesson(
          wed,
          945,
          1030,
          'PH',
          _subjectName('PH', locale),
          'Dr. Maier',
          'A210',
        ),
        _lesson(
          wed,
          1035,
          1120,
          'PH',
          _subjectName('PH', locale),
          'Dr. Maier',
          'A210',
        ),
        _lesson(
          wed,
          1135,
          1220,
          'DE',
          _subjectName('DE', locale),
          'Herr Lang',
          'B204',
        ),
        _lesson(
          wed,
          1225,
          1310,
          'GE',
          _subjectName('GE', locale),
          'Herr Braun',
          'B018',
        ),
        _lesson(
          wed,
          1320,
          1405,
          'IF',
          _subjectName('IF', locale),
          'Herr Weber',
          'IT 3',
        ),
        _lesson(
          wed,
          1320,
          1405,
          'FO',
          _subjectName('FO', locale),
          'Frau Otto',
          'C006',
        ),
        _lesson(
          wed,
          1410,
          1455,
          'CH',
          _subjectName('CH', locale),
          'Dr. Roth',
          'Lab 1',
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
          'Frau Becker',
          'A101',
        ),
        _lesson(
          thu,
          850,
          935,
          'EN',
          _subjectName('EN', locale),
          'Mrs. Miller',
          'C110',
        ),
        _lesson(
          thu,
          945,
          1030,
          'DE',
          _subjectName('DE', locale),
          'Herr Lang',
          'B204',
        ),
        _lesson(
          thu,
          1035,
          1120,
          'GE',
          _subjectName('GE', locale),
          'Herr Braun',
          'B018',
        ),
        _lesson(
          thu,
          1135,
          1220,
          'SP',
          _subjectName('SP', locale),
          'Coach Ali',
          'Field',
        ),
        _lesson(
          thu,
          1225,
          1310,
          'SP',
          _subjectName('SP', locale),
          'Coach Ali',
          'Field',
        ),
        _lesson(
          thu,
          1320,
          1405,
          'KU',
          _subjectName('KU', locale),
          'Frau Stern',
          'Art 1',
        ),
      ],
      4: [
        _lesson(
          fri,
          800,
          845,
          'BI',
          _subjectName('BI', locale),
          'Frau Koch',
          'Lab 2',
        ),
        _lesson(
          fri,
          850,
          935,
          'CH',
          _subjectName('CH', locale),
          'Dr. Roth',
          'Lab 1',
        ),
        _lesson(
          fri,
          945,
          1030,
          'IF',
          _subjectName('IF', locale),
          'Herr Weber',
          'IT 3',
        ),
        _lesson(
          fri,
          1035,
          1120,
          'EN',
          _subjectName('EN', locale),
          'Mrs. Miller',
          'C110',
        ),
        _lesson(
          fri,
          1135,
          1220,
          'SO',
          _subjectName('SO', locale),
          'Frau Neumann',
          'B022',
        ),
        _lesson(
          fri,
          1225,
          1310,
          'KL',
          _subjectName('KL', locale),
          'Herr Lang',
          'B204',
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
        'subject': 'Mathematik',
        'examType': 'Klausur',
        'date': _dateInt(
          DateTime(y, now.month, now.day).add(const Duration(days: 3)),
        ),
        'description': 'Analysis und Funktionen',
      },
      {
        'subject': 'Englisch',
        'examType': 'Vokabeltest',
        'date': _dateInt(
          DateTime(y, now.month, now.day).add(const Duration(days: 8)),
        ),
        'description': 'Unit 6, Writing Task',
      },
      {
        'subject': 'Biologie',
        'examType': 'Praktikum',
        'date': _dateInt(
          DateTime(y, now.month, now.day).add(const Duration(days: 12)),
        ),
        'description': 'Mikroskopie-Protokoll',
      },
    ];
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
    return {
      'date': _dateInt(date),
      'startTime': startTime,
      'endTime': endTime,
      '_subjectShort': subjectShort,
      '_subjectLong': subjectLong,
      '_teacher': teacher,
      '_room': room,
      'code': code,
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
        'en': 'German',
        'fr': 'Allemand',
        'es': 'Aleman',
        'el': 'Γερμανικά',
      },
      'EN': {
        'de': 'Englisch',
        'en': 'English',
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
        'en': 'Advanced Support',
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
        'en': 'Class Teacher Period',
        'fr': 'Heure de professeur principal',
        'es': 'Hora de tutor',
        'el': 'Ώρα υπευθύνου τμήματος',
      },
    };

    return map[code]?[lang] ?? map[code]?['de'] ?? code;
  }
}
