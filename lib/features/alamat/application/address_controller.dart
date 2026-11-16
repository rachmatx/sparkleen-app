import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/address_repository.dart';

final addressRepositoryProvider = Provider(
  (ref) => AddressRepository(ref.watch(apiClientProvider)),
);
final addressesProvider = AsyncNotifierProvider<AddressController, AddressList>(
  AddressController.new,
);

class AddressController extends AsyncNotifier<AddressList> {
  int _epoch = 0;
  bool _loadingMore = false;
  @override
  Future<AddressList> build() async {
    ref.watch(customerSessionRevisionProvider);
    _epoch++;
    _loadingMore = false;
    return ref.watch(addressRepositoryProvider).list();
  }

  Future<void> refresh() async {
    final epoch = ++_epoch;
    final next = await AsyncValue.guard(
      () => ref.read(addressRepositoryProvider).list(),
    );
    if (ref.mounted && epoch == _epoch) state = next;
  }

  Future<void> loadMore() async {
    final old = state.value;
    if (_loadingMore || old == null || old.page >= old.lastPage) return;
    _loadingMore = true;
    final epoch = _epoch;
    try {
      final next = await ref
          .read(addressRepositoryProvider)
          .list(page: old.page + 1);
      if (ref.mounted && epoch == _epoch) {
        final ids = old.items.map((v) => v.id).toSet();
        state = AsyncData(
          AddressList(
            items: [...old.items, ...next.items.where((v) => ids.add(v.id))],
            page: next.page,
            lastPage: next.lastPage,
          ),
        );
      }
    } finally {
      if (epoch == _epoch) _loadingMore = false;
    }
  }
}
