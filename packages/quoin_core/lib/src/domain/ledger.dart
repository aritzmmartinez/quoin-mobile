import '../calendar/calendar_date.dart';
import '../decimal/dec.dart';
import '../money/money.dart';
import 'coded.dart';

enum FxSource with Coded {
  identity('IDENTITY'),
  broker('BROKER'),
  ecb('ECB'),
  market('MARKET'),
  manual('MANUAL');

  const FxSource(this.code);

  @override
  final String code;

  static FxSource of(String code) => byCode(values, code);
}

enum FxDirection with Coded {
  /// Currency per euro, the ECB's way.
  quotePerBase('QUOTE_PER_BASE'),
  basePerQuote('BASE_PER_QUOTE');

  const FxDirection(this.code);

  @override
  final String code;

  static FxDirection of(String code) => byCode(values, code);
}

enum Funding with Coded {
  cash('CASH'),

  /// Units that arrived without money leaving the bank (a reward, a saveback).
  inKind('IN_KIND');

  const Funding(this.code);

  @override
  final String code;

  static Funding of(String code) => byCode(values, code);
}

enum TradeType with Coded {
  buy('BUY'),
  sell('SELL');

  const TradeType(this.code);

  @override
  final String code;

  static TradeType of(String code) => byCode(values, code);
}

enum CashType with Coded {
  deposit('DEPOSIT'),
  withdrawal('WITHDRAWAL'),
  interest('INTEREST');

  const CashType(this.code);

  @override
  final String code;

  static CashType of(String code) => byCode(values, code);
}

/// One row of the immutable ledger. Amounts are in [currency]; the fx fields
/// say how they become euros, frozen when the row was booked.
sealed class LedgerEvent {
  const LedgerEvent({
    required this.id,
    required this.ts,
    required this.currency,
    this.fxSource = FxSource.identity,
    this.fxDate,
    this.fxRate,
    this.fxDirection,
    this.originalAmount,
    this.originalCurrency,
    this.valuationSource,
    this.linkId,
    this.linkKind,
    required this.account,
    required this.source,
    this.externalId,
    this.note,
  });

  final String id;
  final DateTime ts;
  final String currency;
  final FxSource fxSource;
  final String? fxDate;
  final Dec? fxRate;
  final FxDirection? fxDirection;

  /// The amount and currency the source gave, before any conversion; stored
  /// as the gross amount and currency when null.
  final Money? originalAmount;
  final String? originalCurrency;

  /// Where a price came from when the source gave none (`kraken-amountusd`).
  final String? valuationSource;
  final String? linkId;
  final String? linkKind;
  final String account;
  final String source;
  final String? externalId;
  final String? note;

  /// The instrument the row is about; a cash movement has none.
  String? get instrumentId;
}

final class TradeEvent extends LedgerEvent {
  const TradeEvent({
    required super.id,
    required super.ts,
    required this.type,
    required this.instrumentId,
    required this.quantity,
    required this.price,
    required this.grossAmount,
    required this.fees,
    required super.currency,
    this.funding = Funding.cash,
    super.fxSource,
    super.fxDate,
    super.fxRate,
    super.fxDirection,
    super.originalAmount,
    super.originalCurrency,
    super.valuationSource,
    super.linkId,
    super.linkKind,
    required super.account,
    required super.source,
    super.externalId,
    super.note,
  });

  final TradeType type;
  @override
  final String instrumentId;
  final Dec quantity;
  final Money price;
  final Money grossAmount;
  final Money fees;
  final Funding funding;
}

final class DividendEvent extends LedgerEvent {
  const DividendEvent({
    required super.id,
    required super.ts,
    required this.instrumentId,
    required this.grossAmount,
    required this.taxWithheld,
    required super.currency,
    this.funding = Funding.cash,
    super.fxSource,
    super.fxDate,
    super.fxRate,
    super.fxDirection,
    super.originalAmount,
    super.originalCurrency,
    super.valuationSource,
    super.linkId,
    super.linkKind,
    required super.account,
    required super.source,
    super.externalId,
    super.note,
  });

  @override
  final String instrumentId;
  final Money grossAmount;
  final Money taxWithheld;
  final Funding funding;
}

final class CashEvent extends LedgerEvent {
  const CashEvent({
    required super.id,
    required super.ts,
    required this.type,
    required this.grossAmount,
    required super.currency,
    super.fxSource,
    super.fxDate,
    super.fxRate,
    super.fxDirection,
    super.originalAmount,
    super.originalCurrency,
    super.valuationSource,
    super.linkId,
    super.linkKind,
    required super.account,
    required super.source,
    super.externalId,
    super.note,
  });

  final CashType type;
  final Money grossAmount;

  @override
  String? get instrumentId => null;
}

bool isSwapLeg(LedgerEvent event) => event.linkKind == 'swap';

/// Units that arrived without cash leaving the bank.
bool isInKind(LedgerEvent event) => switch (event) {
      TradeEvent(:final funding) ||
      DividendEvent(:final funding) =>
        funding == Funding.inKind,
      CashEvent() => false,
    };

const valuationSources = {'kraken-amountusd', 'yahoo'};
const linkKinds = {'swap'};

