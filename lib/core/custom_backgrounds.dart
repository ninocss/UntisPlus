part of '../main.dart';

// ── Custom Backgrounds (v1) ──────────────────────────────────────────────────

const int kCustomBackgroundSpecVersion = 1;

const String _kPrefsCustomBackgrounds = 'customBackgrounds';
const String _kPrefsSelectedCustomBackgroundId = 'selectedCustomBackgroundId';

final ValueNotifier<List<CustomBackgroundSpec>> customBackgroundsNotifier =
    ValueNotifier(const []);

final ValueNotifier<String?> selectedCustomBackgroundIdNotifier =
    ValueNotifier(null);

CustomBackgroundSpec? _activeCustomBackgroundOrNull() {
  final selectedId = selectedCustomBackgroundIdNotifier.value;
  final all = customBackgroundsNotifier.value;
  if (all.isEmpty) return null;
  if (selectedId != null) {
    for (final spec in all) {
      if (spec.id == selectedId) return spec;
    }
  }
  return all.first;
}

String _newCustomBackgroundId() {
  // Stable-enough locally, and easy to serialize.
  return 'cbg_${DateTime.now().microsecondsSinceEpoch}';
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

enum CustomBackgroundGradientType { linear, radial }

enum CustomBackgroundPatternType { none, lines, grid }

CustomBackgroundGradientType _parseGradientType(dynamic value) {
  final s = value?.toString().trim().toLowerCase() ?? '';
  switch (s) {
    case 'radial':
      return CustomBackgroundGradientType.radial;
    case 'linear':
    default:
      return CustomBackgroundGradientType.linear;
  }
}

CustomBackgroundPatternType _parsePatternType(dynamic value) {
  final s = value?.toString().trim().toLowerCase() ?? '';
  switch (s) {
    case 'lines':
      return CustomBackgroundPatternType.lines;
    case 'grid':
      return CustomBackgroundPatternType.grid;
    case 'none':
    default:
      return CustomBackgroundPatternType.none;
  }
}

int _clampInt(dynamic value, int min, int max, int fallback) {
  final parsed = value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');
  final v = parsed ?? fallback;
  return v.clamp(min, max);
}

double _clampDouble(dynamic value, double min, double max, double fallback) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  final v = parsed ?? fallback;
  if (v.isNaN || v.isInfinite) return fallback;
  return v.clamp(min, max);
}

int? _parseColorValue(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    // Accept 0xRRGGBB or 0xAARRGGBB.
    final v = value;
    if (v <= 0xFFFFFF) return 0xFF000000 | v;
    return v;
  }
  if (value is num) {
    final v = value.toInt();
    if (v <= 0xFFFFFF) return 0xFF000000 | v;
    return v;
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  String normalized = raw;
  if (normalized.startsWith('0x')) {
    normalized = normalized.substring(2);
  }
  if (normalized.startsWith('#')) {
    normalized = normalized.substring(1);
  }

  // RGB -> add FF alpha
  if (normalized.length == 6) {
    final v = int.tryParse(normalized, radix: 16);
    if (v == null) return null;
    return 0xFF000000 | v;
  }

  // ARGB
  if (normalized.length == 8) {
    return int.tryParse(normalized, radix: 16);
  }

  // Fallback: try parse as int
  return int.tryParse(raw);
}

List<int> _parseColorList(dynamic value, {required List<int> fallback}) {
  if (value is List) {
    final out = <int>[];
    for (final e in value) {
      final parsed = _parseColorValue(e);
      if (parsed != null) out.add(parsed);
    }
    if (out.length >= 2) return out.take(4).toList(growable: false);
  }
  return fallback;
}

@immutable
class CustomBackgroundGradient {
  final CustomBackgroundGradientType type;
  final bool useThemeColors;
  final List<int> colors;
  final double opacity;
  final double angleDeg; // only linear
  final double centerX; // [-1..1] only radial
  final double centerY; // [-1..1] only radial
  final double radius; // [0.4..2.0] only radial

  const CustomBackgroundGradient({
    required this.type,
    required this.useThemeColors,
    required this.colors,
    required this.opacity,
    required this.angleDeg,
    required this.centerX,
    required this.centerY,
    required this.radius,
  });

  factory CustomBackgroundGradient.defaults() {
    return const CustomBackgroundGradient(
      type: CustomBackgroundGradientType.radial,
      useThemeColors: true,
      colors: [0xFF6750A4, 0xFF7D5260, 0xFF4A4458],
      opacity: 0.28,
      angleDeg: 45,
      centerX: -0.25,
      centerY: -0.78,
      radius: 1.35,
    );
  }

