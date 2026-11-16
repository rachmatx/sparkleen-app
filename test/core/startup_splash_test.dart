import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/main.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/app_card.dart';
import 'package:sparkleen_mobile/features/auth/application/auth_controller.dart';
import 'package:sparkleen_mobile/features/auth/presentation/login_page.dart';
import 'package:sparkleen_mobile/features/splash/splash_page.dart';

import '../support/auth_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  testWidgets(
    'fast login initialization still displays splash for two seconds',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: const SparkleenApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1999));
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'default and colored glass both use 75 percent opacity / $brightness',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(brightness: brightness),
            home: const Scaffold(
              body: Column(
                children: [
                  AppCard(child: Text('Default glass')),
                  AppCard(color: Colors.blue, child: Text('Colored glass')),
                ],
              ),
            ),
          ),
        );
        final cards = find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(Material),
        );
        expect(cards, findsNWidgets(2));
        for (final element in cards.evaluate()) {
          expect((element.widget as Material).color!.a, closeTo(.75, .001));
        }
      },
    );
  }
}
