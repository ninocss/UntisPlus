/// Extracts the numeric components from a version-like string.
List<int> extractVersionParts(String input) {
  final cleaned = input.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final matches = RegExp(r'\d+').allMatches(cleaned);
  if (matches.isEmpty) return const [0];
  return matches
      .map((match) => int.tryParse(match.group(0) ?? '0') ?? 0)
      .toList(growable: false);
}

/// Compares two version-like strings by their numeric components.
int compareVersionStrings(String current, String latest) {
  final currentParts = extractVersionParts(current);
  final latestParts = extractVersionParts(latest);
  final maxLength = currentParts.length > latestParts.length
      ? currentParts.length
      : latestParts.length;
  for (var index = 0; index < maxLength; index++) {
    final currentPart = index < currentParts.length ? currentParts[index] : 0;
    final latestPart = index < latestParts.length ? latestParts[index] : 0;
    final comparison = currentPart.compareTo(latestPart);
    if (comparison != 0) return comparison;
  }
  return 0;
}
