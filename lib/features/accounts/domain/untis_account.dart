const untisAccountsStorageKey = 'untisAccountsV1';
const activeUntisAccountStorageKey = 'activeUntisAccountId';

/// A WebUntis profile stored on the current device.
///
/// [toJson] omits secrets by default because credentials belong in the native
/// credential vault. Reading legacy JSON still accepts those fields so older
/// installations can migrate without losing access.
class UntisAccount {
  const UntisAccount({
    required this.id,
    required this.username,
    required this.schoolUrl,
    required this.schoolName,
    required this.password,
    required this.credentialMode,
    required this.sessionId,
    required this.personId,
    required this.personType,
    required this.lastUsedAt,
  });

  final String id;
  final String username;
  final String schoolUrl;
  final String schoolName;
  final String password;
  final String credentialMode;
  final String sessionId;
  final int personId;
  final int personType;
  final DateTime lastUsedAt;

  String get label => username.isEmpty ? schoolName : username;

  Map<String, dynamic> toJson({bool includeSecrets = false}) => {
    'id': id,
    'username': username,
    'schoolUrl': schoolUrl,
    'schoolName': schoolName,
    if (includeSecrets) 'password': password,
    if (includeSecrets) 'credentialMode': credentialMode,
    if (includeSecrets) 'sessionId': sessionId,
    'personId': personId,
    'personType': personType,
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  factory UntisAccount.fromJson(Map<String, dynamic> json) {
    return UntisAccount(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      schoolUrl: json['schoolUrl']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      credentialMode: json['credentialMode']?.toString() ?? 'password',
      sessionId: json['sessionId']?.toString() ?? '',
      personId: (json['personId'] as num?)?.toInt() ?? 0,
      personType: (json['personType'] as num?)?.toInt() ?? 5,
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  UntisAccount copyWith({
    String? password,
    String? credentialMode,
    String? sessionId,
    DateTime? lastUsedAt,
  }) => UntisAccount(
    id: id,
    username: username,
    schoolUrl: schoolUrl,
    schoolName: schoolName,
    password: password ?? this.password,
    credentialMode: credentialMode ?? this.credentialMode,
    sessionId: sessionId ?? this.sessionId,
    personId: personId,
    personType: personType,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}
