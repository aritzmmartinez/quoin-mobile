import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/instrument_page.dart';
import 'package:quoin/src/features/settings/data/datasources/residence_local_datasource.dart';
import 'package:quoin/src/features/settings/data/repositories/residence_repository_impl.dart';
import 'package:quoin/src/features/tax/presentation/pages/realized_page.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

Future<void> openRealized(WidgetTester tester) async {
  await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
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
  for (final (:locale, :analysis, :realized, :tab, :line, :settings) in [
    (
      locale: 'es',
      analysis: 'Análisis',
      realized: 'Realizado',
      tab: 'Fiscal (Bizkaia)',
      line:
          'Calculado con las reglas de Bizkaia. Puedes cambiar tu residencia '
          'fiscal en Ajustes.',
      settings: 'Ajustes',
    ),
    (
      locale: 'en',
      analysis: 'Analysis',
      realized: 'Realized',
      tab: 'Tax (Bizkaia)',
      line:
          "Calculated with Bizkaia's rules. You can change your tax residence "
          'in Settings.',
      settings: 'Settings',
    ),
  ]) {
    Future<void> openTax(WidgetTester tester, {required bool chosen}) async {
      final stores = await sampleStores();
      if (chosen) {
        await ResidenceRepositoryImpl(ResidenceLocalDataSource(stores.database))
            .set(Residence.bizkaia);
      }
      await pumpApp(
        tester,
        prefs: {'locale': locale},
        database: stores.database,
        prices: stores.prices,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(QuoinBottomBar),
          matching: find.text(analysis),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(realized));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }

    testWidgets('$locale: a residence never chosen says the view runs on '
        "Bizkaia's rules and leads to Settings", (tester) async {
      await openTax(tester, chosen: false);
      expect(find.text(line), findsOneWidget);

      await tester.tap(find.text(line));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(QuoinPage),
          matching: find.text(settings),
        ),
        findsOneWidget,
      );
    });

    testWidgets('$locale: once chosen, even Bizkaia, the line is gone', (
      tester,
    ) async {
      await openTax(tester, chosen: true);
      expect(find.text(tab), findsOneWidget);
      expect(find.text(line), findsNothing);
    });
  }

  testWidgets('home leads to the year realised so far', (tester) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
    await tester.scrollUntilVisible(
      find.text('Realizado 2026'),
      200,
      scrollable: verticalLists.first,
    );
    await tester.tap(find.text('Realizado 2026'));
    await tester.pumpAndSettle();
    expect(find.byType(RealizedPage), findsOneWidget);
  });

  testWidgets('sales come by year, on the AVCO basis', (tester) async {
    await openRealized(tester);

    expect(find.text('Resultado de 2026'), findsOneWidget);
    expect(find.textContaining('4 ventas · coste '), findsOneWidget);
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

  testWidgets('a sale opens its sheet, which leads to the instrument', (
    tester,
  ) async {
    await openRealized(tester);
    await tester.tap(find.widgetWithText(SaleRow, 'Salud Mundial'));
    await tester.pumpAndSettle();
    expect(find.text('Has recibido'), findsOneWidget);
    expect(find.text('Te había costado'), findsOneWidget);
    expect(find.textContaining('El coste usa el precio medio'), findsOneWidget);

    await tester.tap(find.text('Ver la ficha del instrumento'));
    await tester.pumpAndSettle();
    expect(find.byType(InstrumentPage), findsOneWidget);
    expect(find.text('Has recibido'), findsNothing);
  });

  testWidgets('the tax view defers the repurchased loss and cites nothing up '
      'front', (tester) async {
    await openRealized(tester);
    await tester.tap(find.text('Fiscal (Bizkaia)'));
    await tester.pumpAndSettle();

    expect(find.text('Impuesto estimado de 2026'), findsOneWidget);
    expect(
      find.textContaining('escala de 2026', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Cuenta este año'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Aplazado por recompra'),
          matching: find.byType(Row),
        ),
        matching: find.text('+25,90 €'),
      ),
      findsOneWidget,
    );
    expect(find.text('Base del ahorro'), findsOneWidget);
    expect(find.textContaining('Art.'), findsNothing);

    await tester.ensureVisible(find.text('Cómo se calcula'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cómo se calcula'));
    await tester.pumpAndSettle();
    expect(
      find.text('Según la Norma Foral 13/2013 del IRPF de Bizkaia.'),
      findsOneWidget,
    );
    expect(find.text('Art. 43 NF 13/2013'), findsOneWidget);
    expect(find.text('Arts. 47.1.i y 47.1.p'), findsOneWidget);
    expect(find.text('Art. 66.1.b NF 13/2013'), findsOneWidget);
    final detail = find.text('Los criterios en detalle');
    await tester.ensureVisible(detail);
    await tester.pumpAndSettle();
    await tester.tap(detail);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no vinculan a la Hacienda Foral'),
      findsOneWidget,
    );
    expect(find.textContaining('Criterios propios de Quoin'), findsOneWidget);
    expect(find.textContaining('(Arts. 47.1.i y 47.1.p)'), findsOneWidget);
    expect(
      find.textContaining('Escala aplicada: Art. 76 NF 13/2013'),
      findsOneWidget,
    );
    Navigator.of(tester.element(detail)).pop();
    await tester.pumpAndSettle();

    final repurchased = find.widgetWithText(SaleRow, 'Fondo Emergentes');
    await tester.scrollUntilVisible(
      repurchased,
      200,
      scrollable: verticalLists.first,
    );
    final row = tester.widget<SaleRow>(repurchased);
    expect(row.tag, 'recompra');
    expect(row.note?.label, 'cuenta');

    await tester.tap(repurchased);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Recompraste', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Compras que se venden (FIFO)'), findsOneWidget);
    expect(find.text('Art. 43.g NF 13/2013 de Bizkaia'), findsOneWidget);
    expect(find.textContaining('uds'), findsNothing);
    expect(find.text('Ver la ficha del instrumento'), findsOneWidget);
    Navigator.of(tester.element(find.text('Art. 43.g NF 13/2013 de Bizkaia')))
        .pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ingresos en especie'),
      200,
      scrollable: verticalLists.first,
    );
  });
}
