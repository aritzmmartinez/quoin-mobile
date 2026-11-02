import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';

class SaleLine {
  const SaleLine({required this.sale, required this.name, required this.year});

  final RealizedSale sale;
  final String name;
  final int year;
}

enum SaleOrder { date, result, name }

List<SaleLine> sortSales(List<SaleLine> lines, SaleOrder order) {
  int newest(SaleLine a, SaleLine b) {
    final byTs = b.sale.ts.compareTo(a.sale.ts);
    return byTs != 0 ? byTs : compareCodeUnits(a.sale.eventId, b.sale.eventId);
  }

  final primary = switch (order) {
    SaleOrder.date => (SaleLine a, SaleLine b) => 0,
    SaleOrder.result => (
      SaleLine a,
      SaleLine b,
    ) => b.sale.realizedPnL.compareTo(a.sale.realizedPnL),
    SaleOrder.name => (SaleLine a, SaleLine b) => compareNamesEs(
      a.name,
      b.name,
    ),
  };
  return [...lines]..sort((a, b) {
    final first = primary(a, b);
    return first != 0 ? first : newest(a, b);
  });
}

class SalesTotals {
  SalesTotals(List<SaleLine> lines)
    : count = lines.length,
      cost = lines.fold(Money.zero, (s, l) => s.add(l.sale.costBasis)),
      realized = lines.fold(Money.zero, (s, l) => s.add(l.sale.realizedPnL));

  final int count;
  final Money cost;
  final Money realized;

  Dec? get returnPct =>
      cost.isZero ? null : realized.amount.dividedBy(cost.amount).roundTo(6);
}

class RealizedReport {
  const RealizedReport({
    required this.hasLedger,
    required this.sales,
    required this.names,
    required this.events,
    required this.history,
    required this.taxYears,
    required this.defaultYear,
    required this.today,
    required this.noRate,
    required this.unclassified,
  });

  final bool hasLedger;
  final List<SaleLine> sales;
  final Map<String, String> names;
  final List<LedgerEvent> events;
  final TaxHistory history;
  final List<int> taxYears;
  final int? defaultYear;
  final String today;
  final List<String> noRate;
  final List<String> unclassified;

  String get zone => history.jurisdiction.zone;

  String nameOf(String instrumentId) => names[instrumentId] ?? instrumentId;

  TaxYearView taxYear(int year) => buildTaxYearView(events, history, year);
}
