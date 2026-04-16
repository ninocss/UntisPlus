String formatUntisTime(String time) {
  final trimmed = time.trim();
  if (trimmed.isEmpty) return time;
  final formatted = trimmed.padLeft(4, '0');
  return "${formatted.substring(0, 2)}:${formatted.substring(2)}";
}
