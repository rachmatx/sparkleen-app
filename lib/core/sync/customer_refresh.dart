import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/home/application/home_providers.dart';
import '../../features/pesanan/application/pesanan_controller.dart';
import '../../features/pesanan/presentation/detail_pesanan_page.dart';
import '../../features/nota/presentation/nota_page.dart';
import '../../features/notifikasi/application/notification_controller.dart';
import '../../features/loyalitas/application/loyalty_controller.dart';
import '../../features/jemput/application/pickup_controller.dart';

class RefreshStatus {
  const RefreshStatus({this.busy = false, this.failed = false});
  final bool busy, failed;
}

final customerRefreshProvider =
    NotifierProvider<CustomerRefresh, RefreshStatus>(CustomerRefresh.new);

class CustomerRefresh extends Notifier<RefreshStatus> {
  Future<void>? _pending;
  @override
  RefreshStatus build() {
    ref.watch(customerSessionRevisionProvider);
    _pending = null;
    return const RefreshStatus();
  }

  Future<void> refresh() => _pending ??= _refresh();
  Future<void> _refresh() async {
    final revision = ref.read(customerSessionRevisionProvider);
    if (ref.read(authControllerProvider).value is! AuthAuthenticated) return;
    state = const RefreshStatus(busy: true);
    var failed = false;
    try {
      await ref.read(authControllerProvider.notifier).refreshMe();
    } on Object {
      failed = true;
    }
    if (!ref.mounted || revision != ref.read(customerSessionRevisionProvider)) {
      return;
    }
    if (ref.read(authControllerProvider).value is AuthAuthenticated) {
      ref.invalidate(layananProvider);
      ref.invalidate(outletProvider);
      ref.invalidate(pesananAktifProvider);
      ref.invalidate(transaksiDetailProvider);
      ref.invalidate(notaProvider);
      ref.invalidate(loyaltySummaryProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
      final results = await Future.wait(
        [
          ref.read(layananProvider.future),
          ref.read(outletProvider.future),
          ref.read(pesananAktifProvider.future),
          ref.read(unreadNotificationsProvider.future),
          ref.read(pesananControllerProvider.notifier).refresh(),
          ref.read(pickupControllerProvider.notifier).refresh(),
        ].map(
          (future) => future.then(
            (_) => true,
            onError: (Object _, StackTrace _) => false,
          ),
        ),
      );
      failed = failed || results.any((ok) => !ok);
    }
    if (ref.mounted && revision == ref.read(customerSessionRevisionProvider)) {
      state = RefreshStatus(failed: failed);
      _pending = null;
    }
  }
}
