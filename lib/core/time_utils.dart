String formatUntisTime(String time) {
  if (time.length < 3) return time;
  final formatted = time.padLeft(4, '0');
  return "${formatted.substring(0, 2)}:${formatted.substring(2)}";
}
