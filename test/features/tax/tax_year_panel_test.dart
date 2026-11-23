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

Future<void> pumpPanel(
  WidgetTester tester,
  List<LedgerEvent> events,
  int year,
  DateTime now,
) async {
  final report = realizedReportOf(
    PortfolioLedger(
      residence: Residence.bizkaia,
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

    expect(
      find.textContaining('escala de Bizkaia 2026', findRichText: true),
      findsOne,
    );
    expect(
      find.textContaining('Se aplica la escala vigente desde 2026'),
      findsOne,
    );
    expect(find.textContaining('Algún interés'), findsNothing);
    expect(find.textContaining('Los intereses de diciembre'), findsNothing);
  });
}
