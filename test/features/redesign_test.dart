import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/app_artwork.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/data/pelanggan.dart';
import 'package:sparkleen_mobile/features/auth/presentation/activate_page.dart';
import 'package:sparkleen_mobile/features/auth/presentation/login_page.dart';
import 'package:sparkleen_mobile/features/auth/presentation/register_page.dart';
import 'package:sparkleen_mobile/features/home/application/home_providers.dart';
import 'package:sparkleen_mobile/features/home/presentation/home_page.dart';
import 'package:sparkleen_mobile/features/nota/presentation/nota_page.dart';
import 'package:sparkleen_mobile/features/pesanan/application/pesanan_controller.dart';
import 'package:sparkleen_mobile/features/pesanan/presentation/detail_pesanan_page.dart';
import 'package:sparkleen_mobile/features/pesanan/presentation/pesanan_page.dart';
import 'package:sparkleen_mobile/features/profil/presentation/edit_profil_page.dart';
import 'package:sparkleen_mobile/features/profil/presentation/profil_page.dart';
import 'package:sparkleen_mobile/main.dart';

import '../support/auth_fakes.dart';
import '../support/engagement_fakes.dart';

import 'package:sparkleen_mobile/features/pengaturan/presentation/settings_page.dart';
import 'package:sparkleen_mobile/features/profil/presentation/security_page.dart';

import 'package:sparkleen_mobile/features/loyalitas/presentation/loyalty_page.dart';
import 'package:sparkleen_mobile/features/loyalitas/application/loyalty_controller.dart';

import '../support/home_fakes.dart';
import '../support/redesign_fixtures.dart';

class _PendingLogin extends FakeAuthRepository {
  final result = Completer<Pelanggan>();
  @override
  Future<Pelanggan> login({required String noTelp, required String pin}) {
    loginCalls++;
    return result.future;
  }
}

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  // Render the actual pages and scroll lazy children into layout. A single
  // viewport screenshot would miss overflow near the bottom of these screens.
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 360.0, 390.0, 412.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('pages fit $width / text $scale / ${brightness.name}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final page in const [
            HomePage(),
            LoginPage(),
            RegisterPage(),
            ActivatePage(),
            PesananPage(),
            DetailPesananPage(id: 87),
            NotaPage(id: 87),
            ProfilPage(),
            EditProfilPage(),
            SettingsPage(),
            SecurityPage(),
          ]) {
            final container = ProviderContainer.test(
              retry: (_, _) => null,
              overrides: [
                tokenStorageProvider.overrideWithValue(
                  FakeTokenStorage('demo'),
                ),
                authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
                homeRepositoryProvider.overrideWithValue(
                  FakeHomeRepository()
                    ..layananResult = testLayanan
                    ..pesananAktifResult = testTransaksiAktif,
                ),
                transaksiRepositoryProvider.overrideWithValue(
                  redesignTransaksiRepository(),
                ),
              ],
            );
            await container.read(authControllerProvider.future);
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: buildAppTheme(brightness: brightness),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: page,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType} initial',
            );
            final scroll = find.byType(Scrollable).first;
            for (var step = 0; step < 8; step++) {
              await tester.drag(scroll, const Offset(0, -500));
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${page.runtimeType} scroll $step',
              );
            }
            await tester.pumpWidget(const SizedBox());
            container.dispose();
          }
        });
      }
    }
  }

  testWidgets(
    'PIN visibility preserves digits and loading blocks keyboard resubmit',
    (tester) async {
      final repository = _PendingLogin();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: const LoginPage()),
        ),
      );
      await tester.pumpAndSettle();
      final pin = find.byType(TextFormField).at(1);
      await tester.enterText(find.byType(TextFormField).first, '081298765432');
      await tester.enterText(pin, '12a34567');
      expect(tester.widget<TextFormField>(pin).controller!.text, '123456');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Tampilkan PIN'));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .obscureText,
        isFalse,
      );
      await tester.tap(find.byTooltip('Sembunyikan PIN'));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .obscureText,
        isTrue,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pump();
      expect(repository.loginCalls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      tester
          .widget<TextField>(
            find.descendant(of: pin, matching: find.byType(TextField)),
          )
          .onSubmitted!('123456');
      await tester.pump();
      expect(repository.loginCalls, 1);
      repository.result.complete(testPelanggan);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('service sheet, outlet copy, points and order links work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage('demo')),
          loyaltyRepositoryProvider.overrideWithValue(FakeLoyalty()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          homeRepositoryProvider.overrideWithValue(
            FakeHomeRepository()
              ..layananResult = testLayanan
              ..pesananAktifResult = testTransaksiAktif,
          ),
          transaksiRepositoryProvider.overrideWithValue(
            redesignTransaksiRepository(),
          ),
        ],
        child: const SparkleenApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Cuci Kering'), 200);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuci Kering'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('Rp 7.000 per kg'), findsOneWidget);
    expect(find.byType(IllustrationPanel), findsWidgets);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Salin nomor WhatsApp outlet'),
      200,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salin nomor WhatsApp outlet'));
    await tester.pumpAndSettle();
    expect(copied, testOutlet.noWa);
    await tester.scrollUntilVisible(find.text('15 poin'), -400);
    await tester.tap(find.text('15 poin'));
    await tester.pumpAndSettle();
    expect(find.byType(LoyaltyPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(LoyaltyPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Beranda'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pesanan'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pesanan selesai.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Aktif'));
    await tester.pumpAndSettle();
    expect(find.text(testTransaksiAktif.noNota), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Beranda'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailPesananPage), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lihat Nota'), 200);
    await tester.ensureVisible(find.text('Lihat Nota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Nota'));
    await tester.pumpAndSettle();
    expect(find.byType(NotaPage), findsOneWidget);
    expect(find.text('4821'), findsNothing);
  });
}