  factory CustomBackgroundGradient.fromJson(Map<String, dynamic> json) {
    final fallback = CustomBackgroundGradient.defaults();
    return CustomBackgroundGradient(
      type: _parseGradientType(json['type']),
      useThemeColors: (json['useThemeColors'] ?? fallback.useThemeColors) ==
          true,
      colors: _parseColorList(
        json['colors'],
        fallback: fallback.colors,
      ),
      opacity: _clampDouble(json['opacity'], 0.0, 1.0, fallback.opacity),
      angleDeg: _clampDouble(json['angleDeg'], 0.0, 360.0, fallback.angleDeg),
      centerX: _clampDouble(json['centerX'], -1.0, 1.0, fallback.centerX),
      centerY: _clampDouble(json['centerY'], -1.0, 1.0, fallback.centerY),
      radius: _clampDouble(json['radius'], 0.4, 2.0, fallback.radius),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'useThemeColors': useThemeColors,
    'colors': colors,
    'opacity': opacity,
    'angleDeg': angleDeg,
    'centerX': centerX,
    'centerY': centerY,
    'radius': radius,
  };

  CustomBackgroundGradient copyWith({
    CustomBackgroundGradientType? type,
    bool? useThemeColors,
    List<int>? colors,
    double? opacity,
    double? angleDeg,
    double? centerX,
    double? centerY,
    double? radius,
  }) {
    return CustomBackgroundGradient(
      type: type ?? this.type,
      useThemeColors: useThemeColors ?? this.useThemeColors,
      colors: colors ?? this.colors,
      opacity: opacity ?? this.opacity,
      angleDeg: angleDeg ?? this.angleDeg,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radius: radius ?? this.radius,
    );
  }
}

@immutable
class CustomBackgroundOrbs {
  final bool enabled;
  final int seed;
  final int count;
  final double size;
  final double sizeVariance;
  final double opacity;
  final double softness;
  final bool useThemeColors;
  final List<int> colors;

  const CustomBackgroundOrbs({
    required this.enabled,
    required this.seed,
    required this.count,
    required this.size,
    required this.sizeVariance,
    required this.opacity,
    required this.softness,
    required this.useThemeColors,
    required this.colors,
  });

  factory CustomBackgroundOrbs.defaults() {
    return const CustomBackgroundOrbs(
      enabled: true,
      seed: 1337,
      count: 7,
      size: 190,
      sizeVariance: 0.32,
      opacity: 0.26,
      softness: 0.72,
      useThemeColors: true,
      colors: [0xFF6750A4, 0xFF625B71, 0xFF7D5260],
    );
  }

  factory CustomBackgroundOrbs.fromJson(Map<String, dynamic> json) {
    final fallback = CustomBackgroundOrbs.defaults();
    return CustomBackgroundOrbs(
      enabled: (json['enabled'] ?? fallback.enabled) == true,
      seed: _clampInt(json['seed'], 0, 1 << 31, fallback.seed),
      count: _clampInt(json['count'], 0, 14, fallback.count),
      size: _clampDouble(json['size'], 40, 420, fallback.size),
      sizeVariance: _clampDouble(
        json['sizeVariance'],
        0.0,
        1.0,
        fallback.sizeVariance,
      ),
      opacity: _clampDouble(json['opacity'], 0.0, 1.0, fallback.opacity),
      softness: _clampDouble(json['softness'], 0.0, 1.0, fallback.softness),
      useThemeColors: (json['useThemeColors'] ?? fallback.useThemeColors) ==
          true,
      colors: _parseColorList(json['colors'], fallback: fallback.colors),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'seed': seed,
    'count': count,
    'size': size,
    'sizeVariance': sizeVariance,
    'opacity': opacity,
    'softness': softness,
    'useThemeColors': useThemeColors,
    'colors': colors,
  };

  CustomBackgroundOrbs copyWith({
    bool? enabled,
    int? seed,
    int? count,
    double? size,
    double? sizeVariance,
    double? opacity,
    double? softness,
    bool? useThemeColors,
    List<int>? colors,
  }) {
    return CustomBackgroundOrbs(
      enabled: enabled ?? this.enabled,
      seed: seed ?? this.seed,
      count: count ?? this.count,
      size: size ?? this.size,
      sizeVariance: sizeVariance ?? this.sizeVariance,
      opacity: opacity ?? this.opacity,
      softness: softness ?? this.softness,
      useThemeColors: useThemeColors ?? this.useThemeColors,
      colors: colors ?? this.colors,
    );
  }
}

@immutable
class CustomBackgroundPattern {
  final CustomBackgroundPatternType type;
  final double opacity;
  final double scale;
  final double angleDeg; // for lines

