import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'storage/token_storage.dart';
import 'settings/server_settings.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    baseUrl: '${ref.watch(serverAddressProvider)}/api/v1',
  );
});

/// Invalidates customer data after a session changes, without coupling data
/// providers back to the authentication controller or secure-storage plugins.
final customerSessionRevisionProvider =
    NotifierProvider<CustomerSessionRevision, int>(CustomerSessionRevision.new);

class CustomerSessionRevision extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state++;
}
