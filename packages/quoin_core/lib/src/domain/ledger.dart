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
    this.linkId,
    this.linkKind,
    required this.account,
    required this.source,
    this.externalId,
  });

  final String id;
  final DateTime ts;
  final String currency;
  final FxSource fxSource;
  final String? fxDate;
  final Dec? fxRate;
  final FxDirection? fxDirection;
  final String? linkId;
  final String? linkKind;
  final String account;
  final String source;
  final String? externalId;

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
    super.linkId,
    super.linkKind,
    required super.account,
    required super.source,
    super.externalId,
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
    required super.account,
    required super.source,
    super.externalId,
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
    required super.account,
    required super.source,
    super.externalId,
  });

  final CashType type;
  final Money grossAmount;

  @override
  String? get instrumentId => null;
}

bool isSwapLeg(LedgerEvent event) => event.linkKind == 'swap';

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
