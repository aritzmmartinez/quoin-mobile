import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';

RealizedReport realizedReportOf(PortfolioLedger ledger, DateTime now) {
  final jurisdiction = jurisdictionOf(ledger.residence);
  final zone = jurisdiction.zone;
  final names = {for (final i in ledger.instruments) i.id: i.name};
  String nameOf(String id) => names[id] ?? id;
  final years = listTaxYears(ledger.events, zone);

  return RealizedReport(
    hasLedger: ledger.events.isNotEmpty,
    sales: [
      for (final sale in computeRealizedGains(ledger.events, jurisdiction))
        SaleLine(
          sale: sale,
          name: nameOf(sale.instrumentId),
          year: fiscalYearOf(sale.ts, zone),
        ),
    ],
    names: names,
    events: ledger.events,
    history: computeTaxHistory(
      ledger.events,
      taxScopeFor(ledger.instruments, jurisdiction),
    ),
    taxYears: years,
    defaultYear: defaultTaxYear(years, zone, now),
    today: today(zone, now),
    noRate: [
      for (final id in unconvertibleInstrumentIds(ledger.events)) nameOf(id),
    ]..sort(compareNamesEs),
    unclassified: [
      for (final id in unclassifiedSoldIds(ledger.events, ledger.instruments))
        nameOf(id),
    ]..sort(compareNamesEs),
  );
}
