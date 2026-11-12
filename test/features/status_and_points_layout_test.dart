import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/status_chip.dart';
import 'package:sparkleen_mobile/features/loyalitas/data/loyalty_repository.dart';
import 'package:sparkleen_mobile/features/loyalitas/presentation/loyalty_page.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  for (final mode in Brightness.values) {
    testWidgets('statuses are plain text with semantic colors / $mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(brightness: mode),
          home: const Scaffold(
            body: Column(
              children: [
                StatusChip(status: 'menunggu', label: 'Diterima'),
                StatusChip(status: 'lunas', label: 'Lunas'),
                StatusChip(status: 'proses', label: 'Diproses'),
              ],
            ),
          ),
        ),
      );
      for (final status in ['menunggu', 'lunas', 'proses']) {
        final badge = find.byWidgetPredicate(
          (w) => w is StatusChip && w.status == status,
        );
        expect(
          find.descendant(of: badge, matching: find.byType(Container)),
          findsNothing,
        );
        expect(
          find.descendant(of: badge, matching: find.byType(Icon)),
          findsNothing,
        );
        final text = tester.widget<Text>(
          find.descendant(of: badge, matching: find.byType(Text)),
        );
        expect(text.style!.color, statusColor(status, brightness: mode));
      }
    });
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'point delta and date share the right content edge / $mode / $scale',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness: mode),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PointMovementTile(
                    item: PointMovement(
                      id: 1,
                      orderId: 1,
                      delta: 4,
                      balanceAfter: 10,
                      reason: 'Poin pesanan baru',
                      nota: 'LAU/20261112/0003',
                      createdAt: DateTime(2026, 11, 12),
                    ),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final amount = tester.getRect(
            find.byKey(const ValueKey('point-delta-1')),
          );
          final date = tester.getRect(
            find.byKey(const ValueKey('point-date-1')),
          );
          final tile = tester.getRect(find.byType(PointMovementTile));
          expect(amount.right, closeTo(tile.right - 14, 1));
          expect(date.right, closeTo(amount.right, 1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
