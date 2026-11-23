import '../calendar/day.dart';
import '../decimal/dec.dart';
import '../domain/instrument.dart';
import '../domain/ledger.dart';
import '../fx/to_base.dart';
import '../money/money.dart';
import 'config.dart';
import 'territory.dart';

/// Income from movable capital in the savings base: interest and dividends
/// paid in cash, gross, and Trade Republic's saveback, which it declares as
/// account income in money with its withholding, at its value on receipt. Any
/// other income received in kind (a Kraken reward) stays out: its
/// classification is pending.
bool isSavingsIncome(LedgerEvent event) => switch (event) {
      InterestEvent() => true,
      DividendEvent() => !isInKind(event) || _isSaveback(event),
      _ => false,
    };

/// Trade Republic's only income in kind is the saveback (`pairSavebacks`).
bool _isSaveback(DividendEvent event) =>
    isInKind(event) && event.source == tradeRepublicSource;

/// Income received in kind that no figure adds.
bool isInKindIncome(LedgerEvent event) =>
    event is DividendEvent && isInKind(event) && !isSavingsIncome(event);

/// The fiscal year an income counts in. Trade Republic pays on the 1st the
/// interest of the month before and declares it in that month, so its
/// interest counts on the day before the payment: 1 January goes to the year
/// before. The stored date is left as it is.
int incomeYearOf(LedgerEvent event, String zone) {
  if (event is InterestEvent && event.source == tradeRepublicSource) {
    final day = dayOf(event.ts, zone);
    final year = int.parse(day.substring(0, 4));
    return day.endsWith('-01-01') ? year - 1 : year;
  }
  return fiscalYearOf(event.ts, zone);
}

List<LedgerEvent> _inYear(List<LedgerEvent> events, int year, String zone) => [
      for (final e in bookable(events))
        if (isSavingsIncome(e) && incomeYearOf(e, zone) == year) e,
    ];

final class DividendExemption {
  const DividendExemption({required this.rule, required this.isCollective});

  final DividendExemptionRule rule;

  /// A fund or ETF: its dividends are never exempt when the rule excludes
  /// them.
  final bool Function(String instrumentId) isCollective;
}

/// Only an ETF is a fund here: Trade Republic stores funds as ETF. An
/// instrument not on file is never exempt.
bool Function(String instrumentId) isCollectiveInvestment(
  List<Instrument> instruments,
) {
  final types = {for (final i in instruments) i.id: i.type};
  return (id) {
    final type = types[id];
    return type == null || type == 'ETF';
  };
}

final class SavingsIncome {
  SavingsIncome._(this._gross, this._eligible, this._limit);

  final Map<int, Dec> _gross;
  final Map<int, Dec> _eligible;
  final Dec? _limit;

  /// The year's income, gross in euros.
  Dec grossOf(int year) => _gross[year] ?? Dec.zero;

  /// The part of it exempt as dividends, up to the year's limit.
  Dec exemptOf(int year) {
    final limit = _limit;
    return limit == null
        ? Dec.zero
        : minDec(_eligible[year] ?? Dec.zero, limit);
  }

  /// What enters the income pool: gross less exempt.
  Dec netOf(int year) => grossOf(year) - exemptOf(year);
}

SavingsIncome savingsIncomeOf(
  List<LedgerEvent> events,
  String zone,
  DividendExemption? exemption,
) {
  final gross = <int, Dec>{};
  final eligible = <int, Dec>{};
  void add(Map<int, Dec> map, int year, Dec amount) =>
      map[year] = (map[year] ?? Dec.zero) + amount;

  for (final e in bookable(events)) {
    if (!isSavingsIncome(e)) continue;
    final year = incomeYearOf(e, zone);
    final amount = switch (e) {
      InterestEvent(:final grossAmount) ||
      DividendEvent(:final grossAmount) =>
        baseOf(e, grossAmount).amount,
      _ => throw StateError('Not savings income: ${e.id}'),
    };
    add(gross, year, amount);
    if (exemption != null &&
        e is DividendEvent &&
        !isInKind(e) &&
        !(exemption.rule.excludesCollectiveInvestment &&
            exemption.isCollective(e.instrumentId))) {
      add(eligible, year, amount);
    }
  }
  return SavingsIncome._(
    gross,
    eligible,
    exemption == null ? null : Dec.parse(exemption.rule.limit),
  );
}

typedef Withholdings = ({
  /// The withholdings recorded on the year's savings income, in euros:
  /// payments on account of the whole IRPF, never subtracted from the
  /// savings quota. In-kind income shows its own.
  Money total,

  /// Some Trade Republic interest of the year records no withholding: its
  /// rows imported before interest carried it say 0. Interest from another
  /// source at 0 is taken as it is. Only for a notice.
  bool interestWithoutWithholding,
});

Withholdings withholdingsOf(List<LedgerEvent> events, int year, String zone) {
  final income = _inYear(events, year, zone);
  var total = Money.zero;
  var missing = false;
  for (final e in income) {
    switch (e) {
      case InterestEvent(:final taxWithheld):
        total = total.add(baseOf(e, taxWithheld));
        missing =
            missing || (e.source == tradeRepublicSource && taxWithheld.isZero);
      case DividendEvent(:final taxWithheld):
        total = total.add(baseOf(e, taxWithheld));
      default:
    }
  }
  return (total: total, interestWithoutWithholding: missing);
}

int savingsIncomeCountOf(List<LedgerEvent> events, int year, String zone) =>
    _inYear(events, year, zone).length;
