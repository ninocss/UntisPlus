import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cache/offline_cache_store.dart';
import '../data/security/credential_vault.dart';
import '../data/webuntis/webuntis_client.dart';

final webUntisClientProvider = Provider<WebUntisClient>((ref) {
  final client = WebUntisClient();
  ref.onDispose(client.close);
  return client;
});

final credentialVaultProvider = Provider<CredentialVault>(
  (ref) => CredentialVault.instance,
);

final offlineCacheStoreProvider = Provider<OfflineCacheStore>(
  (ref) => OfflineCacheStore.instance,
);
