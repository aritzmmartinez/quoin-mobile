import '../decimal/dec.dart';
import '../domain/instrument.dart';
import '../domain/ledger.dart';
import '../id.dart';
import '../money/money.dart';
import 'batch.dart';
import 'crypto_id.dart';
import 'csv.dart';
import 'reasons.dart';

final class TradeRepublicRow {
  const TradeRepublicRow({
    required this.datetime,
    required this.category,
    required this.type,
    required this.assetClass,
    required this.name,
    required this.symbol,
    required this.shares,
    required this.price,
    required this.amount,
    required this.fee,
    required this.tax,
    required this.currency,
    required this.transactionId,
    this.originalAmount,
    this.originalCurrency,
    required this.position,
  });

  final String datetime;
  final String category;
  final String type;
  final String assetClass;
  final String name;
  final String symbol;
  final String shares;
  final String price;
  final String amount;
  final String fee;
  final String tax;
  final String currency;
  final String transactionId;
  final String? originalAmount;
  final String? originalCurrency;
  final int position;

  DateTime get ts => _instant(datetime);
}

const _columns = [
  'datetime',
  'category',
  'type',
  'asset_class',
  'name',
  'symbol',
  'shares',
  'price',
  'amount',
  'fee',
  'tax',
  'currency',
  'transaction_id',
];

const _date = r'(?:(?:\d\d[2468][048]|\d\d[13579][26]|\d\d0[48]|[02468][048]00'
    r'|[13579][26]00)-02-29|\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\d|3[01])'
    r'|(?:0[469]|11)-(?:0[1-9]|[12]\d|30)|(?:02)-(?:0[1-9]|1\d|2[0-8])))';
final _datetime = RegExp(
  '^${_date}T(?:[01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d(?:\\.\\d+)?'
  r'(?:Z|([+-](?:[01]\d|2[0-3]):[0-5]\d))$',
);

DateTime _instant(String datetime) {
  final parsed = DateTime.parse(datetime).toUtc();
  return DateTime.fromMillisecondsSinceEpoch(
    parsed.millisecondsSinceEpoch,
    isUtc: true,
  );
}

({List<TradeRepublicRow> rows, List<RowError> errors}) parseTradeRepublicCsv(
  String csv,
) {
  final read = readCsv(csv, _columns);
  requireColumns(read);
  final rows = <TradeRepublicRow>[];
  final errors = <RowError>[];
  for (final CsvRecord(:raw, :position, :malformed) in read.records) {
    final ref = RowRef.of(
      raw['transaction_id'],
      position,
      raw['datetime'],
      raw['type'],
    );
    if (malformed) {
      errors.add(RowError(ref, RowErrorReason.wrongFieldCount));
      continue;
    }
    final datetime = raw['datetime']!;
    if (!_datetime.hasMatch(datetime)) {
      errors.add(RowError(ref, RowErrorReason.invalidDate));
      continue;
    }
    rows.add(
      TradeRepublicRow(
        datetime: datetime,
        category: raw['category']!,
        type: raw['type']!,
        assetClass: raw['asset_class']!,
        name: raw['name']!,
        symbol: raw['symbol']!,
        shares: raw['shares']!,
        price: raw['price']!,
        amount: raw['amount']!,
        fee: raw['fee']!,
        tax: raw['tax']!,
        currency: raw['currency']!,
        transactionId: raw['transaction_id']!,
        originalAmount: raw['original_amount'],
        originalCurrency: raw['original_currency'],
        position: position,
      ),
    );
  }
  return (rows: rows, errors: errors);
}

const _savebackWindow = Duration(days: 7);

Dec _magnitude(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? Dec.zero : Dec.parse(trimmed).abs();
}

bool _isSaveback(TradeRepublicRow row) =>
    row.category == 'CASH' && row.type == 'BENEFITS_SAVEBACK';

bool _isBuy(TradeRepublicRow row) =>
    row.category == 'TRADING' && row.type == 'BUY';

bool _isCandidate(TradeRepublicRow saveback, TradeRepublicRow buy) {
  final from = saveback.ts;
  final at = buy.ts;
  if (at.isBefore(from) || at.difference(from) > _savebackWindow) return false;
  if (saveback.symbol.isNotEmpty && buy.symbol != saveback.symbol) {
    return false;
  }
  final invested = _magnitude(saveback.amount) - _magnitude(saveback.tax);
  return _magnitude(buy.amount).compareTo(invested) == 0;
}

