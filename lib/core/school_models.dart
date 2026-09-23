class SchoolSearchResult {
  const SchoolSearchResult({
    required this.id,
    required this.loginName,
    required this.displayName,
    required this.serverUrl,
    required this.address,
  });

  final int id;
  final String loginName;
  final String displayName;
  final String serverUrl;
  final String address;

  factory SchoolSearchResult.fromJson(Map<String, dynamic> json) {
    return SchoolSearchResult(
      id: switch (json['schoolId']) {
        final int value => value,
        final num value => value.toInt(),
        final Object value => int.tryParse(value.toString()) ?? 0,
        null => 0,
      },
      loginName: (json['loginName'] ?? '').toString().trim(),
      displayName: (json['displayName'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      serverUrl: (json['server'] ?? json['serverUrl'] ?? '').toString().trim(),
    );
  }
}
