import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/main.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/router/app_router.dart';
import 'package:sparkleen_mobile/core/security/biometric_service.dart';
import 'package:sparkleen_mobile/core/settings/appearance_settings.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/home/data/layanan.dart';
import 'package:sparkleen_mobile/features/jemput/application/pickup_controller.dart';
import 'package:sparkleen_mobile/features/loyalitas/application/loyalty_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/application/notification_controller.dart';
import 'package:sparkleen_mobile/features/notifikasi/data/notification_repository.dart';
import 'package:sparkleen_mobile/features/pembayaran/application/payment_controller.dart';
import 'package:sparkleen_mobile/features/pembayaran/data/payment_repository.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';

import '../test/support/auth_fakes.dart';
import '../test/support/home_fakes.dart';
import '../test/support/engagement_fakes.dart';
import '../test/support/redesign_fixtures.dart';
import '../test/features/payment_test.dart' show FakePayments;
import '../test/features/pickup_test.dart' as pickup_fixture;
import '../test/features/session_security_test.dart' show FakeBiometrics;

class LockedPreview extends AuthController {
  @override
  Future<AuthState> build() async => const AuthLocked();
}

class OfflinePreview extends AuthController {
  @override
  Future<AuthState> build() async => const AuthSessionUnavailable(
    ApiException(
      code: 'NETWORK_ERROR',
      message: 'Server pengujian belum tersedia.',
    ),
  );
}

