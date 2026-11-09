import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/core/theme/app_assets.dart';
import 'package:sparkleen_mobile/core/widgets/app_artwork.dart';
import 'package:sparkleen_mobile/core/widgets/async_value_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all nine production images are included in the asset bundle', () async {
    for (final asset in [
      AppAssets.brandMark,
      AppAssets.points,
      AppAssets.home,
      AppAssets.login,
      AppAssets.emptyActiveOrder,
      AppAssets.emptyOrderHistory,
      AppAssets.connectionError,
      AppAssets.cuciKering,
      AppAssets.cuciSetrika,
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  testWidgets('full-width artwork resolves finite decode dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: IllustrationPanel(
              asset: AppAssets.login,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(IllustrationPanel)).width, 320);
  });

  testWidgets('a missing image falls back without breaking the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppArtwork(
            asset: 'assets/not-present.png',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.local_laundry_service_outlined), findsOneWidget);
  });

  testWidgets('only network errors display the disconnected illustration', (
    tester,
  ) async {
    Widget errorPage(String code) => MaterialApp(
      home: Scaffold(
        body: ErrorState(
          error: ApiException(code: code, message: 'Silakan coba lagi.'),
        ),
      ),
    );

    await tester.pumpWidget(errorPage('NETWORK_ERROR'));
    expect(find.byType(IllustrationPanel), findsOneWidget);

    await tester.pumpWidget(errorPage('HTTP_500'));
    expect(find.byType(IllustrationPanel), findsNothing);
    expect(find.text('Silakan coba lagi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
