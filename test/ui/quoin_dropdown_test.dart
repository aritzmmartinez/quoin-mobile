import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/organisms/quoin_dropdown.dart';

void main() {
  testWidgets('shows the chosen option and picks another from the sheet', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinLightTheme,
        home: Scaffold(
          body: Center(
            child: QuoinDropdown<String?>(
              label: 'Categoría',
              value: null,
              options: const [
                (value: null, label: 'Todas las categorías'),
                (value: 'CRYPTO', label: 'Cripto'),
              ],
              onChanged: (v) => picked = v,
            ),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(QuoinDropdown<String?>));
    expect(node.label, 'Categoría');
    expect(node.value, 'Todas las categorías');

    await tester.tap(find.text('Todas las categorías'));
    await tester.pumpAndSettle();
    expect(find.text('Categoría'), findsOneWidget, reason: 'the sheet title');
    await tester.tap(find.text('Cripto'));
    await tester.pumpAndSettle();
    expect(picked, 'CRYPTO');
    semantics.dispose();
  });

  testWidgets('dismissing the sheet changes nothing', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: quoinDarkTheme,
        home: Scaffold(
          body: Center(
            child: QuoinDropdown<int>(
              label: 'Orden',
              value: 0,
              options: const [(value: 0, label: 'Por valor')],
              onChanged: (_) => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Por valor'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
}