  const CustomBackgroundPattern({
    required this.type,
    required this.opacity,
    required this.scale,
    required this.angleDeg,
  });

  factory CustomBackgroundPattern.defaults() {
    return const CustomBackgroundPattern(
      type: CustomBackgroundPatternType.none,
      opacity: 0.10,
      scale: 1.0,
      angleDeg: 25,
    );
  }

  factory CustomBackgroundPattern.fromJson(Map<String, dynamic> json) {
    final fallback = CustomBackgroundPattern.defaults();
    return CustomBackgroundPattern(
      type: _parsePatternType(json['type']),
      opacity: _clampDouble(json['opacity'], 0.0, 1.0, fallback.opacity),
      scale: _clampDouble(json['scale'], 0.5, 3.0, fallback.scale),
      angleDeg: _clampDouble(json['angleDeg'], 0.0, 360.0, fallback.angleDeg),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'opacity': opacity,
    'scale': scale,
    'angleDeg': angleDeg,
  };

  CustomBackgroundPattern copyWith({
    CustomBackgroundPatternType? type,
    double? opacity,
    double? scale,
    double? angleDeg,
  }) {
    return CustomBackgroundPattern(
      type: type ?? this.type,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      angleDeg: angleDeg ?? this.angleDeg,
    );
  }
}

@immutable
class CustomBackgroundSpec {
  final int version;
  final String id;
  final String name;
  final int createdAtMs;
  final int updatedAtMs;

  final CustomBackgroundGradient base;
  final CustomBackgroundOrbs orbs;
  final CustomBackgroundPattern pattern;

  final double noise;
  final double vignette;

  final bool animate;
  final double animationSpeed;
  final double parallaxStrength;

  const CustomBackgroundSpec({
    required this.version,
    required this.id,
    required this.name,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.base,
    required this.orbs,
    required this.pattern,
    required this.noise,
    required this.vignette,
    required this.animate,
    required this.animationSpeed,
    required this.parallaxStrength,
  });

  factory CustomBackgroundSpec.defaults({String? id, String? name}) {
    final now = _nowMs();
    return CustomBackgroundSpec(
      version: kCustomBackgroundSpecVersion,
      id: id ?? _newCustomBackgroundId(),
      name: name ?? 'Theme Aura',
      createdAtMs: now,
      updatedAtMs: now,
      base: CustomBackgroundGradient.defaults(),
      orbs: CustomBackgroundOrbs.defaults(),
      pattern: CustomBackgroundPattern.defaults(),
      noise: 0.08,
      vignette: 0.22,
      animate: true,
      animationSpeed: 1.0,
      parallaxStrength: 0.55,
    );
  }

