import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/profil/presentation/profil_page.dart';

import '../support/auth_fakes.dart';

void main() {
  testWidgets(
    'profil menampilkan data pelanggan dan keluar mengosongkan sesi',
    (tester) async {
      final repository = FakeAuthRepository();
      final storage = FakeTokenStorage('token-aktif');
      final container = ProviderContainer.test(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfilPage()),
        ),
      );
      await tester.pump();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('PLG012'), findsOneWidget);
      expect(find.text('6281298765432'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('4 transaksi'), findsOneWidget);
      expect(find.text('Rp 4'), findsNothing);

      await tester.scrollUntilVisible(find.text('Keluar Akun'), 200);
      await tester.tap(find.text('Keluar Akun'));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      await tester.tap(find.text('Keluar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.logoutCalls, 1);
      expect(
        container.read(authControllerProvider).value,
        isA<AuthUnauthenticated>(),
      );
    },
  );
}
