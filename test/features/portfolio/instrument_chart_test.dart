import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/price_chart_section.dart';
import 'package:quoin/src/ui/organisms/quoin_line_chart.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';
import 'package:quoin_core/quoin_core.dart' show shiftDay;

import '../../helpers.dart';

const _fund = 'IE00QSAMPLE1';
const _coin = 'QSAMPLECOIN';

Future<void> _series(
  PricesDatabase prices,
  String id, {
  bool kraken = false,
}) => prices.batch((batch) {
  batch.insertAll(prices.priceSnapshot, [
    for (var i = 0; i < 450; i++)
      PriceSnapshotCompanion.insert(
        id: 'test-$id-$i',
        instrumentId: id,
        price:
            '${80 + (i * 7) % 31}.${(i * 13 % 100).toString().padLeft(2, '0')}',
        currency: 'EUR',
        asOf: DateTime.parse('${shiftDay('2026-10-29', i - 449)}T21:00:00Z'),
        source: Value(kraken ? 'KRAKEN' : 'YAHOO'),
        createdAt: testNow,
      ),
  ]);
});

Future<void> _open(
  WidgetTester tester,
  String id, {
  String locale = 'es',
  bool kraken = false,
  bool series = true,
}) async {
  final stores = await sampleStores();
  if (series) await _series(stores.prices, id, kraken: kraken);
  await pumpApp(
    tester,
    prefs: {'locale': locale},
    database: stores.database,
    prices: stores.prices,
  );
  unawaited(
    GoRouter.of(tester.element(find.byType(QuoinPage).first))
        .push(Routes.instrument(id)),
  );
  await tester.pumpAndSettle();
  if (!series) return;
  await tester.scrollUntilVisible(
    find.byType(QuoinLineChart),
    200,
    scrollable: find
        .descendant(
          of: find.byType(QuoinPage).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

String _header(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(
      of: find.byType(PriceChartSection),
      matching: find.byType(Text),
    ),
  ))
    t.textSpan?.toPlainText() ?? t.data ?? '',
].join(' | ');

QuoinLineChart _chart(WidgetTester tester) =>
    tester.widget<QuoinLineChart>(find.byType(QuoinLineChart));

void main() {
  testWidgets('a period chip changes the period, the header and the summary', (
    tester,
  ) async {
    await _open(tester, _fund);
    expect(_header(tester), contains('último año'));
    expect(_chart(tester).semanticLabel, contains('último año'));
    final yearLength = _chart(tester).points.length;

    await tester.tap(find.text('1M'));
    await tester.pumpAndSettle();
    expect(_header(tester), contains('último mes'));
    expect(
      _chart(tester).semanticLabel,
      startsWith('Fondo Global Indexado, último mes, de '),
    );
    expect(_chart(tester).points.length, lessThan(yearLength));
  });

  testWidgets('dragging along the chart puts that day in the header', (
    tester,
  ) async {
    await _open(tester, _fund);
    final box = tester.getRect(find.byType(QuoinLineChart));
    final gesture = await tester.startGesture(box.center);
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(_header(tester), isNot(contains('último año')));
    expect(_header(tester), matches(RegExp(r'\d{1,2} \w+ 202\d')));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_header(tester), contains('último año'));
  });

  testWidgets('trades are marks the screen reader can open', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, _fund);
    final marks = find.semantics.byLabel(
      RegExp(r'^Compra, \d{1,2} \w+ \d{4}$'),
    );
    expect(marks, findsExactly(2));
    expect(find.byType(BottomSheet), findsNothing);
    tester.semantics.tap(marks.first);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    semantics.dispose();
  });

  for (final (locale, label) in [
    ('es', RegExp('^Tu precio medio · [0-9.]+,[0-9]{2} €\$')),
    ('en', RegExp(r'^Your average price · €[0-9,]+\.[0-9]{2}$')),
  ]) {
    testWidgets('label and figures share the language in $locale', (
      tester,
    ) async {
      await _open(tester, _fund, locale: locale);
      expect(_chart(tester).reference!.label, matches(label));
      final euro = locale == 'es' ? RegExp(r',\d{2} €') : RegExp(r'€\d');
      expect(_chart(tester).semanticLabel, contains(euro));
      expect(
        _chart(tester).formatValue(_chart(tester).points.first.value),
        contains(euro),
      );
    });
  }

  testWidgets(
    'Kraken data says so once, under the chart, even when the PC sent it',
    (tester) async {
      await _open(tester, _coin, kraken: true);
      expect(find.text('Market Data: Kraken'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PriceChartSection),
          matching: find.text('Market Data: Kraken'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('one price is no chart, as before', (tester) async {
    await _open(tester, _fund, series: false);
    expect(find.byType(QuoinLineChart), findsNothing);
    expect(
      find.text(
        'Todavía no hay histórico de precios para dibujar su evolución.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the chart fits at 200 % text size', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, _fund);
    for (final chip in ['1M', '6M', 'Máx']) {
      await tester.ensureVisible(find.text(chip));
      await tester.tap(find.text(chip));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
