import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:quoin/src/ui/molecules/allocation_donut.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

void main() {
  testWidgets('home shows the total, the allocation and the top five', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);

    expect(find.text('Patrimonio total'), findsOneWidget);
    expect(find.textContaining('2 sin valorar'), findsOneWidget);
    expect(
      find.text(
        'Sin tipo de cambio reciente, quedan sin valorar: '
        'Ejemplo Tecnología Inc.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AllocationDonut), findsOneWidget);
    expect(find.text('Sin clasificar'), findsOneWidget);
    expect(find.byType(PositionRow), findsNWidgets(5));

    await tester.ensureVisible(find.text('Ver todas'));
    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();
    expect(find.byType(PortfolioPage), findsOneWidget);
  });

  testWidgets('portfolio filters by category and names the unpriced', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
    await tester.tap(
      find.descendant(
        of: find.byType(QuoinBottomBar),
        matching: find.text('Cartera'),
      ),
    );
    await tester.pumpAndSettle();

    // Eight open positions; the closed one is gone.
    expect(find.textContaining('8 posiciones'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sin precio').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sin precio'), findsWidgets);

    await tester.tap(find.text('Cripto'));
    await tester.pumpAndSettle();
    expect(find.byType(PositionRow), findsNWidgets(2));

    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alfabético'));
    await tester.pumpAndSettle();
    final names = tester
        .widgetList<PositionRow>(find.byType(PositionRow))
        .map((row) => row.name);
    expect(names, ['Moneda Ejemplo', 'Token Ejemplo']);
  });

  test('a notice closes its sentence once', () {
    for (final locale in const [Locale('es'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.fxUnrated('Acme', 'none'), endsWith(': Acme.'));
      expect(l10n.fxUnrated('Tesla Inc.', 'dot'), endsWith(': Tesla Inc.'));
      expect(l10n.fxUnconvertible('Acme', 'none'), endsWith(': Acme.'));
      expect(
        l10n.fxUnconvertible('Acme, Tesla Inc.', 'dot'),
        endsWith(': Acme, Tesla Inc.'),
      );
    }
  });

  testWidgets('with nothing imported both screens show the empty state', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    expect(find.text('Aún no has importado ningún movimiento'), findsOneWidget);
    expect(find.text('Patrimonio total'), findsNothing);
  });
}