/// Why [event] may not be written to the ledger, as Quoin's
/// `ledgerEventWriteSchema` says; empty when it may.
List<String> ledgerWriteIssues(LedgerEvent event) {
  final issues = <String>[];
  if ((event.externalId ?? '').isEmpty) {
    issues.add('An entry needs the id its source gave it');
  }
  final valuation = event.valuationSource;
  if (valuation != null && !valuationSources.contains(valuation)) {
    issues.add('Unknown valuation source "$valuation"');
  }
  final link = event.linkKind;
  if (link != null && !linkKinds.contains(link)) {
    issues.add('Unknown link kind "$link"');
  }
  if ((event.linkId == null) != (link == null)) {
    issues.add('A link needs both its id and its kind, or neither');
  }
  if (link == 'swap' && event is! TradeEvent) {
    issues.add('A swap leg is a purchase or a sale');
  }

  final conversion = [event.fxRate, event.fxDirection, event.fxDate];
  if (event.fxSource == FxSource.identity) {
    if (event.currency != baseCurrency) {
      issues.add(
        'An amount in ${event.currency} needs a conversion to $baseCurrency',
      );
    }
    if (conversion.any((value) => value != null)) {
      issues.add(
        'An amount booked as it stands carries no rate, direction or day',
      );
    }
    return issues;
  }
  final source = event.fxSource.code;
  if (event.currency == baseCurrency) {
    issues.add('An amount in $baseCurrency is not converted ($source)');
  }
  if (conversion.any((value) => value == null)) {
    issues.add('A $source conversion needs its rate, direction and day');
  }
  final rate = event.fxRate;
  if (rate != null && !rate.isPositive) {
    issues.add('A rate must be positive, got $rate');
  }
  final day = event.fxDate;
  if (day != null && !_isDay(day)) {
    issues.add("A rate's day must be a YYYY-MM-DD date, got $day");
  }
  return issues;
}

/// Orders ids, never names: by code unit, the same on every runtime.
int compareCodeUnits(String a, String b) => a.compareTo(b).sign;

/// The one order of trades: by instant, then BUY before SELL, then the
/// source's id, then the row's. The store sorts by `ts` alone and SQLite
/// breaks ties however it likes, so every fold over trades sorts with this.
int compareTrades(TradeEvent a, TradeEvent b) {
  final byTs = a.ts.compareTo(b.ts);
  if (byTs != 0) return byTs;
  if (a.type != b.type) return a.type == TradeType.buy ? -1 : 1;
  final byExternal = compareCodeUnits(a.externalId ?? '', b.externalId ?? '');
  return byExternal != 0 ? byExternal : compareCodeUnits(a.id, b.id);
}

bool _isDay(String day) {
  try {
    CalendarDate.parse(day);
    return true;
  } on RangeError {
    return false;
  }
}

String ledgerTypeOf(LedgerEvent event) => switch (event) {
      TradeEvent(:final type) => type.code,
      DividendEvent() => 'DIVIDEND',
      CashEvent(:final type) => type.code,
    };

bool isUnconvertedForeign(LedgerEvent event) =>
    event.fxSource == FxSource.identity &&
    event.currency != baseCurrency &&
    event.fxRate == null &&
    event.fxDirection == null &&
    event.fxDate == null;

LedgerEvent convertedAt(
  LedgerEvent event, {
  required FxSource source,
  required Dec rate,
  required String day,
}) =>
    _rebuilt(
      event,
      fxSource: source,
      fxRate: rate,
      fxDirection: FxDirection.quotePerBase,
      fxDate: day,
    );

LedgerEvent fundedInKind(LedgerEvent event) =>
    _rebuilt(event, funding: Funding.inKind);

LedgerEvent _rebuilt(
  LedgerEvent e, {
  FxSource? fxSource,
  Dec? fxRate,
  FxDirection? fxDirection,
  String? fxDate,
  Funding? funding,
}) =>
    switch (e) {
      TradeEvent() => TradeEvent(
          id: e.id,
          ts: e.ts,
          type: e.type,
          instrumentId: e.instrumentId,
          quantity: e.quantity,
          price: e.price,
          grossAmount: e.grossAmount,
          fees: e.fees,
          currency: e.currency,
          funding: funding ?? e.funding,
          fxSource: fxSource ?? e.fxSource,
          fxDate: fxDate ?? e.fxDate,
          fxRate: fxRate ?? e.fxRate,
          fxDirection: fxDirection ?? e.fxDirection,
          originalAmount: e.originalAmount,
          originalCurrency: e.originalCurrency,
          valuationSource: e.valuationSource,
          linkId: e.linkId,
          linkKind: e.linkKind,
          account: e.account,
          source: e.source,
          externalId: e.externalId,
          note: e.note,
        ),
      DividendEvent() => DividendEvent(
          id: e.id,
          ts: e.ts,
          instrumentId: e.instrumentId,
          grossAmount: e.grossAmount,
          taxWithheld: e.taxWithheld,
          currency: e.currency,
          funding: funding ?? e.funding,
          fxSource: fxSource ?? e.fxSource,
          fxDate: fxDate ?? e.fxDate,
          fxRate: fxRate ?? e.fxRate,
          fxDirection: fxDirection ?? e.fxDirection,
          originalAmount: e.originalAmount,
          originalCurrency: e.originalCurrency,
          valuationSource: e.valuationSource,
          linkId: e.linkId,
          linkKind: e.linkKind,
          account: e.account,
          source: e.source,
          externalId: e.externalId,
          note: e.note,
        ),
      CashEvent() => CashEvent(
          id: e.id,
          ts: e.ts,
          type: e.type,
          grossAmount: e.grossAmount,
          currency: e.currency,
          fxSource: fxSource ?? e.fxSource,
          fxDate: fxDate ?? e.fxDate,
          fxRate: fxRate ?? e.fxRate,
          fxDirection: fxDirection ?? e.fxDirection,
          originalAmount: e.originalAmount,
          originalCurrency: e.originalCurrency,
          valuationSource: e.valuationSource,
          linkId: e.linkId,
          linkKind: e.linkKind,
          account: e.account,
          source: e.source,
          externalId: e.externalId,
          note: e.note,
        ),
    };
