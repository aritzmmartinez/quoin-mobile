import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/movements_of.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/instrument_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/movements_page.dart';
import 'package:quoin/src/ui/molecules/movement_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

TradeEvent trade(
  String id,
  String ts,
  TradeType type,
  String gross, {
  String fees = '0',
  String? swap,
}) => TradeEvent(
  id: id,
  ts: DateTime.parse(ts),
  type: type,
  instrumentId: 'X',
  quantity: Dec.one,
  price: Money.parse(gross),
  grossAmount: Money.parse(gross),
  fees: Money.parse(fees),
  currency: baseCurrency,
  linkId: swap,
  linkKind: swap == null ? null : 'swap',
  account: 'test',
  source: 'TEST',
  externalId: id,
);

Future<void> openPortfolio(WidgetTester tester) async {
  await pumpApp(tester, prefs: {'locale': 'es'}, sample: true);
  await tester.tap(
    find.descendant(
      of: find.byType(QuoinBottomBar),
      matching: find.text('Cartera'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('movements: newest first, ties by source id, cash signed', () {
    final rows = movementsOf(
      PortfolioLedger(
        residence: Residence.bizkaia,
        instruments: const [],
        events: [
          trade('b', '2026-01-01T09:00:00Z', TradeType.buy, '100', fees: '1'),
          trade('c', '2026-01-02T09:00:00Z', TradeType.sell, '50', fees: '1'),
          trade('a', '2026-01-02T09:00:00Z', TradeType.buy, '10', swap: 's'),
        ],
        latestPrices: const {},
        rates: const [],
      ),
    );
    expect(rows.map((r) => r.id), ['a', 'c', 'b']);
    expect(rows.map((r) => '${r.amount}'), ['10', '49', '-101']);
    expect(rows.first.isSwap, isTrue, reason: 'unpaired leg, still a swap');
  });

  testWidgets('movements filter by type and instrument', (tester) async {
    await openPortfolio(tester);
    await tester.tap(find.byTooltip('Movimientos'));
    await tester.pumpAndSettle();
    expect(find.byType(MovementsPage), findsOneWidget);
    expect(find.text('22 movimientos'), findsOneWidget);

    await tester.tap(find.text('Venta').first);
    await tester.pumpAndSettle();
    expect(find.text('5 movimientos'), findsOneWidget);

    await tester.tap(find.text('Todos los instrumentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salud Mundial').last);
    await tester.pumpAndSettle();
    expect(find.text('1 movimiento'), findsOneWidget);
    expect(find.byType(MovementRow), findsOneWidget);
  });

  testWidgets('a position opens its page, and its movements from there', (
    tester,
  ) async {
    await openPortfolio(tester);
    await tester.tap(find.text('Fondo Global Indexado'));
    await tester.pumpAndSettle();
    expect(find.byType(InstrumentPage), findsOneWidget);
    expect(find.textContaining('8131,50'), findsOneWidget);
    expect(find.text('Precio medio'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ver movimientos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Ver movimientos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver movimientos'));
    await tester.pumpAndSettle();
    expect(find.text('3 movimientos'), findsOneWidget);
  });

  testWidgets('an unpriced position says so instead of a value', (
    tester,
  ) async {
    await openPortfolio(tester);
    await tester.scrollUntilVisible(
      find.text('Fondo Emergentes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Fondo Emergentes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fondo Emergentes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sin precio todavía: la app aún no descarga cotizaciones.'),
      findsOneWidget,
    );
  });
}
