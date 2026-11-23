import '../calendar/day.dart';
import '../decimal/dec.dart';
import '../domain/instrument.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../fx/to_base.dart';
import '../money/money.dart';
import 'carryforward.dart';
import 'config.dart';
import 'savings_income.dart';
import 'tax_lots.dart';
import 'territory.dart';
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
      if (e is DividendEvent &&
          isInKindIncome(e) &&
          fiscalYearOf(e.ts, zone) == year)
        e,
  ];
  return (
    count: received.length,
    gross: received.fold(Money.zero, (s, e) => s.add(baseOf(e, e.grossAmount))),
    withheld:
        received.fold(Money.zero, (s, e) => s.add(baseOf(e, e.taxWithheld))),
  );
}

/// The income pool of one year: its own count, gross and exempt part, and
/// the pool after its carryforward. [exemptSource] is null where the
/// territory exempts no dividend.
typedef SavingsIncomeView = ({
  int count,
  Dec gross,
  Dec exempt,
  String? exemptSource,
  PoolResult pool,
});

/// Quoin's `buildTaxYearView` (lib/tax.ts) without the rows' names and the
/// pending deferrals grouped by sale: the figures of one fiscal year.
final class TaxYearView {
  const TaxYearView({
    required this.result,
    required this.carryforward,
    required this.savingsIncome,
    required this.savingsBase,
    required this.scale,
    required this.quota,
    required this.withholdings,
    required this.inKindIncome,
  });

  final TaxYearResult result;

  /// The capital-gains pool.
  final CarryforwardResult carryforward;
  final SavingsIncomeView savingsIncome;

  /// Both pools' positive final balances: what the quota applies to.
  final Dec savingsBase;

  /// The scale in force: an earlier year's when no newer one is on file.
  final SavingsBaseTaxScale? scale;
  final Money? quota;
  final Withholdings withholdings;
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

  bool get scaleInherited => scale != null && scale!.year < year;
}

TaxYearView buildTaxYearView(
  List<LedgerEvent> events,
  List<Instrument> instruments,
  TaxHistory history,
  int year,
) {
  final territory = history.jurisdiction.territory;
  final zone = history.jurisdiction.zone;
  final rules = territoryRules(territory);
  final exemptionRule = rules.dividendExemption;
  final income = savingsIncomeOf(
    events,
    zone,
    exemptionRule == null
        ? null
        : DividendExemption(
            rule: exemptionRule,
            isCollective: isCollectiveInvestment(instruments),
          ),
  );
  final (:pools, :savingsBase, targetYear: _) = carryforwardPools(
    (gainsNetOf(history), income.netOf),
    year,
    rules.lossCarryforwardYears,
    rules.crossOffsetLimit,
  );
  final scale = getTaxScale(territory, year);
  return TaxYearView(
    result: taxYearOf(history, year),
    carryforward: carryforwardFrom(history, year),
    savingsIncome: (
      count: savingsIncomeCountOf(events, year, zone),
      gross: income.grossOf(year),
      exempt: income.exemptOf(year),
      exemptSource: exemptionRule?.source,
      pool: pools.$2,
    ),
    savingsBase: savingsBase,
    scale: scale,
    quota: scale == null
        ? null
        : savingsBase.isPositive
            ? computeSavingsQuota(Money.of(savingsBase), scale)
            : Money.zero,
    withholdings: withholdingsOf(events, year, zone),
    inKindIncome: inKindIncomeOf(events, year, zone),
  );
}

List<int> listTaxYears(List<LedgerEvent> events, String zone) => {
      for (final e in events)
        if (isSavingsIncome(e))
          incomeYearOf(e, zone)
        else if ((e is TradeEvent && e.type == TradeType.sell) ||
            isInKindIncome(e))
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