Map<String, String> pairSavebacks(List<TradeRepublicRow> rows) {
  final unique = <String, TradeRepublicRow>{};
  for (final row in rows) {
    unique.putIfAbsent(row.transactionId, () => row);
  }
  final buys = unique.values.where(_isBuy).toList();
  final candidates = <String, List<String>>{};
  final claims = <String, int>{};
  for (final saveback in unique.values.where(_isSaveback)) {
    final found = [
      for (final buy in buys)
        if (_isCandidate(saveback, buy)) buy.transactionId,
    ];
    candidates[saveback.transactionId] = found;
    for (final id in found) {
      claims[id] = (claims[id] ?? 0) + 1;
    }
  }
  return {
    for (final MapEntry(key: saveback, value: found) in candidates.entries)
      if (found.length == 1 && claims[found.single] == 1)
        saveback: found.single,
  };
}

String _abs(String value) => Dec.parse(value).abs().text;

String _absOrZero(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '0' : _abs(trimmed);
}

const _typeOfAssetClass = {
  'FUND': 'ETF',
  'STOCK': 'STOCK',
  'CRYPTO': 'CRYPTO',
  'SYNTHETIC': 'ETF',
};

String? _instrumentIdOf(TradeRepublicRow row) =>
    row.assetClass == 'CRYPTO' ? cryptoInstrumentId(row.symbol) : row.symbol;

Instrument _instrument(TradeRepublicRow row, String id, String type) {
  if (id.isEmpty) throw const MissingInstrument();
  return Instrument(
    id: id,
    name: row.name,
    type: type,
    assetClass: row.assetClass.isEmpty ? null : row.assetClass,
  );
}

final class _Base {
  _Base(TradeRepublicRow row)
      : ts = row.ts,
        currency = row.currency,
        externalId = row.transactionId {
    final amount = row.originalAmount?.trim() ?? '';
    final currency = row.originalCurrency?.trim() ?? '';
    if (amount.isNotEmpty && currency.isNotEmpty) {
      originalAmount = Money.parse(_abs(amount));
      originalCurrency = currency;
    }
  }

  final id = uuidV4();
  final DateTime ts;
  final String currency;
  final String externalId;
  Money? originalAmount;
  String? originalCurrency;
}

const _account = 'trade-republic';
const _source = 'TR_CSV';

DiscardItem _invalidCryptoCode(TradeRepublicRow row) => DiscardItem(
      DiscardReason.invalidCryptoCode,
      detail: DiscardDetail(
        date: row.datetime,
        type: row.type,
        instrument: _firstOf(row.symbol, row.name),
      ),
    );

DiscardItem _unsupportedAssetClass(TradeRepublicRow row) => DiscardItem(
      DiscardReason.unsupportedAssetClass,
      detail: DiscardDetail(
        date: row.datetime,
        type: row.type,
        subtype: row.assetClass.isEmpty ? null : row.assetClass,
        instrument: _firstOf(row.name, row.symbol),
        affectsPosition: row.category == 'TRADING',
      ),
    );

DiscardItem _savebackUnpaired(TradeRepublicRow row) => DiscardItem(
      DiscardReason.savebackUnpaired,
      detail: DiscardDetail(
        date: row.datetime,
        type: row.type,
        instrument: row.name.isEmpty ? null : row.name,
      ),
    );

String? _firstOf(String a, String b) =>
    a.isNotEmpty ? a : (b.isNotEmpty ? b : null);

