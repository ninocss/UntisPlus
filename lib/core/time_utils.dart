String formatUntisTime(String time) {
  final trimmed = time.trim();
  if (trimmed.isEmpty) return time;
  final formatted = trimmed.padLeft(4, '0');
  return "${formatted.substring(0, 2)}:${formatted.substring(2)}";
}

String formatUntisDate(DateTime value) => untisDateString(value);

String untisDateString(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}';

int untisDateInt(DateTime value) => int.parse(untisDateString(value));

DateTime? parseUntisDateString(String? value) {
  final normalized = value?.trim() ?? '';
  if (!RegExp(r'^\d{8}$').hasMatch(normalized)) return null;
  final year = int.tryParse(normalized.substring(0, 4));
  final month = int.tryParse(normalized.substring(4, 6));
  final day = int.tryParse(normalized.substring(6, 8));
  if (year == null || month == null || day == null) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

DateTime? parseUntisDateInt(int? value) =>
    value == null ? null : parseUntisDateString(value.toString());

DateTime? parseUntisDate(Object? value) {
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  if (value is int) return parseUntisDateInt(value);
  return parseUntisDateString(value?.toString());
}

int? normalizeUntisDateInt(Object? value) {
  final parsed = parseUntisDate(value);
  return parsed == null ? null : untisDateInt(parsed);
}

int? untisTimeToMinutes(Object? value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0) return null;
  final hours = parsed ~/ 100;
  final minutes = parsed % 100;
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}
