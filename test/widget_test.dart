import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/providers.dart';
import 'package:sparkleen_mobile/core/storage/token_storage.dart';
import 'package:sparkleen_mobile/main.dart';

class _PendingTokenStorage extends TokenStorage {
  final _completer = Completer<String?>();

  @override
  Future<String?> read() => _completer.future;
}

void main() {
  testWidgets('app membuka splash selama status auth belum diketahui', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_PendingTokenStorage()),
        ],
        child: const SparkleenApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Sparkleen'), findsOneWidget);
    expect(find.text('Laundry jadi ringan'), findsOneWidget);
  });
}
