String formatUntisTime(String time) {
  final trimmed = time.trim();
  if (trimmed.isEmpty) return time;
  final formatted = trimmed.padLeft(4, '0');
  return "${formatted.substring(0, 2)}:${formatted.substring(2)}";
}

String formatUntisDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}';
