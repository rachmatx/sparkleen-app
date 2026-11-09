import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/app_card.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/presentation/login_page.dart';

import '../support/auth_fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late FakeTokenStorage storage;

  Widget buildPage() {
    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const LoginPage()),
    );
  }

  setUp(() {
    repository = FakeAuthRepository();
    storage = FakeTokenStorage();
  });

  testWidgets('latar login mengisi viewport yang lebih tinggi dari formulir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(tester.getSize(find.byType(AppBackdrop)), const Size(390, 1100));
  });

  testWidgets('PIN kurang dari 6 digit menampilkan validasi tanpa submit', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '081298765432');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();

    expect(find.text('PIN harus 6 digit angka.'), findsOneWidget);
    expect(repository.loginCalls, 0);
  });

  testWidgets('login gagal menampilkan pesan error dari server', (
    tester,
  ) async {
    repository.loginError = const ApiException(
      code: 'AUTH_INVALID_CREDENTIALS',
      message: 'Nomor telepon atau PIN salah.',
      statusCode: 401,
    );

    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '081298765432');
    await tester.enterText(find.byType(TextFormField).at(1), '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    await tester.pump();

    expect(repository.loginCalls, 1);
    expect(find.text('Nomor telepon atau PIN salah.'), findsOneWidget);
  });
}
