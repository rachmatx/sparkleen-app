import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/theme/app_theme.dart';
import 'package:sparkleen_mobile/core/widgets/app_text_field.dart';

void main() {
  testWidgets(
    'placeholder is visible before focus; label and adornments survive',
    (tester) async {
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Form(
              key: form,
              child: AppTextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon',
                  hintText: '0812xxxxxxx',
                  prefixText: '+62 ',
                  helperText: 'Nomor aktif',
                  suffixIcon: Icon(Icons.check),
                ),
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Isi nomor telepon.' : null,
              ),
            ),
          ),
        ),
      );
      final hint = find.text('0812xxxxxxx');
      final opacity = find.ancestor(
        of: hint,
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(opacity.first).opacity, 1);
      expect(find.text('Nomor telepon'), findsOneWidget);
      expect(find.text('Nomor aktif'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Isi nomor telepon.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '8123456789');
      expect(form.currentState!.validate(), isTrue);
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(opacity.first).opacity, 0);
      expect(find.text('Nomor telepon'), findsOneWidget);
      expect(find.text('Isi nomor telepon.'), findsNothing);
    },
  );
}
