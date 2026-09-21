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
      id: json['schoolId'] ?? 0,
      loginName: json['loginName'] ?? '',
      displayName: json['displayName'] ?? '',
      address: json['address'] ?? '',
      serverUrl: json['server'] ?? json['serverUrl'] ?? '',
    );
  }
}