  factory CustomBackgroundSpec.fromJson(Map<String, dynamic> json) {
    final fallback = CustomBackgroundSpec.defaults(id: 'fallback');
    final version = _clampInt(
      json['version'],
      1,
      999,
      kCustomBackgroundSpecVersion,
    );

    final id = (json['id'] ?? '').toString().trim();
    final name = (json['name'] ?? '').toString().trim();

    return CustomBackgroundSpec(
      version: version,
      id: id.isNotEmpty ? id : _newCustomBackgroundId(),
      name: name.isNotEmpty ? name : fallback.name,
      createdAtMs: _clampInt(
        json['createdAtMs'],
        0,
        1 << 62,
        fallback.createdAtMs,
      ),
      updatedAtMs: _clampInt(
        json['updatedAtMs'],
        0,
        1 << 62,
        fallback.updatedAtMs,
      ),
      base: json['base'] is Map
          ? CustomBackgroundGradient.fromJson(
              Map<String, dynamic>.from(json['base'] as Map),
            )
          : fallback.base,
      orbs: json['orbs'] is Map
          ? CustomBackgroundOrbs.fromJson(
              Map<String, dynamic>.from(json['orbs'] as Map),
            )
          : fallback.orbs,
      pattern: json['pattern'] is Map
          ? CustomBackgroundPattern.fromJson(
              Map<String, dynamic>.from(json['pattern'] as Map),
            )
          : fallback.pattern,
      noise: _clampDouble(json['noise'], 0.0, 0.5, fallback.noise),
      vignette: _clampDouble(json['vignette'], 0.0, 0.7, fallback.vignette),
      animate: (json['animate'] ?? fallback.animate) == true,
      animationSpeed: _clampDouble(
        json['animationSpeed'],
        0.0,
        2.5,
        fallback.animationSpeed,
      ),
      parallaxStrength: _clampDouble(
        json['parallaxStrength'],
        0.0,
        1.0,
        fallback.parallaxStrength,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'id': id,
    'name': name,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    'base': base.toJson(),
    'orbs': orbs.toJson(),
    'pattern': pattern.toJson(),
    'noise': noise,
    'vignette': vignette,
    'animate': animate,
    'animationSpeed': animationSpeed,
    'parallaxStrength': parallaxStrength,
  };

  CustomBackgroundSpec copyWith({
    String? name,
    CustomBackgroundGradient? base,
    CustomBackgroundOrbs? orbs,
    CustomBackgroundPattern? pattern,
    double? noise,
    double? vignette,
    bool? animate,
    double? animationSpeed,
    double? parallaxStrength,
    int? updatedAtMs,
  }) {
    return CustomBackgroundSpec(
      version: version,
      id: id,
      name: name ?? this.name,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      base: base ?? this.base,
      orbs: orbs ?? this.orbs,
      pattern: pattern ?? this.pattern,
      noise: noise ?? this.noise,
      vignette: vignette ?? this.vignette,
      animate: animate ?? this.animate,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      parallaxStrength: parallaxStrength ?? this.parallaxStrength,
    );
  }
}

Future<void> loadCustomBackgroundsFromPrefs(SharedPreferences prefs) async {
  List<CustomBackgroundSpec> parsed = [];
  try {
    final raw = prefs.getStringList(_kPrefsCustomBackgrounds) ?? [];
    parsed = raw
        .map((e) {
          try {
            final decoded = jsonDecode(e);
            if (decoded is Map<String, dynamic>) {
              return CustomBackgroundSpec.fromJson(decoded);
            }
          } catch (_) {}
          return null;
        })
        .whereType<CustomBackgroundSpec>()
        .toList();
  } catch (_) {
    parsed = [];
  }

  if (parsed.isEmpty) {
    parsed = [
      CustomBackgroundSpec.defaults(id: 'theme_aura', name: 'Theme Aura'),
    ];
    await prefs.setStringList(
      _kPrefsCustomBackgrounds,
      parsed.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  customBackgroundsNotifier.value = List.unmodifiable(parsed);

  final selectedId = prefs.getString(_kPrefsSelectedCustomBackgroundId);
  if (selectedId != null && selectedId.trim().isNotEmpty) {
    selectedCustomBackgroundIdNotifier.value = selectedId.trim();
  } else {
    selectedCustomBackgroundIdNotifier.value = parsed.first.id;
    await prefs.setString(
      _kPrefsSelectedCustomBackgroundId,
      parsed.first.id,
    );
  }
}

Future<void> _persistCustomBackgroundState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _kPrefsCustomBackgrounds,
    customBackgroundsNotifier.value.map((s) => jsonEncode(s.toJson())).toList(),
  );
  final selected = selectedCustomBackgroundIdNotifier.value;
  if (selected != null && selected.trim().isNotEmpty) {
    await prefs.setString(_kPrefsSelectedCustomBackgroundId, selected.trim());
  }
}

Future<void> upsertCustomBackground(CustomBackgroundSpec spec) async {
  final all = customBackgroundsNotifier.value;
  final updated = <CustomBackgroundSpec>[];
  var replaced = false;
  for (final existing in all) {
    if (existing.id == spec.id) {
      updated.add(spec);
      replaced = true;
    } else {
      updated.add(existing);
    }
  }
  if (!replaced) updated.add(spec);

  customBackgroundsNotifier.value = List.unmodifiable(updated);
  selectedCustomBackgroundIdNotifier.value = spec.id;
  await _persistCustomBackgroundState();
}

Future<void> deleteCustomBackground(String id) async {
  final before = customBackgroundsNotifier.value;
  final updated = before.where((s) => s.id != id).toList();

  if (updated.isEmpty) {
    final fallback = CustomBackgroundSpec.defaults(
      id: 'theme_aura',
      name: 'Theme Aura',
    );
    customBackgroundsNotifier.value = [fallback];
    selectedCustomBackgroundIdNotifier.value = fallback.id;
    await _persistCustomBackgroundState();
    return;
  }

  customBackgroundsNotifier.value = List.unmodifiable(updated);

  if (selectedCustomBackgroundIdNotifier.value == id) {
    selectedCustomBackgroundIdNotifier.value = updated.first.id;
  }

  await _persistCustomBackgroundState();
}

Future<void> selectCustomBackground(String id) async {
  final exists = customBackgroundsNotifier.value.any((s) => s.id == id);
  if (!exists) return;
  selectedCustomBackgroundIdNotifier.value = id;
  await _persistCustomBackgroundState();
}

CustomBackgroundSpec duplicateCustomBackground(CustomBackgroundSpec base) {
  final now = _nowMs();
  return CustomBackgroundSpec(
    version: base.version,
    id: _newCustomBackgroundId(),
    name: '${base.name} Copy',
    createdAtMs: now,
    updatedAtMs: now,
    base: base.base,
    orbs: base.orbs.copyWith(seed: math.Random().nextInt(1 << 31)),
    pattern: base.pattern,
    noise: base.noise,
    vignette: base.vignette,
    animate: base.animate,
    animationSpeed: base.animationSpeed,
    parallaxStrength: base.parallaxStrength,
  );
}

String exportCustomBackgroundSpecPretty(CustomBackgroundSpec spec) {
  return const JsonEncoder.withIndent('  ').convert(spec.toJson());
}

String exportCustomBackgroundLibraryPretty(List<CustomBackgroundSpec> specs) {
  return const JsonEncoder.withIndent('  ').convert(
    specs.map((s) => s.toJson()).toList(growable: false),
  );
}

String _stripMarkdownCodeFences(String input) {
  var out = input;
  // Remove ```json ... ``` and ``` ... ```.
  out = out.replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '');
  out = out.replaceAll('```', '');
  return out.trim();
}

String _extractFirstJsonBlock(String input) {
  final s = _stripMarkdownCodeFences(input);
  final arrayStart = s.indexOf('[');
  final objStart = s.indexOf('{');

  if (arrayStart != -1 && (objStart == -1 || arrayStart < objStart)) {
    final end = s.lastIndexOf(']');
    if (end != -1 && end > arrayStart) {
      return s.substring(arrayStart, end + 1).trim();
    }
  }

  if (objStart != -1) {
    final end = s.lastIndexOf('}');
    if (end != -1 && end > objStart) {
      return s.substring(objStart, end + 1).trim();
    }
  }

  return s;
}

CustomBackgroundSpec _withUniqueId(
  CustomBackgroundSpec spec,
  Set<String> existingIds,
) {
  if (!existingIds.contains(spec.id)) {
    existingIds.add(spec.id);
    return spec;
  }

  final now = _nowMs();
  final updated = CustomBackgroundSpec(
    version: spec.version,
    id: _newCustomBackgroundId(),
    name: spec.name,
    createdAtMs: now,
    updatedAtMs: now,
    base: spec.base,
    orbs: spec.orbs,
    pattern: spec.pattern,
    noise: spec.noise,
    vignette: spec.vignette,
    animate: spec.animate,
    animationSpeed: spec.animationSpeed,
    parallaxStrength: spec.parallaxStrength,
  );
  existingIds.add(updated.id);
  return updated;
}

List<CustomBackgroundSpec> parseCustomBackgroundSpecsFromJsonText(
  String text,
) {
  final jsonText = _extractFirstJsonBlock(text);
  final decoded = jsonDecode(jsonText);
  if (decoded is Map) {
    return [CustomBackgroundSpec.fromJson(Map<String, dynamic>.from(decoded))];
  }
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((e) => CustomBackgroundSpec.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  throw Exception('Invalid JSON');
}

Future<int> importCustomBackgroundsFromJsonText(
  String text, {
  bool replaceAll = false,
}) async {
  final incoming = parseCustomBackgroundSpecsFromJsonText(text);
  if (incoming.isEmpty) return 0;

  final now = _nowMs();
  final existing = customBackgroundsNotifier.value;
  final ids = <String>{...existing.map((e) => e.id)};

  final normalized = incoming
      .map((s) {
        final base = s.copyWith(updatedAtMs: now);
        return _withUniqueId(base, ids);
      })
      .toList();

  if (replaceAll) {
    customBackgroundsNotifier.value = List.unmodifiable(normalized);
    selectedCustomBackgroundIdNotifier.value = normalized.first.id;
    await _persistCustomBackgroundState();
    return normalized.length;
  }

  final merged = [...existing, ...normalized];
  customBackgroundsNotifier.value = List.unmodifiable(merged);
  selectedCustomBackgroundIdNotifier.value = normalized.last.id;
  await _persistCustomBackgroundState();
  return normalized.length;
}
