import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/accounts/domain/untis_account.dart';

void main() {
  final account = UntisAccount(
    id: 'account-1',
    username: 'student',
    schoolUrl: 'school.example',
    schoolName: 'Example School',
    password: 'secret',
    credentialMode: 'password',
    sessionId: 'session',
    personId: 42,
    personType: 5,
    lastUsedAt: DateTime.utc(2026, 9, 21),
  );

  test('public account JSON never includes credentials by default', () {
    final json = account.toJson();

    expect(json['id'], 'account-1');
    expect(json, isNot(contains('password')));
    expect(json, isNot(contains('sessionId')));
    expect(json, isNot(contains('credentialMode')));
  });

  test('legacy account JSON with credentials still round-trips', () {
    final restored = UntisAccount.fromJson(account.toJson(includeSecrets: true));

    expect(restored.password, 'secret');
    expect(restored.sessionId, 'session');
    expect(restored.personId, 42);
    expect(restored.lastUsedAt, DateTime.utc(2026, 9, 21));
  });

  test('storage keys remain compatible with existing installations', () {
    expect(untisAccountsStorageKey, 'untisAccountsV1');
    expect(activeUntisAccountStorageKey, 'activeUntisAccountId');
  });
}