MappedItem mapTradeRepublicRow(TradeRepublicRow row) {
  switch ('${row.category}|${row.type}') {
    case 'TRADING|BUY' || 'TRADING|SELL':
      final type = _typeOfAssetClass[row.assetClass];
      if (type == null) return _unsupportedAssetClass(row);
      final id = _instrumentIdOf(row);
      if (id == null) return _invalidCryptoCode(row);
      final instrument = _instrument(row, id, type);
      final base = _Base(row);
      return DomainItem(
        instrument,
        TradeEvent(
          id: base.id,
          ts: base.ts,
          type: TradeType.of(row.type),
          instrumentId: id,
          quantity: Dec.parse(_abs(row.shares)),
          price: Money.parse(row.price),
          grossAmount: Money.parse(_abs(row.amount)),
          fees: Money.parse(_absOrZero(row.fee)),
          currency: base.currency,
          originalAmount: base.originalAmount,
          originalCurrency: base.originalCurrency,
          account: _account,
          source: _source,
          externalId: base.externalId,
        ),
      );

    case 'CASH|DIVIDEND':
      final type = _typeOfAssetClass[row.assetClass];
      if (type == null) return _unsupportedAssetClass(row);
      final id = _instrumentIdOf(row);
      if (id == null) return _invalidCryptoCode(row);
      final instrument = _instrument(row, id, type);
      final base = _Base(row);
      return DomainItem(
        instrument,
        DividendEvent(
          id: base.id,
          ts: base.ts,
          instrumentId: id,
          grossAmount: Money.parse(_abs(row.amount)),
          taxWithheld: Money.parse(_absOrZero(row.tax)),
          currency: base.currency,
          originalAmount: base.originalAmount,
          originalCurrency: base.originalCurrency,
          account: _account,
          source: _source,
          externalId: base.externalId,
        ),
      );

    case 'CASH|INTEREST_PAYMENT':
      return DomainItem(null, _cash(row, CashType.interest));

    case 'CASH|CUSTOMER_INPAYMENT' ||
          'CASH|TRANSFER_INSTANT_INBOUND' ||
          'CASH|TRANSFER_DIRECT_DEBIT_INBOUND' ||
          'CASH|TRANSFER_INBOUND':
      return DomainItem(null, _cash(row, CashType.deposit));

    case 'CASH|TRANSFER_INSTANT_OUTBOUND':
      return DomainItem(null, _cash(row, CashType.withdrawal));

    case 'CASH|BENEFITS_SAVEBACK':
      return _savebackUnpaired(row);

    case 'CASH|CARD_TRANSACTION' || 'CASH|CARD_TRANSACTION_INTERNATIONAL':
      return const DiscardItem(DiscardReason.cardSpending);

    default:
      return DiscardItem(
        DiscardReason.unsupported,
        detail: DiscardDetail(
          date: row.datetime,
          type: row.type,
          instrument: row.name.isEmpty ? null : row.name,
        ),
      );
  }
}

List<MappedItem> mapSavebackPurchase(
  TradeRepublicRow buy,
  TradeRepublicRow saveback,
) {
  final purchase = mapTradeRepublicRow(buy);
  if (purchase is DiscardItem) return [purchase, _savebackUnpaired(saveback)];
  if (purchase is! DomainItem ||
      purchase.event is! TradeEvent ||
      (purchase.event as TradeEvent).type != TradeType.buy) {
    throw StateError(
      'Saveback ${saveback.transactionId} paired with a non-buy',
    );
  }
  final bought = purchase.event as TradeEvent;
  final base = _Base(saveback);
  return [
    DomainItem(purchase.instrument, fundedInKind(bought)),
    DomainItem(
      null,
      DividendEvent(
        id: base.id,
        ts: base.ts,
        instrumentId: bought.instrumentId,
        grossAmount: Money.parse(_abs(saveback.amount)),
        taxWithheld: Money.of(
          Dec.parse(_absOrZero(saveback.tax)) + Dec.parse(_absOrZero(buy.tax)),
        ),
        currency: base.currency,
        funding: Funding.inKind,
        originalAmount: base.originalAmount,
        originalCurrency: base.originalCurrency,
        account: _account,
        source: _source,
        externalId: base.externalId,
      ),
    ),
  ];
}

CashEvent _cash(TradeRepublicRow row, CashType type) {
  final base = _Base(row);
  return CashEvent(
    id: base.id,
    ts: base.ts,
    type: type,
    grossAmount: Money.parse(_abs(row.amount)),
    currency: base.currency,
    originalAmount: base.originalAmount,
    originalCurrency: base.originalCurrency,
    account: _account,
    source: _source,
    externalId: base.externalId,
  );
}

MappedBatch planTradeRepublic(String csv, BatchBuilder builder) {
  final (:rows, :errors) = parseTradeRepublicCsv(csv);
  final pairs = pairSavebacks(rows);
  final savebackOf = <String, TradeRepublicRow>{};
  for (final row in rows) {
    final buy = pairs[row.transactionId];
    if (buy != null) savebackOf.putIfAbsent(buy, () => row);
  }

  errors.forEach(builder.addError);
  for (final row in rows) {
    if (pairs.containsKey(row.transactionId)) continue;
    final saveback = savebackOf[row.transactionId];
    try {
      if (saveback != null) {
        builder.addOperation(mapSavebackPurchase(row, saveback));
      } else {
        builder.add(mapTradeRepublicRow(row));
      }
    } on Object catch (error) {
      final reason = rowErrorReason(error);
      for (final failed in [if (saveback != null) saveback, row]) {
        builder.addError(
          RowError(
            RowRef.of(
              failed.transactionId,
              failed.position,
              failed.datetime,
              failed.type,
            ),
            reason,
          ),
        );
      }
    }
  }
  return builder.build(rows.length + errors.length);
}
