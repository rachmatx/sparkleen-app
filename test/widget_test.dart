import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/main.dart';

void main() {
  testWidgets('app menampilkan splash saat dibuka', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SparkleenApp()));
    await tester.pump();

    expect(find.text('Sparkleen'), findsOneWidget);
    expect(find.text('Laundry jadi ringan'), findsOneWidget);
  });
}
