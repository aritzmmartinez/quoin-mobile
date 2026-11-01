import '../decimal/dec.dart';
import '../domain/instrument.dart';
import '../domain/ledger.dart';
import '../fx/value.dart';
import '../id.dart';
import '../money/money.dart';
import '../series/as_of.dart';
import 'batch.dart';
import 'crypto_id.dart';
import 'csv.dart';
import 'reasons.dart';

final class KrakenRow {
  const KrakenRow(this.raw, this.position);

  final Map<String, String> raw;
  final int position;

  String get txid => raw['txid']!;
  String get refid => raw['refid']!;
  String get time => raw['time']!;
  String get type => raw['type']!;
  String get subtype => raw['subtype'] ?? '';
  String get subclass => raw['subclass']!;
  String get asset => raw['asset']!;
  String get wallet => raw['wallet']!;
  String get amount => raw['amount']!;
  String get fee => raw['fee']!;
  String get balance => raw['balance']!;
  String get amountusd => raw['amountusd'] ?? '';
  String get feeusd => raw['feeusd'] ?? '';

  RowRef get ref => RowRef.of(refid, position, time, type);
}

const _columns = [
  'txid',
  'refid',
  'time',
  'type',
  'aclass',
  'subclass',
  'asset',
  'wallet',
  'amount',
  'fee',
  'balance',
];

final _isoUtc = RegExp(
  r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d)(?::(\d\d)(?:\.(\d+))?)?Z$',
);

DateTime? parseKrakenTime(String time) {
  final match = _isoUtc.firstMatch('${time.replaceFirst(' ', 'T')}Z');
  if (match == null) return null;
  int part(int i) => int.parse(match[i] ?? '0');
  final (month, day, hour, minute, second) =
      (part(2), part(3), part(4), part(5), part(6));
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;
  final fraction = (match[7] ?? '').padRight(3, '0').substring(0, 3);
  return DateTime.utc(
    part(1),
    month,
    day,
    hour,
    minute,
    second,
    int.parse(fraction),
  );
}

List<KrakenRow> parseKrakenCsv(String csv) {
  final read = readCsv(csv, _columns);
  if (read.missing.contains('wallet')) throw const KrakenLegacyExport();
  requireColumns(read);
  return [
    for (final CsvRecord(:raw, :position, :malformed) in read.records)
      if (malformed)
        throw CsvFileError(
          FileErrorReason.wrongFieldCount,
          row: RowRef.of(raw['refid'], position, raw['time'], raw['type']),
        )
      else
        KrakenRow(raw, position),
  ];
}

({String asset, String wallet, String date})? findBalanceMismatch(
  List<KrakenRow> rows,
) {
  final held = <(String, String), Dec>{};
  for (final row in rows) {
    final amount = Dec.tryParse(_orZero(row.amount));
    final fee = Dec.tryParse(_orZero(row.fee));
    final balance = Dec.tryParse(row.balance);
    if (amount == null || fee == null || balance == null) {
      throw CsvFileError(FileErrorReason.invalidNumber, row: row.ref);
    }
    final key = (row.asset, row.wallet);
    final before = held[key];
    if (before != null && (before + amount - fee).compareTo(balance) != 0) {
      return (asset: row.asset, wallet: row.wallet, date: '${row.time} UTC');
    }
    held[key] = balance;
  }
  return null;
}

String _orZero(String value) => value.isEmpty ? '0' : value;

const krakenRewardNote = 'kraken-reward';
const krakenAccountTransferNote = 'kraken-account-transfer';
const _rewardIncomeNote = 'kraken-reward-income';
const _account = 'kraken';
const _source = 'KRAKEN_CSV';

const _internalEarn = {
  'allocation',
  'deallocation',
  'migration',
  'autoallocation',
};

DiscardDetail _detailOf(KrakenRow row, String? instrument) => DiscardDetail(
      date: isoInstant(parseKrakenTime(row.time)!),
      type: row.type,
      subtype: row.subtype.isEmpty ? null : row.subtype,
      instrument: instrument,
    );

