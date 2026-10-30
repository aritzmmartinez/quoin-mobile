import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/ui/molecules/quoin_text_field.dart';

Future<void> _pump(WidgetTester tester, Widget field) => tester.pumpWidget(
  MaterialApp(
    theme: quoinLightTheme,
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(20), child: field),
    ),
  ),
);

void main() {
  testWidgets('the label is shown above and read with the field', (
    tester,
  ) async {
    await _pump(tester, const QuoinTextField(label: 'Horizonte', hint: '10'));
    expect(find.text('Horizonte'), findsOneWidget);
    final node = tester.getSemantics(find.byType(TextField));
    expect(node.label, startsWith('Horizonte'));
    expect(node, isSemantics(isTextField: true));
  });

  testWidgets('shows the unit, the help and the error in negative', (
    tester,
  ) async {
    await _pump(
      tester,
      const QuoinTextField(
        label: 'Horizonte',
        unit: 'años',
        help: 'Ayuda',
        error: 'Entre 1 y 50 años.',
      ),
    );
    expect(find.text('años'), findsOneWidget);
    final error = tester.widget<Text>(find.text('Entre 1 y 50 años.'));
    expect(error.style?.color, QuoinColors.light.negative);
  });

  testWidgets('multiline takes the card radius, one line is a pill', (
    tester,
  ) async {
    BorderRadius radius() =>
        (tester
                    .widget<TextField>(find.byType(TextField))
                    .decoration!
                    .enabledBorder
                as OutlineInputBorder?)
            ?.borderRadius ??
        BorderRadius.zero;
    await _pump(tester, const QuoinTextField(label: 'Nota', maxLines: 4));
    expect(radius(), BorderRadius.circular(24));
    await _pump(tester, const QuoinTextField(label: 'Nombre'));
    expect(radius(), BorderRadius.zero);
  });

  testWidgets('search: short hint, full description for screen readers', (
    tester,
  ) async {
    await _pump(
      tester,
      const QuoinTextField.search(label: 'Buscar por ISIN o nombre'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Buscar por ISIN o nombre'), findsNothing);
    final node = tester.getSemantics(find.byType(TextField));
    expect(node.label, startsWith('Buscar por ISIN o nombre'));
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.prefixIcon, isNotNull);
  });
}
