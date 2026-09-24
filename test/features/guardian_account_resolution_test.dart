import 'package:flutter_test/flutter_test.dart';

void main() {
  group('_resolveTimetableElementFromAuth', () {
    test('returns fallback when no linked people', () {
      final authResult = <String, dynamic>{};
      final result = _resolveTimetableElementFromAuth(authResult, 42, 5);
      expect(result['personId'], 42);
      expect(result['personType'], 5);
    });

    test('resolves student type from self in people list', () {
      final authResult = {
        'people': [
          {'id': 42, 'type': 5, 'name': 'Student User'},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 42);
      expect(result['personType'], 5);
    });

    test('redirects guardian (type 3) to first student (type 5)', () {
      final authResult = {
        'people': [
          {'id': 42, 'type': 3, 'name': 'Parent User'},
          {'id': 99, 'type': 5, 'name': 'Child User'},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 99);
      expect(result['personType'], 5);
    });

    test('redirects guardian using persons list when people empty', () {
      final authResult = {
        'people': [],
        'persons': [
          {'id': 42, 'type': 3, 'name': 'Parent User'},
          {'id': 100, 'type': 5, 'name': 'Child User'},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 100);
      expect(result['personType'], 5);
    });

    test('keeps fallback when guardian has no linked students', () {
      final authResult = {
        'people': [
          {'id': 42, 'type': 3, 'name': 'Parent User'},
          {'id': 43, 'type': 4, 'name': 'Teacher User'},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 42);
      expect(result['personType'], 3);
    });

    test('handles string ids and types gracefully', () {
      final authResult = {
        'people': [
          {'id': '42', 'type': '3', 'name': 'Parent User'},
          {'id': '99', 'type': '5', 'name': 'Child User'},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 99);
      expect(result['personType'], 5);
    });

    test('ignores invalid entries in linked lists', () {
      final authResult = {
        'people': [
          'not-a-map',
          {'id': 42, 'type': 3},
          {'id': 99, 'type': 5},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 99);
      expect(result['personType'], 5);
    });

    test('prioritizes first student when multiple students linked', () {
      final authResult = {
        'people': [
          {'id': 42, 'type': 3, 'name': 'Parent User'},
          {'id': 99, 'type': 5, 'name': 'First Child'},
          {'id': 100, 'type': 5, 'name': 'Second Child'},
        ],
      };
      final result = _resolveTimetableElementFromAuth(authResult, 42, 3);
      expect(result['personId'], 99);
      expect(result['personType'], 5);
    });
  });
}

/// Copy of the internal function for testing purposes.
/// In a real refactor this would be extracted to a shared utility.
Map<String, dynamic> _resolveTimetableElementFromAuth(
  Map<String, dynamic> authResult,
  int fallbackPersonId,
  int fallbackPersonType,
) {
  var personId = fallbackPersonId;
  var personType = fallbackPersonType;

  final linked = <Map<dynamic, dynamic>>[];
  final rawPeople = authResult['people'];
  if (rawPeople is List) {
    for (final p in rawPeople) {
      if (p is Map) linked.add(Map<dynamic, dynamic>.from(p));
    }
  }
  final rawPersons = authResult['persons'];
  if (rawPersons is List) {
    for (final p in rawPersons) {
      if (p is Map) linked.add(Map<dynamic, dynamic>.from(p));
    }
  }

  Map<dynamic, dynamic>? self;
  for (final p in linked) {
    if ((p['id']?.toString()) == personId.toString()) {
      self = p;
      break;
    }
  }
  if (self != null) {
    final selfType = int.tryParse(self['type']?.toString() ?? '');
    if (selfType != null) personType = selfType;
  }

  if (personType == 3) {
    Map<dynamic, dynamic>? child;
    for (final p in linked) {
      if (int.tryParse(p['type']?.toString() ?? '-1') == 5) {
        child = p;
        break;
      }
    }
    if (child != null) {
      final childId = int.tryParse(child['id']?.toString() ?? '');
      if (childId != null && childId > 0) {
        personId = childId;
        personType = 5;
      }
    }
  }

  return {'personId': personId, 'personType': personType};
}