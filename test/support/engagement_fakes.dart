import 'dart:async';

import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/loyalitas/data/loyalty_repository.dart';
import 'package:sparkleen_mobile/features/notifikasi/data/notification_repository.dart';

RedemptionQuote testQuote({bool redeemed = false, bool blocked = false}) =>
    RedemptionQuote(
      orderId: 1,
      nota: 'LAU/TEST/0001',
      balance: redeemed ? 79 : 100,
      total: redeemed ? 29000 : 35000,
      earned: redeemed ? 2 : 3,
      maxPoints: redeemed || blocked ? 0 : 99,
      canRedeem: !redeemed && !blocked,
      reason: blocked ? 'Batalkan tagihan online terlebih dahulu.' : null,
      redemption: redeemed ? {'points': 20, 'discount': 6000} : null,
    );
CustomerNotification testNotification(int id, {bool read = false}) =>
    CustomerNotification(
      id: id,
      title: 'Cucian siap diambil',
      body: 'Buka pesanan untuk rincian cucian Anda.',
      category: 'order',
      targetType: 'order',
      targetId: 1,
      readAt: read ? DateTime(2026, 11, 10) : null,
      createdAt: DateTime(2026, 11, 10, 12),
    );

class FakeNotifications implements NotificationRepository {
  NotificationList current = NotificationList(
    items: [testNotification(100)],
    unread: 1,
    latestId: 100,
  );
  NotificationList? next;
  ApiException? error;
  Completer<void>? delayedRead;
  Completer<NotificationList>? delayedPage;
  int reads = 0, summaryCalls = 0;
  int? cutoff;
  @override
  Future<int> unread() async {
    summaryCalls++;
    return current.unread;
  }

  @override
  Future<NotificationList> list({int page = 1}) async {
    if (error != null) throw error!;
    if (page > 1 && delayedPage != null) return delayedPage!.future;
    return page > 1 && next != null ? next! : current;
  }

  @override
  Future<void> read(int id) async {
    reads++;
    if (delayedRead != null) await delayedRead!.future;
    if (error != null) throw error!;
    current = NotificationList(
      items: [testNotification(id, read: true)],
      latestId: 100,
    );
  }

  @override
  Future<void> readAll(int throughId) async {
    cutoff = throughId;
    if (error != null) throw error!;
    current = NotificationList(
      items: [testNotification(100, read: true)],
      latestId: 100,
    );
  }
}

class FakeLoyalty implements LoyaltyRepository {
  RedemptionQuote current = testQuote();
  LoyaltySummary balance = const LoyaltySummary(balance: 100);
  LoyaltySummary? next;
  Completer<RedemptionQuote>? delayed;
  ApiException? error;
  int redemptions = 0;
  List<String> keys = [];
  int? submittedPoints, submittedTotal;
  @override
  Future<LoyaltySummary> summary({int page = 1}) async =>
      page > 1 && next != null ? next! : balance;
  @override
  Future<RedemptionQuote> quote(int id) async => current;
  @override
  Future<RedemptionQuote> redeem(
    int id, {
    required int points,
    required int expectedTotal,
    required String requestId,
  }) async {
    redemptions++;
    keys.add(requestId);
    submittedPoints = points;
    submittedTotal = expectedTotal;
    if (error != null) throw error!;
    return delayed != null ? delayed!.future : testQuote(redeemed: true);
  }
}
