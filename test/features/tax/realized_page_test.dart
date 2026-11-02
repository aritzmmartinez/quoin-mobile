import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/tax/presentation/pages/realized_page.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

Future<void> openRealized(WidgetTester tester) async {
  await pumpApp(
    tester,
    prefs: {'locale': 'es'},
    database: await sampleDatabase(),
  );
  await tester.tap(
    find.descendant(
      of: find.byType(QuoinBottomBar),
      matching: find.text('Análisis'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Realizado'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home leads to the year realised so far', (tester) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: await sampleDatabase(),
    );
    await tester.scrollUntilVisible(
      find.text('Realizado en 2026'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Realizado en 2026'));
    await tester.pumpAndSettle();
    expect(find.byType(RealizedPage), findsOneWidget);
  });

  testWidgets('sales come by year, on the AVCO basis', (tester) async {
    await openRealized(tester);

    expect(find.textContaining('4 ventas en 2026 · coste'), findsOneWidget);
    final names = tester
        .widgetList<SaleRow>(find.byType(SaleRow))
        .map((row) => row.name);
    expect(names.first, 'Salud Mundial', reason: 'newest first');

    await tester.tap(find.text('A–Z'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<SaleRow>(find.byType(SaleRow))
          .map((r) => r.name)
          .take(4),
      [
        'Bonos Euro Gobierno',
        'Fondo Emergentes',
        'Moneda Ejemplo',
        'Salud Mundial',
      ],
    );
  });

  testWidgets('the tax view defers the repurchased loss and cites nothing up '
      'front', (tester) async {
    await openRealized(tester);
    await tester.tap(find.text('Fiscal (Bizkaia)'));
    await tester.pumpAndSettle();

    expect(find.text('Base liquidable del ahorro'), findsOneWidget);
    expect(find.text('Escala del ahorro de Bizkaia 2026'), findsOneWidget);
    expect(find.textContaining('Art.'), findsNothing);

    await tester.tap(find.text('Cómo se ha calculado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Art. 43'), findsOneWidget);
    expect(
      find.textContaining('no vinculan a la Hacienda Foral'),
      findsOneWidget,
    );
    expect(find.textContaining('Criterios propios de Quoin'), findsOneWidget);
    expect(find.textContaining('art. 47.1.i y 47.1.p'), findsOneWidget);

    final repurchased = find.widgetWithText(SaleRow, 'Fondo Emergentes');
    await tester.scrollUntilVisible(
      repurchased,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<SaleRow>(repurchased).badge, 'Recompra');
    expect(
      find.textContaining('queda diferida en las uds recompradas'),
      findsOneWidget,
    );
    expect(find.textContaining('no deducible'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('INGRESOS EN ESPECIE'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  });
}
