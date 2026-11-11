import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/jemput/application/pickup_controller.dart';
import 'package:sparkleen_mobile/features/jemput/data/pickup_repository.dart';
import 'package:sparkleen_mobile/features/jemput/presentation/pickup_form_page.dart';
import 'package:sparkleen_mobile/features/jemput/presentation/pickup_page.dart';

import '../support/auth_fakes.dart';
import '../support/home_fakes.dart';

PickupRequest pickup({
  int id = 1,
  String status = 'menunggu',
  int? transactionId,
}) => PickupRequest(
  id: id,
  status: status,
  service: 'Cuci Kering',
  estimatedWeight: 4.5,
  estimatedPrice: 31500,
  address: 'Jl. Merdeka No. 10, Depok',
  scheduledAt: DateTime.parse('2026-11-11T12:00:00+07:00'),
  slot: 'siang',
  rejectionReason: status == 'ditolak' ? 'Di luar area penjemputan' : null,
  transactionId: transactionId,
);

class FakePickupRepository implements PickupRepository {
  List<PickupRequest> items = [];
  int lastPage = 1;
  int creates = 0;
  int cancels = 0;
  ApiException? createError;
  ApiException? listError;
  Completer<PickupRequest>? pendingCreate;
  Completer<PickupList>? pendingPage;
  Map<String, Object?>? submitted;
  @override
  Future<PickupList> list({int page = 1}) async {
    if (listError != null) throw listError!;
    if (page > 1 && pendingPage != null) return pendingPage!.future;
    return PickupList(items: List.of(items), page: page, lastPage: lastPage);
  }

  @override
  Future<void> cancel(int id) async {
    cancels++;
    items = [pickup(id: id, status: 'dibatalkan')];
  }

  @override
  Future<PickupRequest> create({
    required int serviceId,
    required double weight,
    required String address,
    required String date,
    required String slot,
    String note = '',
  }) async {
    creates++;
    submitted = {
      'id_layanan': serviceId,
      'berat_perkiraan': weight,
      'alamat_jemput': address,
      'tgl_jemput': date,
      'slot_jemput': slot,
      'catatan': note,
    };
    if (createError != null) throw createError!;
    if (pendingCreate != null) return pendingCreate!.future;
    return pickup();
  }
}

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthAuthenticated(testPelanggan);
}

Widget app(
  FakePickupRepository repository,
  Widget page, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    pickupRepositoryProvider.overrideWithValue(repository),
    authControllerProvider.overrideWith(_Auth.new),
    homeRepositoryProvider.overrideWithValue(
      FakeHomeRepository()..layananResult = testLayanan,
    ),
  ],
  child: MaterialApp(
    theme: buildAppTheme(brightness: brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: page,
  ),
);

Future<void> openForm(
  WidgetTester tester,
  FakePickupRepository repository,
) async {
  await tester.pumpWidget(
    app(
      repository,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PickupFormPage()),
            ),
            child: const Text('Open form'),
          ),
        ),
      ),
    ),
  );
  ProviderScope.containerOf(tester.element(find.text('Open form')))
      .read(authControllerProvider);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
}

