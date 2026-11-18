import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';

void main() {
  Widget app(Widget child, {double scale = 1}) => MaterialApp(
    theme: quoinDarkTheme,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  );

  testWidgets('says what it is, what to do, and offers the way out', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      app(
        EmptyState(
          icon: QuoinIcons.portfolio,
          title: 'Sin posiciones todavía',
          body: 'Importa el CSV de tu bróker.',
          actionLabel: 'Importar CSV',
          onAction: () => tapped = true,
        ),
      ),
    );
    expect(find.text('Sin posiciones todavía'), findsOneWidget);
    expect(find.text('Importa el CSV de tu bróker.'), findsOneWidget);
    await tester.tap(find.text('Importar CSV'));
    expect(tapped, isTrue);
  });

  testWidgets('scrolls instead of overflowing in a short space at 200 %', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const SizedBox(
          height: 200,
          child: EmptyState(
            icon: QuoinIcons.alert,
            title: 'No se ha podido leer la cartera',
            body:
                'Vuelve a abrir esta pantalla. Si sigue sin cargarse, '
                'cierra Quoin y ábrelo de nuevo.',
            negative: true,
          ),
        ),
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out inside a page that already scrolls', (tester) async {
    await tester.pumpWidget(
      app(
        const SingleChildScrollView(
          child: EmptyState(
            icon: QuoinIcons.portfolio,
            title: 'Sin movimientos todavía',
            body: 'Importa el CSV.',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
