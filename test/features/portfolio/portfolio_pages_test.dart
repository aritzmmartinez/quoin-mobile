import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:quoin/src/ui/molecules/allocation_donut.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

void main() {
  testWidgets('home shows the total, the allocation and the top five', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: await sampleDatabase(),
    );

    expect(find.text('Patrimonio total'), findsOneWidget);
    expect(find.textContaining('1 sin valorar'), findsOneWidget);
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
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: await sampleDatabase(),
    );
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
      find.text('Sin precio'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sin precio'), findsOneWidget);

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

  testWidgets('with nothing imported both screens show the empty state', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    expect(find.text('Aún no has importado ningún movimiento'), findsOneWidget);
    expect(find.text('Patrimonio total'), findsNothing);
  });
}
