import '../calendar/day.dart';
import '../decimal/dec.dart';
import '../domain/instrument.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../fx/to_base.dart';
import '../money/money.dart';
import 'config.dart';
import 'tax_lots.dart';
import 'wash_sale.dart';

RepurchaseScope taxScopeFor(
  List<Instrument> instruments,
  Jurisdiction jurisdiction,
) =>
    RepurchaseScope(
      jurisdiction: jurisdiction,
      assetClasses: {
        for (final i in instruments) i.id: repurchaseAssetClassOf(i.type),
      },
    );

typedef InKindIncome = ({int count, Money gross, Money withheld});

InKindIncome inKindIncomeOf(List<LedgerEvent> events, int year, String zone) {
  final received = [
    for (final e in bookable(events))
      if (e is DividendEvent && isInKind(e) && fiscalYearOf(e.ts, zone) == year)
        e,
  ];
  return (
    count: received.length,
    gross: received.fold(Money.zero, (s, e) => s.add(baseOf(e, e.grossAmount))),
    withheld:
        received.fold(Money.zero, (s, e) => s.add(baseOf(e, e.taxWithheld))),
  );
}

/// Quoin's `buildTaxYearView` (lib/tax.ts) without the rows' names and the
/// pending deferrals grouped by sale: the figures of one fiscal year.
final class TaxYearView {
  const TaxYearView({
    required this.result,
    required this.carryforward,
    required this.scale,
    required this.quota,
    required this.inKindIncome,
  });

  final TaxYearResult result;
  final CarryforwardResult carryforward;
  final SavingsBaseTaxScale? scale;
  final Money? quota;
  final InKindIncome inKindIncome;

  int get year => result.year;

  List<RealizedGainDetail> get sales => result.gains;

  int get affectedCount => sales.where((s) => s.washSale != null).length;

  Dec get ownNet => sumDec(sales.map((g) => g.realizedPnL.amount));

  Dec get nonComputableSum => sumDec(sales.map((g) => g.nonComputable.amount));

  Dec get integratedSum =>
      sumDec(result.integrations.map((i) => i.amount.amount));

  Dec get computableNet => result.computableNet;

  Dec get pendingSum => sumDec(result.pending.map((p) => p.amount.amount));

  Dec get netSavingsBase => carryforward.netSavingsBase;
}

TaxYearView buildTaxYearView(
  List<LedgerEvent> events,
  TaxHistory history,
  int year,
) {
  final carry = carryforwardFrom(history, year);
  final scale = getTaxScale(history.jurisdiction.territory, year);
  return TaxYearView(
    result: taxYearOf(history, year),
    carryforward: carry,
    scale: scale,
    quota: scale == null
        ? null
        : carry.netSavingsBase.isPositive
            ? computeSavingsQuota(Money.of(carry.netSavingsBase), scale)
            : Money.zero,
    inKindIncome: inKindIncomeOf(events, year, history.jurisdiction.zone),
  );
}

List<int> listTaxYears(List<LedgerEvent> events, String zone) => {
      for (final e in events)
        if ((e is TradeEvent && e.type == TradeType.sell) ||
            (e is DividendEvent && isInKind(e)))
          fiscalYearOf(e.ts, zone),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

int? defaultTaxYear(List<int> years, String zone, DateTime now) {
  final current = fiscalYearOf(now, zone);
  return years.contains(current) ? current : years.firstOrNull;
}

String? windowOpenUntil(RealizedGainDetail gain, String today) {
  final window = gain.repurchaseWindow?.window;
  if (window == null || !gain.realizedPnL.isNegative) return null;
  final end = window.end.toString();
  return today.compareTo(end) <= 0 ? end : null;
}

final _halfCent = Dec.parse('0.005');

bool _roundsToNothing(Money value) => value.amount.abs() < _halfCent;

bool isBelowCent(Money value) => !value.isZero && _roundsToNothing(value);

bool isDeferralMinor(RealizedGainDetail gain) =>
    gain.washSale != null &&
    _roundsToNothing(gain.nonComputable) &&
    _roundsToNothing(gain.carriedOver);

List<String> unclassifiedSoldIds(
  List<LedgerEvent> events,
  List<Instrument> instruments,
) {
  final unclassified = {
    for (final i in instruments)
      if (repurchaseAssetClassOf(i.type) == RepurchaseAssetClass.unclassified)
        i.id,
  };
  return {
    for (final e in events)
      if (e is TradeEvent &&
          e.type == TradeType.sell &&
          unclassified.contains(e.instrumentId))
        e.instrumentId,
  }.toList()
    ..sort(compareCodeUnits);
}
