import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_theme.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/tax/domain/usecases/realized_report_of.dart';
import 'package:quoin/src/features/tax/presentation/widgets/tax_year_panel.dart';
import 'package:quoin_core/quoin_core.dart';

DividendEvent dividend(
  String id,
  String ts,
  String instrumentId,
  String gross,
  String withheld, {
  Funding funding = Funding.cash,
  String source = 'TEST',
}) => DividendEvent(
  id: id,
  ts: DateTime.parse(ts),
  instrumentId: instrumentId,
  grossAmount: Money.parse(gross),
  taxWithheld: Money.parse(withheld),
  currency: baseCurrency,
  funding: funding,
  account: 'test',
  source: source,
  externalId: id,
);

InterestEvent interest(String id, String ts, String gross, String withheld) =>
    InterestEvent(
      id: id,
      ts: DateTime.parse(ts),
      grossAmount: Money.parse(gross),
      taxWithheld: Money.parse(withheld),
      currency: baseCurrency,
      account: 'test',
      source: tradeRepublicSource,
      externalId: id,
    );

TradeEvent trade(
  TradeType type,
  String id,
  String ts,
  String instrumentId,
  String quantity,
  String gross,
) => TradeEvent(
  id: id,
  ts: DateTime.parse(ts),
  type: type,
  instrumentId: instrumentId,
  quantity: Dec.parse(quantity),
  price: Money.of(Dec.parse(gross).dividedBy(Dec.parse(quantity))),
  grossAmount: Money.parse(gross),
  fees: Money.zero,
  currency: baseCurrency,
  account: 'test',
  source: 'TEST',
  externalId: id,
);

Future<void> pumpPanel(
  WidgetTester tester,
  List<LedgerEvent> events,
  int year,
  DateTime now, {
  Residence residence = Residence.bizkaia,
}) async {
  final report = realizedReportOf(
    PortfolioLedger(
      residence: residence,
      instruments: const [
        Instrument(id: 'STOCK', name: 'Test Stock', type: 'STOCK'),
        Instrument(id: 'COIN', name: 'Test Coin', type: 'CRYPTO'),
      ],
      events: events,
      latestPrices: const {},
      rates: const [],
    ),
    now,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: quoinDarkTheme,
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: TaxYearPanel(
            report: report,
            view: report.taxYear(year),
            how: const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder rowWith(String label, String value) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
  matching: find.text(value),
);

void main() {
  testWidgets('a year with only income shows its pool, the exempt dividends, '
      'the withholdings and their notices, citing nothing', (tester) async {
    await pumpPanel(
      tester,
      [
        dividend('d', '2026-03-02T09:00:00Z', 'STOCK', '100', '19'),
        interest('i', '2026-07-01T09:00:00Z', '20', '0'),
        dividend(
          'r',
          '2026-06-01T09:00:00Z',
          'COIN',
          '4',
          '0',
          funding: Funding.inKind,
          source: 'KRAKEN_CSV',
        ),
      ],
      2026,
      DateTime.utc(2026, 11, 23),
    );

    expect(find.text('Impuesto estimado de 2026'), findsOneWidget);
    expect(find.text('3,80 €'), findsOneWidget);
    expect(rowWith('Saldo de ganancias y pérdidas', '0,00 €'), findsOne);
    expect(
      rowWith('Saldo de rendimientos del capital mobiliario', '+20,00 €'),
      findsOne,
    );
    expect(rowWith('Retenciones registradas', '19,00 €'), findsOne);
    expect(
      find.textContaining('Algún interés de este año no tiene retención'),
      findsOne,
    );

    expect(find.text('Rendimientos del capital mobiliario'), findsOne);
    expect(rowWith('Cobros', '2'), findsOne);
    expect(rowWith('Bruto del año', '120,00 €'), findsOne);
    expect(rowWith('Dividendos exentos', '100,00 €'), findsOne);
    expect(rowWith('Saldo tras el arrastre', '+20,00 €'), findsOne);
    expect(find.textContaining('exentos hasta 1500 € al año'), findsOne);
    expect(find.textContaining('Los intereses de diciembre'), findsOne);
    expect(find.textContaining('pero sí rendimientos'), findsOne);

    expect(find.text('Ingresos en especie'), findsOne);
    expect(rowWith('Recepciones', '1'), findsOne);

    expect(find.textContaining('Art.'), findsNothing);
  });

  testWidgets('a year after the last scale says the earlier one applies', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      [interest('i', '2027-02-01T09:00:00Z', '10', '1.9')],
      2027,
      DateTime.utc(2028, 3, 1),
    );

    expect(find.textContaining('escala de 2026', findRichText: true), findsOne);
    expect(
      find.textContaining('Se aplica la escala vigente desde 2026 en Bizkaia'),
      findsOne,
    );
    expect(find.textContaining('Algún interés'), findsNothing);
    expect(find.textContaining('Los intereses de diciembre'), findsNothing);
  });

  group('régimen común', () {
    final ledger = [
      trade(TradeType.buy, 'b1', '2024-01-10T09:00:00Z', 'STOCK', '10', '4000'),
      trade(
        TradeType.sell,
        's1',
        '2024-06-03T09:00:00Z',
        'STOCK',
        '10',
        '1000',
      ),
      trade(TradeType.buy, 'b2', '2025-01-10T09:00:00Z', 'STOCK', '10', '1000'),
      trade(TradeType.sell, 's2', '2025-06-02T09:00:00Z', 'STOCK', '10', '600'),
      dividend('d', '2025-07-01T09:00:00Z', 'STOCK', '2000', '380'),
    ];

    testWidgets('the pools cross, line by line, within one 25% a year', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        ledger,
        2025,
        DateTime.utc(2026, 3, 1),
        residence: Residence.comun,
      );

      expect(find.text('285,00 €'), findsOne, reason: '1500 × 19%');
      expect(rowWith('Cruce del año', '+400,00 €'), findsOne);
      expect(find.text('Cruce del año'), findsNWidgets(2));
      expect(find.text('De la otra bolsa, años anteriores'), findsOne);
      expect(find.textContaining('hasta el 25 % de ese positivo'), findsOne);
      expect(find.textContaining('Un saldo negativo compensa'), findsOne);
      expect(find.text('Dividendos exentos'), findsNothing);
      expect(find.textContaining('Art.'), findsNothing);
    });

    testWidgets('the same ledger in Bizkaia keeps the pools apart', (
      tester,
    ) async {
      await pumpPanel(tester, ledger, 2025, DateTime.utc(2026, 3, 1));

      expect(find.text('Cruce del año'), findsNothing);
      expect(find.text('De la otra bolsa, años anteriores'), findsNothing);
      expect(find.textContaining('solo dentro de su propia bolsa'), findsOne);
    });

    testWidgets('a crypto loss rebought within the year notes art. 33.5.e', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        [
          trade(
            TradeType.buy,
            'b',
            '2025-01-10T12:00:00Z',
            'COIN',
            '1',
            '1000',
          ),
          trade(
            TradeType.sell,
            's',
            '2025-03-03T12:00:00Z',
            'COIN',
            '1',
            '700',
          ),
          trade(TradeType.buy, 'r', '2025-04-01T12:00:00Z', 'COIN', '1', '720'),
        ],
        2025,
        DateTime.utc(2026, 3, 1),
        residence: Residence.canarias,
      );
      await tester.ensureVisible(find.text('Test Coin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Coin'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Podría aplicarse el art. 33.5.e'), findsOne);
      expect(
        find.textContaining('Criptomoneda vendida antes de 2025'),
        findsNothing,
      );
    });
  });
}
