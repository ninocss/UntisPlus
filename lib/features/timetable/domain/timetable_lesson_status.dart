/// WebUntis marks changed lessons as `irregular` and cancellations as
/// `cancelled`. Some responses also wrap the replacement in `new_lesson`.
bool isTimetableSubstitution(Map? lesson) {
  if (lesson == null) return false;
  if (lesson['isSubstitution'] == true || lesson['substitution'] == true) {
    return true;
  }
  final code = lesson['code']?.toString().trim().toLowerCase();
  if (code == 'irregular' || code == 'substitution') return true;
  final replacement = lesson['new_lesson'] ?? lesson['newLesson'];
  if (replacement is Map) return isTimetableSubstitution(replacement);
  return false;
}

bool isTimetableCancelled(Map? lesson) =>
    lesson?['code']?.toString().trim().toLowerCase() == 'cancelled' &&
    !isTimetableSubstitution(lesson);
