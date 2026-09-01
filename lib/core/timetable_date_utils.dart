DateTime resolveDefaultTimetableMonday(DateTime referenceDate) {
  final dayStart = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  final currentWeekMonday = dayStart.subtract(
    Duration(days: referenceDate.weekday - DateTime.monday),
  );
  if (referenceDate.weekday >= DateTime.saturday) {
    return currentWeekMonday.add(const Duration(days: DateTime.daysPerWeek));
  }
  return currentWeekMonday;
}

int resolveInitialTimetableDayIndex(DateTime referenceDate) {
  if (referenceDate.weekday >= DateTime.saturday) return 0;
  return (referenceDate.weekday - DateTime.monday).clamp(0, 4);
}