Future<void> fillForm(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cuci Kering').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('pickup-weight')), '4,5');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Kirim permintaan jemput'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));
  test('unknown status stays unknown instead of showing confirmed', () {
    final item = pickup(status: 'future-status');
    expect(item.isActive, false);
    expect(item.canCancel, false);
    expect(item.statusLabel, 'Status belum tersedia');
  });
  testWidgets(
    'required pickup fields stay validated after scrolling to submit',
    (tester) async {
      final repo = FakePickupRepository();
      await openForm(tester, repo);
      await tester.scrollUntilVisible(
        find.text('Kirim permintaan jemput'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Kirim permintaan jemput'));
      await tester.pumpAndSettle();
      expect(repo.creates, 0);
      expect(find.text('Pilih layanan.'), findsOneWidget);
      expect(find.text('Masukkan berat 0,1–100 kg.'), findsOneWidget);
    },
  );
  testWidgets(
    'form submits selected service, comma weight and profile address once',
    (tester) async {
      final repo = FakePickupRepository()
        ..pendingCreate = Completer<PickupRequest>();
      await openForm(tester, repo);
      expect(find.text(testPelanggan.alamat), findsOneWidget);
      await fillForm(tester);
      await tester.tap(find.text('Kirim permintaan jemput'));
      await tester.pump();
      expect(repo.creates, 1);
      expect(repo.submitted!['berat_perkiraan'], 4.5);
      expect(repo.submitted!['alamat_jemput'], testPelanggan.alamat);
      expect(repo.submitted!.containsKey('estimasi_harga'), false);
      expect(repo.submitted!.containsKey('id_pelanggan'), false);
      repo.pendingCreate!.complete(pickup());
      await tester.pumpAndSettle();
      expect(find.byType(PickupFormPage), findsNothing);
    },
  );
  testWidgets('server conflict remains on form and shows a useful error', (
    tester,
  ) async {
    final repo = FakePickupRepository()
      ..createError = const ApiException(
        code: 'ACTIVE_REQUEST_EXISTS',
        message: 'Masih ada permintaan aktif.',
        statusCode: 409,
      );
    await openForm(tester, repo);
    await fillForm(tester);
    await tester.tap(find.text('Kirim permintaan jemput'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pickup-error')), findsOneWidget);
    expect(find.text('Masih ada permintaan aktif.'), findsOneWidget);
    expect(find.byType(PickupFormPage), findsOneWidget);
  });
  testWidgets('only waiting pickup can be cancelled after confirmation', (
    tester,
  ) async {
    final repo = FakePickupRepository()..items = [pickup()];
    await tester.pumpWidget(app(repo, const PickupPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Batalkan permintaan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan permintaan'));
    await tester.pumpAndSettle();
    expect(repo.cancels, 0);
    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();
    expect(repo.cancels, 1);
    expect(find.text('Dibatalkan'), findsOneWidget);
    expect(find.text('Batalkan permintaan'), findsNothing);
  });
  testWidgets(
    'processed pickup cannot be cancelled and rejected pickup explains why',
    (tester) async {
      final repo = FakePickupRepository()
        ..items = [
          pickup(status: 'diproses'),
          pickup(id: 2, status: 'ditolak'),
        ];
      await tester.pumpWidget(app(repo, const PickupPage()));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan permintaan'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Permintaan ditolak'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Permintaan ditolak'));
      await tester.pumpAndSettle();
      expect(find.text('Alasan: Di luar area penjemputan'), findsOneWidget);
    },
  );
  test(
    'late pagination response cannot restore previous customer pickups',
    () async {
      final repo = FakePickupRepository()
        ..items = [pickup()]
        ..lastPage = 2
        ..pendingPage = Completer<PickupList>();
      final container = ProviderContainer.test(
        overrides: [pickupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        pickupControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(pickupControllerProvider.future);
      final pending = container
          .read(pickupControllerProvider.notifier)
          .loadMore();
      repo.items = [];
      repo.lastPage = 1;
      container.read(customerSessionRevisionProvider.notifier).advance();
      await container.read(pickupControllerProvider.future);
      repo.pendingPage!.complete(
        PickupList(items: [pickup(id: 2)], page: 2, lastPage: 2),
      );
      await pending;
      expect(
        container.read(pickupControllerProvider).value!.result.items,
        isEmpty,
      );
    },
  );
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.8]) {
      testWidgets('pickup pages fit 320px at $scale / ${brightness.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FakePickupRepository()
          ..items = [pickup(status: 'dikonfirmasi', transactionId: 2)];
        await tester.pumpWidget(
          app(repo, const PickupPage(), brightness: brightness, scale: scale),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Lihat pesanan'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(
            repo,
            const PickupFormPage(),
            brightness: brightness,
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Kirim permintaan jemput'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
