import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/auth_fakes.dart';

import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/pembayaran/application/payment_controller.dart';
import 'package:sparkleen_mobile/features/pembayaran/data/payment_repository.dart';
import 'package:sparkleen_mobile/features/pembayaran/presentation/payment_page.dart';

PaymentSnapshot snapshot({
  String status = 'NONE',
  bool enabled = true,
  String? method,
}) => PaymentSnapshot(
  status: status,
  enabled: enabled,
  amount: 35000,
  remaining: status == 'SUCCESS' ? 0 : 35000,
  method: method,
  detail: const {'simulation_code': 'fixture-demo-code'},
);

class FakePayments implements PaymentRepository {
  PaymentSnapshot current = snapshot();
  int starts = 0;
  int syncs = 0;
  int cancels = 0;
  String? submitted;
  ApiException? error;
  Completer<PaymentSnapshot>? delayed;
  @override
  Future<PaymentSnapshot> load(int id) async => current;
  @override
  Future<PaymentSnapshot> start(int id, String method) async {
    starts++;
    submitted = method;
    if (error != null) throw error!;
    return current =
        await (delayed?.future ??
            Future.value(snapshot(status: 'PENDING', method: method)));
  }

  @override
  Future<PaymentSnapshot> sync(int id) async {
    syncs++;
    if (error != null) throw error!;
    return current;
  }

  @override
  Future<PaymentSnapshot> cancel(int id) async {
    cancels++;
    if (error != null) throw error!;
    return current = snapshot();
  }
}

Widget app(
  FakePayments repository, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    paymentRepositoryProvider.overrideWithValue(repository),
    tokenStorageProvider.overrideWithValue(FakeTokenStorage('fixture-token')),
  ],
  child: MaterialApp(
    theme: buildAppTheme(brightness: brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const PaymentPage(id: 1),
  ),
);
void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  test('unknown mode/status fails closed', () {
    final value = PaymentSnapshot.fromJson({
      'mode': 'LIVE',
      'status': 'PENDING',
      'enabled': true,
      'payment_detail': {'account_number': '123'},
    });
    expect(value.status, 'REVIEW');
    expect(value.enabled, false);
    expect(value.detail, isEmpty);
  });
  testWidgets('disabled outlet exposes no creation buttons', (tester) async {
    final repository = FakePayments()..current = snapshot(enabled: false);
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Buat QR simulasi'), findsNothing);
    expect(find.textContaining('belum diaktifkan'), findsOneWidget);
  });
  testWidgets(
    'start submits only selected method and duplicate tap is blocked',
    (tester) async {
      final repository = FakePayments()..delayed = Completer();
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat QR simulasi'));
      await tester.pump();
      await tester.tap(find.text('Buat QR simulasi'));
      expect(repository.starts, 1);
      expect(repository.submitted, 'QRIS');
      repository.delayed!.complete(snapshot(status: 'PENDING', method: 'QRIS'));
      await tester.pumpAndSettle();
      expect(find.text('fixture-demo-code'), findsOneWidget);
      expect(find.textContaining('Jangan transfer uang nyata'), findsOneWidget);
    },
  );
  testWidgets('failed sync preserves pending code and offers retry', (
    tester,
  ) async {
    final repository = FakePayments()
      ..current = snapshot(status: 'PENDING', method: 'TRANSFER')
      ..error = const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Koneksi terputus',
      );
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Periksa status'));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi terputus'), findsOneWidget);
    expect(find.text('fixture-demo-code'), findsOneWidget);
    expect(find.text('Buat QR simulasi'), findsNothing);
  });
  testWidgets('cancel requires confirmation and provider reply', (
    tester,
  ) async {
    final repository = FakePayments()..current = snapshot(status: 'PENDING');
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan tagihan'));
    await tester.pumpAndSettle();
    expect(repository.cancels, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Batalkan tagihan'));
    await tester.pumpAndSettle();
    expect(repository.cancels, 1);
    expect(find.text('Buat QR simulasi'), findsOneWidget);
  });
  testWidgets('foreground polls pending and background stops polling', (
    tester,
  ) async {
    final repository = FakePayments()..current = snapshot(status: 'PENDING');
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(repository.syncs, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(repository.syncs, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.syncs, 2);
  });
  test(
    'old session create completion cannot replace new account state',
    () async {
      final repository = FakePayments()..delayed = Completer();
      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage('fixture-token'),
          ),
        ],
        retry: (_, _) => null,
      );
      final subscription = container.listen(
        paymentControllerProvider(1),
        (_, _) {},
      );
      addTearDown(() => {subscription.close(), container.dispose()});
      await container.read(paymentControllerProvider(1).future);
      final old = container
          .read(paymentControllerProvider(1).notifier)
          .start('QRIS');
      repository.current = snapshot(enabled: false);
      container.read(customerSessionRevisionProvider.notifier).advance();
      await container.read(paymentControllerProvider(1).future);
      repository.delayed!.complete(snapshot(status: 'PENDING'));
      await old;
      expect(
        container.read(paymentControllerProvider(1)).value!.snapshot.enabled,
        false,
      );
      expect(
        container.read(paymentControllerProvider(1)).value!.snapshot.status,
        'NONE',
      );
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets('320px $brightness large text has no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakePayments()
        ..current = snapshot(status: 'PENDING', method: 'TRANSFER');
      await tester.pumpWidget(
        app(repository, brightness: brightness, scale: 1.6),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final status in ['PROCESSING', 'EXPIRED', 'REVIEW', 'SUCCESS']) {
    testWidgets('$status never offers another create', (tester) async {
      await tester.pumpWidget(
        app(FakePayments()..current = snapshot(status: status)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buat QR simulasi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
