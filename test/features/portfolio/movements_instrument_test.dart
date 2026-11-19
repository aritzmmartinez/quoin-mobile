import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/movements_of.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/instrument_page.dart';
import 'package:quoin/src/features/portfolio/presentation/pages/movements_page.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
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

  test('months add the cash moved, leaving swaps out', () {
    final rows = movementsOf(
      PortfolioLedger(
        residence: Residence.bizkaia,
        instruments: const [],
        events: [
          trade('a', '2026-01-31T23:30:00Z', TradeType.buy, '100'),
          trade('b', '2026-01-10T09:00:00Z', TradeType.sell, '40', fees: '1'),
          trade('c', '2026-01-12T09:00:00Z', TradeType.sell, '500', swap: 's'),
        ],
        latestPrices: const {},
        rates: const [],
      ),
    );
    final months = byMonth(rows, 'Europe/Madrid');
    expect(months.map((m) => '${m.month}'), ['2026-02-01', '2026-01-01']);
    expect(months.map((m) => '${m.net}'), ['-100', '39']);
  });

  test('a month follows the residence calendar, not the device', () {
    final rows = movementsOf(
      PortfolioLedger(
        residence: Residence.bizkaia,
        instruments: const [],
        events: [
          trade('a', '2026-03-31T22:30:00Z', TradeType.buy, '100'),
          trade('b', '2026-03-10T12:00:00Z', TradeType.buy, '50'),
        ],
        latestPrices: const {},
        rates: const [],
      ),
    );
    expect(byMonth(rows, 'Europe/Madrid').map((m) => '${m.month}'), [
      '2026-04-01',
      '2026-03-01',
    ]);
    expect(byMonth(rows, 'America/New_York').map((m) => '${m.month}'), [
      '2026-03-01',
    ]);
  });

  testWidgets('movements filter by type and instrument', (tester) async {
    await openPortfolio(tester);
    await tester.tap(find.text('Movimientos'));
    await tester.pumpAndSettle();
    expect(find.byType(MovementsPage), findsOneWidget);
    expect(find.byType(GroupHeader), findsWidgets);

    await tester.tap(find.text('Todos los tipos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venta').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<MovementRow>(find.byType(MovementRow))
          .every(
            (r) =>
                r.detail.startsWith('Venta · ') ||
                r.detail.startsWith('Permuta · '),
          ),
      isTrue,
    );

    await tester.tap(find.text('Todos los instrumentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salud Mundial').last);
    await tester.pumpAndSettle();
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
    expect(
      find.textContaining('sobre lo que te costó', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Tienes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ver todos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Ver todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();
    expect(find.byType(MovementsPage), findsOneWidget);
    expect(find.byType(MovementRow), findsNWidgets(3));
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
