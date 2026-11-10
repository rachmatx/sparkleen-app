import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../home/application/home_providers.dart';
import '../../nota/presentation/nota_page.dart';
import '../../notifikasi/application/notification_controller.dart';
import '../../pembayaran/application/payment_controller.dart';
import '../../pesanan/application/pesanan_controller.dart';
import '../../pesanan/presentation/detail_pesanan_page.dart';
import '../data/loyalty_repository.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => LoyaltyRepository(ref.watch(apiClientProvider)),
);
final loyaltySummaryProvider =
    AsyncNotifierProvider.autoDispose<LoyaltyController, LoyaltyView>(
      LoyaltyController.new,
    );

class LoyaltyView {
  const LoyaltyView(this.summary, {this.busy = false, this.error});
  final LoyaltySummary summary;
  final bool busy;
  final Object? error;
}

class LoyaltyController extends AsyncNotifier<LoyaltyView> {
  int _epoch = 0;
  @override
  Future<LoyaltyView> build() async {
    ref.watch(customerSessionRevisionProvider);
    _epoch++;
    return LoyaltyView(await ref.watch(loyaltyRepositoryProvider).summary());
  }

  Future<void> refresh() async {
    final epoch = ++_epoch;
    final next = await AsyncValue.guard(
      () async =>
          LoyaltyView(await ref.read(loyaltyRepositoryProvider).summary()),
    );
    if (ref.mounted && epoch == _epoch) state = next;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.busy ||
        current.summary.page >= current.summary.lastPage) {
      return;
    }
    final epoch = _epoch;
    state = AsyncData(LoyaltyView(current.summary, busy: true));
    try {
      final next = await ref
          .read(loyaltyRepositoryProvider)
          .summary(page: current.summary.page + 1);
      if (!ref.mounted || epoch != _epoch) return;
      final ids = current.summary.history.map((e) => e.id).toSet();
      state = AsyncData(
        LoyaltyView(
          LoyaltySummary(
            balance: next.balance,
            value: next.value,
            page: next.page,
            lastPage: next.lastPage,
            history: [
              ...current.summary.history,
              ...next.history.where((e) => ids.add(e.id)),
            ],
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = AsyncData(LoyaltyView(current.summary, error: error));
      }
    }
  }
}

final redemptionProvider = AsyncNotifierProvider.autoDispose
    .family<RedemptionController, RedemptionView, int>(
      RedemptionController.new,
    );

class RedemptionView {
  const RedemptionView(this.quote, {this.busy = false, this.error});
  final RedemptionQuote quote;
  final bool busy;
  final Object? error;
}

class RedemptionController extends AsyncNotifier<RedemptionView> {
  RedemptionController(this.id);
  final int id;
  int _epoch = 0;
  int? _attemptPoints;
  String? _requestId;
  @override
  Future<RedemptionView> build() async {
    ref.watch(customerSessionRevisionProvider);
    _epoch++;
    _attemptPoints = null;
    _requestId = null;
    return RedemptionView(await ref.watch(loyaltyRepositoryProvider).quote(id));
  }

  Future<void> redeem(int points) async {
    final current = state.value;
    if (current == null ||
        current.busy ||
        !current.quote.canRedeem ||
        points < 1 ||
        points > current.quote.maxPoints) {
      return;
    }
    final epoch = _epoch;
    final revision = ref.read(customerSessionRevisionProvider);
    if (_requestId == null || _attemptPoints != points) {
      final random = Random.secure();
      _requestId = base64UrlEncode(
        List.generate(24, (_) => random.nextInt(256)),
      ).replaceAll('=', '');
      _attemptPoints = points;
    }
    state = AsyncData(RedemptionView(current.quote, busy: true));
    try {
      final result = await ref
          .read(loyaltyRepositoryProvider)
          .redeem(
            id,
            points: points,
            expectedTotal: current.quote.total,
            requestId: _requestId!,
          );
      if (!ref.mounted ||
          epoch != _epoch ||
          revision != ref.read(customerSessionRevisionProvider)) {
        return;
      }
      state = AsyncData(RedemptionView(result));
      ref.invalidate(loyaltySummaryProvider);
      ref.invalidate(unreadNotificationsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(transaksiDetailProvider(id));
      ref.invalidate(notaProvider(id));
      ref.invalidate(paymentControllerProvider(id));
      ref.invalidate(pesananControllerProvider);
      ref.invalidate(pesananAktifProvider);
      try {
        await ref.read(authControllerProvider.notifier).refreshMe();
      } on Object {
        /* The committed redemption remains visible if profile refresh fails. */
      }
    } catch (error) {
      if (ref.mounted &&
          epoch == _epoch &&
          revision == ref.read(customerSessionRevisionProvider)) {
        state = AsyncData(RedemptionView(current.quote, error: error));
      }
    }
  }
}