class StartingPreview extends AuthController {
  @override
  Future<AuthState> build() => Completer<AuthState>().future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    for (final entry in {
      'Manrope': [400, 500, 700],
      'PlusJakartaSans': [500, 600, 700, 800],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final weight in entry.value) {
        loader.addFont(
          rootBundle.load('assets/fonts/${entry.key}-$weight.ttf'),
        );
      }
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final cases = <String, String>{
    'home': '/beranda',
    'profile': '/profil',
    'settings': '/pengaturan',
    'orders': '/pesanan',
    'history': '/riwayat-pesanan',
    'detail': '/pesanan/87',
    'receipt': '/pesanan/87/nota',
    'pickup': '/jemput',
    'pickup-form': '/jemput/baru',
    'notifications': '/notifikasi',
    'points': '/poin',
    'redeem': '/pesanan/87/poin',
    'security': '/keamanan',
    'server': '/server',
    'edit-profile': '/ubah-profil',
    'payment-choice': '/pesanan/87/pembayaran',
    'payment-qr': '/pesanan/87/pembayaran',
    'payment-success': '/pesanan/87/pembayaran',
    'login': '/login',
    'register': '/register',
    'activate': '/activate',
    'locked': '/session',
    'offline': '/session',
    'splash': '/splash',
  };
  for (final brightness in Brightness.values) {
    testWidgets(
      'capture all ${brightness.name} routes and scroll long content',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        for (final entry in cases.entries) {
          final name = entry.key;
          final unauth = ['login', 'register', 'activate'].contains(name);
          final storage = FakeTokenStorage(unauth ? null : 'demo');
          final biometric = FakeBiometrics(storage);
          final payments = FakePayments();
          if (name == 'payment-qr') {
            payments.current = PaymentSnapshot(
              status: 'PENDING',
              enabled: true,
              amount: 35000,
              remaining: 35000,
              method: 'QRIS',
              expiresAt: DateTime.now().add(const Duration(minutes: 15)),
              detail: {
                'simulation_code': 'SPARKLEEN-QA-SIMULATION-NOT-A-PAYMENT',
                'qr_image': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQgAAAEIAQMAAACZOPi8AAAABlBMVEX///8AAABVwtN+AAAACXBIWXMAAA7EAAAOxAGVKw4bAAABWklEQVRoge2YO7KDMAxFlaGgzBJYCkuDpbEUlpCSIhM962Nh82wmZYqrAhv5VJorSzIRDPYDNrHZJpsPyeY1uu8FokXYsmzpMzDrZnyXRyCuhERQDp7H8Eko74l4aJRB3BM0hgpBfEtoAtNdTEEUeWsqpHnvZjYIXaI2qPgS2q8eICqb+KCHqbBjIPLBkGuDEimUVxWCqAjT3Dr7wSJEcmgCg2gRLBdccu0W05VykWAQHYLlgst2TgVrdoGoCXqylwRDlwjunGsDiIqQA1k1b72akugSRJc4THzyk/uPdx1TEBXh/5Q7ttbkCaIiVHPyHuQd26SFQXUJokGETWf/QVTGFERNWARjRKfQZYwHIC7EOaub+NRTdCQg/hE6A0j/YW+Onrd694G4JSyU0rG5MBnELSEqjHdtoqr/AFERnrdWVoPQDYgW4Yrb4qlx9yJRzA0gWv0YDPar9gf8cQEU8dcOBAAAAABJRU5ErkJggg==',
              },
            );
          }
          if (name == 'payment-success') {
            payments.current = const PaymentSnapshot(
              status: 'SUCCESS',
              enabled: true,
              amount: 0,
              remaining: 0,
              totalPaid: 35000,
            );
          }
          final notifications = FakeNotifications()
            ..current = NotificationList(
              items: [
                CustomerNotification(
                  id: 1,
                  title: 'Pembayaran lunas',
                  body: 'Pembayaran online terkonfirmasi pada nota pesananmu.',
                  category: 'payment',
                  targetType: 'order',
                  targetId: 87,
                  createdAt: DateTime.now(),
                ),
                testNotification(2),
              ],
              unread: 2,
              latestId: 2,
            );
          final container = ProviderContainer(
            retry: (_, _) => null,
            overrides: [
              initialThemeModeProvider.overrideWithValue(
                brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
              ),
              tokenStorageProvider.overrideWithValue(storage),
              authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
              biometricServiceProvider.overrideWithValue(biometric),
              homeRepositoryProvider.overrideWithValue(
                FakeHomeRepository()
                  ..layananResult = const [
                    Layanan(
                      id: 1,
                      nama: 'Cuci + Setrika',
                      hargaPerKg: 10000,
                      estimasiHari: 1,
                    ),
                    Layanan(
                      id: 2,
                      nama: 'Cuci Kilat',
                      hargaPerKg: 10000,
                      estimasiHari: 1,
                    ),
                  ]
                  ..pesananAktifResult = testTransaksiAktif,
              ),
              transaksiRepositoryProvider.overrideWithValue(
                redesignTransaksiRepository(),
              ),
              pickupRepositoryProvider.overrideWithValue(
                pickup_fixture.FakePickupRepository()
                  ..items = [pickup_fixture.pickup()],
              ),
              loyaltyRepositoryProvider.overrideWithValue(FakeLoyalty()),
              notificationRepositoryProvider.overrideWithValue(notifications),
              paymentRepositoryProvider.overrideWithValue(payments),
              if (name == 'locked')
                authControllerProvider.overrideWith(LockedPreview.new),
              if (name == 'offline')
                authControllerProvider.overrideWith(OfflinePreview.new),
              if (name == 'splash')
                authControllerProvider.overrideWith(StartingPreview.new),
            ],
          );
          final key = GlobalKey();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(key: key, child: const SparkleenApp()),
            ),
          );
          if (name == 'splash') {
            await tester.pump(const Duration(milliseconds: 200));
          } else {
            await tester.pumpAndSettle();
          }
          final router = container.read(routerProvider);
          if (![
            'home',
            'locked',
            'offline',
            'splash',
            'login',
          ].contains(name)) {
            if (['profile', 'orders', 'register', 'activate'].contains(name)) {
              router.go(entry.value);
            } else {
              unawaited(router.push(entry.value));
            }
            await tester.pumpAndSettle();
          }
          if (name == 'security') {
            await biometric.enable('demo');
            await biometric.paymentPreference('demo', true);
            container.invalidate(biometricSettingsProvider);
            await tester.pumpAndSettle();
          }
          if (name == 'redeem') {
            await tester.enterText(find.byType(TextField), '20');
            await tester.pumpAndSettle();
          }
          final providers = find
              .byType(Image)
              .evaluate()
              .map((el) => (el.widget as Image).image)
              .toSet();
          await tester.runAsync(
            () => Future.wait(
              providers.map(
                (provider) => precacheImage(provider, key.currentContext!),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$name / ${brightness.name} before capture',
          );
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '../.tooling/ui-qa-v003/${brightness.name}/$name.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isNotEmpty && name != 'splash') {
            for (var n = 0; n < 3; n++) {
              await tester.drag(scroll.first, const Offset(0, -450));
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$name / ${brightness.name} scroll $n',
              );
            }
          }
          await tester.pumpWidget(const SizedBox());
          container.dispose();
        }
      },
    );
  }
}
