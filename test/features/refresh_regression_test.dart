import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/utils/formatters.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/data/notification_repository.dart';
import 'package:sparkleen_mobile/features/notifikasi/presentation/notification_page.dart';
import 'package:sparkleen_mobile/features/pembayaran/application/payment_controller.dart';
import 'package:sparkleen_mobile/features/pembayaran/data/payment_repository.dart';
import 'package:sparkleen_mobile/features/pembayaran/presentation/payment_page.dart';

import '../support/auth_fakes.dart';
import '../support/engagement_fakes.dart';
import 'payment_test.dart' show FakePayments;

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  test('completed cashier payment retains its paid amount without an active intent', () {
    final payment = PaymentSnapshot.fromJson({
      'mode': 'SIMULATION',
      'status': 'SUCCESS',
      'enabled': true,
      'nominal': 0,
      'sisa': 0,
      'total_dibayar': 38500,
    });
    expect(payment.amount, 0);
    expect(payment.displayAmount, 38500);
    expect(payment.active, false);
  });
  testWidgets(
    'cashier-paid page shows total paid and no new payment instruments',
    (tester) async {
      final repo = FakePayments()
        ..current = PaymentSnapshot.fromJson({
          'mode': 'SIMULATION',
          'status': 'SUCCESS',
          'enabled': true,
          'nominal': 0,
          'sisa': 0,
          'total_dibayar': 38500,
        });
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            paymentRepositoryProvider.overrideWithValue(repo),
            tokenStorageProvider.overrideWithValue(FakeTokenStorage('demo')),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const PaymentPage(id: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(formatRupiah(38500)), findsOneWidget);
      expect(find.text('Lunas'), findsOneWidget);
      expect(find.text('Buat QR simulasi'), findsNothing);
      expect(find.text('Lihat nota'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'notification controls keep section left and read-all right; long inbox is lazy',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeNotifications()
        ..current = NotificationList(
          items: [for (var i = 0; i < 100; i++) testNotification(i + 1)],
          unread: 100,
          latestId: 100,
        );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const NotificationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.text('Hari ini')).dx,
        lessThan(tester.getCenter(find.text('Tandai semua dibaca')).dx),
      );
      expect(find.text('Cucian siap diambil').evaluate().length, lessThan(20));
      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.widgetWithText(TextButton, 'Tandai semua dibaca'))
            .right,
        closeTo(390 - 24, 1),
      );
      expect(repo.cutoff, 100);
      expect(tester.takeException(), isNull);
    },
  );
  test('pickup calendar follows Jakarta on either side of UTC midnight', () {
    final day = jakartaCalendarDate(
      instant: DateTime.parse('2026-11-11T18:30:00Z'),
    );
    expect([day.year, day.month, day.day], [2026, 11, 12]);
    final tomorrow = jakartaCalendarDate(
      instant: DateTime.parse('2026-12-31T18:30:00Z'),
      daysAfter: 1,
    );
    expect([tomorrow.year, tomorrow.month, tomorrow.day], [2027, 1, 2]);
  });
}