DiscardItem _discard(DiscardReason reason, KrakenRow row) => DiscardItem(
      reason,
      detail: _detailOf(row, row.asset.isEmpty ? null : row.asset),
    );

DiscardItem _unsupported(KrakenRow row) =>
    _discard(DiscardReason.unsupported, row);

typedef PriceAt = PriceSnapshot? Function(String instrumentId, DateTime ts);

const _maxPriceAge = Duration(days: 7);

PriceAt priceLookupFrom(List<PriceSnapshot> snapshots) {
  final byInstrument = <String, List<PriceSnapshot>>{};
  for (final snapshot in snapshots) {
    byInstrument.putIfAbsent(snapshot.instrumentId, () => []).add(snapshot);
  }
  for (final list in byInstrument.values) {
    _stableSort(list);
  }
  return (instrumentId, ts) {
    final history = byInstrument[instrumentId];
    if (history == null) return null;
    return lastOnOrBefore(
      history,
      snapshotKnownAt,
      ts,
      ts.subtract(_maxPriceAge),
    );
  };
}

void _stableSort(List<PriceSnapshot> list) {
  final indexed = [for (var i = 0; i < list.length; i += 1) (i, list[i])]
    ..sort((a, b) {
      final byTime = snapshotKnownAt(a.$2).compareTo(snapshotKnownAt(b.$2));
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  list
    ..clear()
    ..addAll(indexed.map((entry) => entry.$2));
}

const _names = {'BTC': 'Bitcoin'};

Instrument? _cryptoInstrument(String code) {
  final id = cryptoInstrumentId(code);
  if (id == null) return null;
  return Instrument(
    id: id,
    name: _names[id] ?? id,
    type: 'CRYPTO',
    assetClass: 'crypto',
  );
}

bool _isFiat(KrakenRow row) => row.subclass == 'fiat';

List<String> krakenCryptoIds(List<KrakenRow> rows) => {
      for (final row in rows)
        if (!_isFiat(row))
          if (cryptoInstrumentId(row.asset) case final id?) id,
    }.toList()
      ..sort();

Dec _absOf(String value) => Dec.parse(_orZero(value)).abs();

Dec _net(KrakenRow row) =>
    Dec.parse(_orZero(row.amount)) - Dec.parse(_orZero(row.fee));

Map<String, List<KrakenRow>> groupByRefid(List<KrakenRow> rows) {
  final groups = <String, List<KrakenRow>>{};
  for (final row in rows) {
    groups.putIfAbsent(row.refid, () => []).add(row);
  }
  return groups;
}

bool _isSpotWallet(KrakenRow row) => row.wallet.split(' / ').first == 'spot';

bool _isSpotToEarn(KrakenRow row) =>
    row.type == 'hybridearnwithdrawal' &&
    _isSpotWallet(row) &&
    Dec.parse(_orZero(row.amount)).isNegative;

bool isInternalMove(KrakenRow row) {
  if (row.type == 'transfer') return row.subtype != 'useraccounttransfer';
  if (_isSpotToEarn(row)) return true;
  return row.type == 'earn' && _internalEarn.contains(row.subtype);
}

List<MappedItem> mapKrakenGroup(List<KrakenRow> rows, PriceAt priceAt) {
  final first = rows.first;
  final refid = first.refid;

  if (rows.every(isInternalMove)) {
    return [_discard(DiscardReason.internalMove, first)];
  }

  final spend = rows.where((r) => r.type == 'spend').firstOrNull;
  final receive = rows.where((r) => r.type == 'receive').firstOrNull;
  if (spend != null && receive != null && rows.length == 2) {
    final pair = '${spend.asset} → ${receive.asset}';
    if (_isFiat(spend) && _isFiat(receive)) return [_unsupported(receive)];
    if (!_isFiat(spend) && !_isFiat(receive)) {
      return _swap(refid, spend, receive, pair, priceAt);
    }
    final crypto = _isFiat(spend) ? receive : spend;
    final instrument = _cryptoInstrument(crypto.asset);
    if (instrument == null) {
      return [_discard(DiscardReason.invalidCryptoCode, crypto)];
    }
    return _isFiat(spend)
        ? [_buy(refid, instrument, spend, receive)]
        : [_sell(refid, instrument, receive, spend)];
  }

  if (rows.length != 1) return [_unsupported(first)];

  switch (first.type) {
    case 'deposit' || 'withdrawal':
      if (_isFiat(first)) {
        return [
          _cash(
            refid,
            first,
            first.type == 'deposit' ? CashType.deposit : CashType.withdrawal,
          ),
        ];
      }
      return [_discard(DiscardReason.cryptoTransfer, first)];
    case 'transfer':
      if (!_isFiat(first)) {
        return [_discard(DiscardReason.cryptoTransfer, first)];
      }
      return [
        _cash(
          refid,
          first,
          Dec.parse(first.amount).isNegative
              ? CashType.withdrawal
              : CashType.deposit,
          krakenAccountTransferNote,
        ),
        NoticeItem(
          NoticeReason.accountTransfer,
          _detailOf(first, first.asset.isEmpty ? null : first.asset),
        ),
      ];
    case 'reward':
      return _reward(refid, first, priceAt);
    case 'earn':
      return first.subtype == 'reward'
          ? _reward(refid, first, priceAt)
          : [_unsupported(first)];
    case 'hybridearnwithdrawal':
      return [_discard(DiscardReason.earnReturnUnverified, first)];
    default:
      return [_unsupported(first)];
  }
}

TradeEvent _tradeEvent(
  String refid,
  Instrument instrument,
  TradeType type,
  KrakenRow fiat,
  Dec quantity,
  Dec fiatAmount,
) =>
    TradeEvent(
      id: uuidV4(),
      ts: parseKrakenTime(fiat.time)!,
      type: type,
      instrumentId: instrument.id,
      quantity: quantity,
      price: Money.of(fiatAmount.dividedBy(quantity)),
      grossAmount: Money.of(fiatAmount),
      fees: Money.of(_absOf(fiat.fee)),
      currency: fiat.asset,
      account: _account,
      source: _source,
      externalId: refid,
    );

MappedItem _buy(
  String refid,
  Instrument instrument,
  KrakenRow fiat,
  KrakenRow received,
) {
  final quantity = _net(received);
  final amount = _absOf(fiat.amount);
  if (!quantity.isPositive || amount.isZero) return _unsupported(received);
  return DomainItem(
    instrument,
    _tradeEvent(refid, instrument, TradeType.buy, fiat, quantity, amount),
  );
}

MappedItem _sell(
  String refid,
  Instrument instrument,
  KrakenRow fiat,
  KrakenRow delivered,
) {
  final quantity = _net(delivered).abs();
  final amount = _absOf(fiat.amount);
  if (quantity.isZero || amount.isZero) return _unsupported(delivered);
  return DomainItem(
    instrument,
    _tradeEvent(refid, instrument, TradeType.sell, fiat, quantity, amount),
  );
}

typedef _Value = ({
  Dec gross,
  Dec fee,
  String currency,
  String valuationSource,
});

_Value? _swapLegValue(
  KrakenRow row,
  Instrument instrument,
  PriceAt priceAt, {
  required bool received,
}) {
  final fee = Dec.parse(_orZero(row.fee));
  final amount = Dec.parse(_orZero(row.amount)).abs();

  if (row.amountusd.isNotEmpty && (fee.isZero || row.feeusd.isNotEmpty)) {
    final usd = Dec.parse(row.amountusd).abs();
    final feeUsd = Dec.parse(_orZero(row.feeusd));
    return (
      gross: received ? usd - feeUsd : usd + feeUsd,
      fee: received ? feeUsd : Dec.zero,
      currency: 'USD',
      valuationSource: 'kraken-amountusd',
    );
  }

  final priced = priceAt(instrument.id, parseKrakenTime(row.time)!);
  if (priced == null) return null;
  Dec worth(Dec quantity) => priced.price.scaleBy(quantity).amount;
  return (
    gross: received ? worth(amount - fee) : worth(amount + fee),
    fee: received ? worth(fee) : Dec.zero,
    currency: priced.currency,
    valuationSource: 'yahoo',
  );
}

List<MappedItem> _swap(
  String refid,
  KrakenRow spend,
  KrakenRow receive,
  String pair,
  PriceAt priceAt,
) {
  final delivered = _cryptoInstrument(spend.asset);
  final arrived = _cryptoInstrument(receive.asset);
  if (delivered == null) {
    return [_discard(DiscardReason.invalidCryptoCode, spend)];
  }
  if (arrived == null) {
    return [_discard(DiscardReason.invalidCryptoCode, receive)];
  }

  final deliveredQuantity = _net(spend).abs();
  final receivedQuantity = _net(receive);
  if (deliveredQuantity.isZero || !receivedQuantity.isPositive) {
    return [_unsupported(receive)];
  }

  final out = _swapLegValue(spend, delivered, priceAt, received: false);
  final into = _swapLegValue(receive, arrived, priceAt, received: true);
  if (out == null || into == null) {
    final detail = _detailOf(receive, pair);
    return [
      DiscardItem(
        DiscardReason.swapUnpriced,
        detail: DiscardDetail(
          date: detail.date,
          type: detail.type,
          subtype: detail.subtype,
          instrument: detail.instrument,
          unpriced: [
            if (out == null) delivered.id,
            if (into == null) arrived.id,
          ],
        ),
        instrument: delivered,
        related: [arrived],
      ),
    ];
  }

  TradeEvent leg(
    TradeType type,
    KrakenRow row,
    Instrument instrument,
    Dec quantity,
    _Value value,
    String suffix,
  ) =>
      TradeEvent(
        id: uuidV4(),
        ts: parseKrakenTime(row.time)!,
        type: type,
        instrumentId: instrument.id,
        quantity: quantity,
        price: Money.of(value.gross.dividedBy(quantity)),
        grossAmount: Money.of(value.gross),
        fees: Money.of(value.fee),
        currency: value.currency,
        account: _account,
        source: _source,
        externalId: '$refid:$suffix',
        linkId: refid,
        linkKind: 'swap',
        valuationSource: value.valuationSource,
      );

  return [
    DomainItem(
      delivered,
      leg(TradeType.sell, spend, delivered, deliveredQuantity, out, 'sell'),
    ),
    DomainItem(
      arrived,
      leg(TradeType.buy, receive, arrived, receivedQuantity, into, 'buy'),
    ),
  ];
}

typedef _RewardValue = ({
  Money price,
  Money grossAmount,
  String currency,
  String valuationSource,
});

_RewardValue? _valueAtKraken(KrakenRow row, Dec quantity) {
  if (row.amountusd.isEmpty) return null;
  final usd = Dec.parse(row.amountusd) - Dec.parse(_orZero(row.feeusd));
  return (
    price: Money.of(usd.dividedBy(quantity)),
    grossAmount: Money.of(usd),
    currency: 'USD',
    valuationSource: 'kraken-amountusd',
  );
}

_RewardValue? _valueFromHistory(
  Instrument instrument,
  DateTime ts,
  Dec quantity,
  PriceAt priceAt,
) {
  final priced = priceAt(instrument.id, ts);
  if (priced == null) return null;
  return (
    price: priced.price,
    grossAmount: Money.of(priced.price.scaleBy(quantity).amount),
    currency: priced.currency,
    valuationSource: 'yahoo',
  );
}

List<MappedItem> _reward(String refid, KrakenRow row, PriceAt priceAt) {
  final instrument = _cryptoInstrument(row.asset);
  if (instrument == null) {
    return [_discard(DiscardReason.invalidCryptoCode, row)];
  }

  final ts = parseKrakenTime(row.time)!;
  final quantity = _net(row);
  if (!quantity.isPositive) return [_unsupported(row)];

  final value = _valueAtKraken(row, quantity) ??
      _valueFromHistory(instrument, ts, quantity, priceAt);
  if (value == null) {
    final unpriced = _discard(DiscardReason.rewardUnpriced, row);
    return [
      DiscardItem(
        unpriced.reason,
        detail: unpriced.detail,
        instrument: instrument,
      ),
    ];
  }

  return [
    DomainItem(
      instrument,
      TradeEvent(
        id: uuidV4(),
        ts: ts,
        type: TradeType.buy,
        instrumentId: instrument.id,
        quantity: quantity,
        price: value.price,
        grossAmount: value.grossAmount,
        fees: Money.zero,
        funding: Funding.inKind,
        currency: value.currency,
        account: _account,
        source: _source,
        externalId: refid,
        note: krakenRewardNote,
        valuationSource: value.valuationSource,
      ),
    ),
    DomainItem(
      null,
      DividendEvent(
        id: uuidV4(),
        ts: ts,
        instrumentId: instrument.id,
        grossAmount: value.grossAmount,
        taxWithheld: Money.zero,
        funding: Funding.inKind,
        currency: value.currency,
        account: _account,
        source: _source,
        externalId: '$refid:income',
        note: _rewardIncomeNote,
        valuationSource: value.valuationSource,
      ),
    ),
  ];
}

DomainItem _cash(
  String refid,
  KrakenRow row,
  CashType type, [
  String? note,
]) =>
    DomainItem(
      null,
      CashEvent(
        id: uuidV4(),
        ts: parseKrakenTime(row.time)!,
        type: type,
        grossAmount: Money.of(_absOf(row.amount)),
        currency: row.asset,
        account: _account,
        source: _source,
        externalId: refid,
        note: note,
      ),
    );

MappedBatch planKraken(
  String csv,
  BatchBuilder builder, {
  List<PriceSnapshot> prices = const [],
  Map<String, String> names = const {},
  Set<String> rewardRefids = const {},
}) {
  final rows = parseKrakenCsv(csv);
  final mismatch = findBalanceMismatch(rows);
  if (mismatch != null) {
    throw KrakenBalanceMismatch(mismatch.asset, mismatch.wallet, mismatch.date);
  }
  final groups = groupByRefid(rows);
  final priceAt = priceLookupFrom(prices);

  final internal = <KrakenRow>[];
  for (final group in groups.values) {
    final first = group.first;
    if (group.any((row) => parseKrakenTime(row.time) == null)) {
      builder.addError(RowError(first.ref, RowErrorReason.invalidDate));
      continue;
    }
    if (group.every(isInternalMove)) internal.add(first);
    try {
      builder.addOperation(mapKrakenGroup(group, priceAt));
    } on Object catch (error) {
      builder.addError(RowError(first.ref, rowErrorReason(error)));
    }
  }
  for (final row in internal) {
    if (!rewardRefids.contains(row.refid)) continue;
    builder.addNotice(
      NoticeReason.internalBookedAsReward,
      _detailOf(row, row.asset.isEmpty ? null : row.asset),
    );
  }
  final batch = builder.build(groups.length);
  return batch.withInstruments([
    for (final instrument in batch.instruments)
      switch (names[instrument.id]) {
        final name? when name.isNotEmpty => Instrument(
            id: instrument.id,
            name: name,
            type: instrument.type,
            assetClass: instrument.assetClass,
            exposureKind: instrument.exposureKind,
          ),
        _ => instrument,
      },
  ]);
}
