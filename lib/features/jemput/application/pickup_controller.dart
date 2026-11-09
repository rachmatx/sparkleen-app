import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/pickup_repository.dart';

final pickupRepositoryProvider = Provider<PickupRepository>(
  (ref) => PickupRepository(ref.watch(apiClientProvider)),
);
final pickupControllerProvider =
    AsyncNotifierProvider<PickupController, PickupState>(PickupController.new);

class PickupState {
  const PickupState({
    required this.result,
    this.loadingMore = false,
    this.error,
  });
  final PickupList result;
  final bool loadingMore;
  final Object? error;
}

class PickupController extends AsyncNotifier<PickupState> {
  int _epoch = 0;
  PickupRepository get _repository => ref.read(pickupRepositoryProvider);
  @override
  Future<PickupState> build() async {
    ref.watch(customerSessionRevisionProvider);
    _epoch++;
    return PickupState(result: await _repository.list());
  }

  Future<void> refresh() async {
    final epoch = ++_epoch;
    final next = await AsyncValue.guard(
      () async => PickupState(result: await _repository.list()),
    );
    if (ref.mounted && epoch == _epoch) state = next;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.loadingMore ||
        current.result.page >= current.result.lastPage) {
      return;
    }
    final epoch = _epoch;
    state = AsyncData(PickupState(result: current.result, loadingMore: true));
    try {
      final next = await _repository.list(page: current.result.page + 1);
      if (!ref.mounted || epoch != _epoch) return;
      final ids = current.result.items.map((item) => item.id).toSet();
      state = AsyncData(
        PickupState(
          result: PickupList(
            items: [
              ...current.result.items,
              ...next.items.where((item) => ids.add(item.id)),
            ],
            page: next.page,
            lastPage: next.lastPage,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(PickupState(result: current.result, error: error));
      }
    }
  }

  Future<void> cancel(int id) async {
    final revision = ref.read(customerSessionRevisionProvider);
    await _repository.cancel(id);
    if (ref.mounted && revision == ref.read(customerSessionRevisionProvider)) {
      await refresh();
    }
  }
}
