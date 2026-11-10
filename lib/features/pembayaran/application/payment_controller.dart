import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../home/application/home_providers.dart';
import '../../nota/presentation/nota_page.dart';
import '../../pesanan/application/pesanan_controller.dart';
import '../../pesanan/presentation/detail_pesanan_page.dart';
import '../data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(apiClientProvider)),
);
final paymentControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PaymentController, PaymentViewState, int>(PaymentController.new);

class PaymentViewState {
  const PaymentViewState(this.snapshot, {this.busy = false, this.error});
  final PaymentSnapshot snapshot;
  final bool busy;
  final Object? error;
}

class PaymentController extends AsyncNotifier<PaymentViewState> {
  PaymentController(this.id);
  final int id;
  int _epoch = 0;
  @override
  Future<PaymentViewState> build() async {
    ref.watch(customerSessionRevisionProvider);
    _epoch++;
    return PaymentViewState(
      await ref.watch(paymentRepositoryProvider).load(id),
    );
  }

  Future<void> start(String method) =>
      _run((repository) => repository.start(id, method));
  Future<void> sync() => _run((repository) => repository.sync(id));
  Future<void> cancel() => _run((repository) => repository.cancel(id));
  Future<void> _run(
    Future<PaymentSnapshot> Function(PaymentRepository) action,
  ) async {
    final current = state.value;
    if (current == null || current.busy) return;
    final epoch = _epoch;
    final revision = ref.read(customerSessionRevisionProvider);
    state = AsyncData(PaymentViewState(current.snapshot, busy: true));
    try {
      final result = await action(ref.read(paymentRepositoryProvider));
      if (!ref.mounted ||
          epoch != _epoch ||
          revision != ref.read(customerSessionRevisionProvider)) {
        return;
      }
      state = AsyncData(PaymentViewState(result));
      if (result.status == 'SUCCESS') {
        ref.invalidate(transaksiDetailProvider(id));
        ref.invalidate(notaProvider(id));
        ref.invalidate(pesananControllerProvider);
        ref.invalidate(pesananAktifProvider);
      }
    } catch (error) {
      if (ref.mounted &&
          epoch == _epoch &&
          revision == ref.read(customerSessionRevisionProvider)) {
        state = AsyncData(PaymentViewState(current.snapshot, error: error));
      }
    }
  }
}
