import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';

typedef Json = Map<String, dynamic>;

List<Json> contractCases(String name) =>
    ((jsonDecode(File('test/contract/$name.json').readAsStringSync())
            as Json)['cases'] as List<dynamic>)
        .cast<Json>();

List<LedgerEvent> eventsOf(Json input) => [
      for (final row in (input['events'] as List<dynamic>).cast<Json>())
        eventOf(row),
    ];

LedgerEvent eventOf(Json row) {
  String? text(String key) => row[key] as String?;
  final fxRate = text('fxRate');
  final fxDirection = text('fxDirection');
  final id = row['id'] as String;
  final ts = DateTime.parse(row['ts'] as String);
  final currency = row['currency'] as String;
  final fxSource = FxSource.of(text('fxSource') ?? 'IDENTITY');
  final rate = fxRate == null ? null : Dec.parse(fxRate);
  final direction = fxDirection == null ? null : FxDirection.of(fxDirection);
  final funding = Funding.of(text('funding') ?? 'CASH');

  if (CashType.values.any((t) => t.code == row['type'])) {
    return CashEvent(
      id: id,
      ts: ts,
      type: CashType.of(row['type'] as String),
      grossAmount: Money.parse(row['grossAmount'] as String),
      currency: currency,
      fxSource: fxSource,
      fxDate: text('fxDate'),
      fxRate: rate,
      fxDirection: direction,
      account: row['account'] as String,
      source: row['source'] as String,
      externalId: text('externalId'),
    );
  }
  if (row['type'] == 'DIVIDEND') {
    return DividendEvent(
      id: id,
      ts: ts,
      instrumentId: row['instrumentId'] as String,
      grossAmount: Money.parse(row['grossAmount'] as String),
      taxWithheld: Money.parse(row['taxWithheld'] as String),
      currency: currency,
      funding: funding,
      fxSource: fxSource,
      fxDate: text('fxDate'),
      fxRate: rate,
      fxDirection: direction,
      linkId: text('linkId'),
      linkKind: text('linkKind'),
      account: row['account'] as String,
      source: row['source'] as String,
      externalId: text('externalId'),
    );
  }
  return TradeEvent(
    id: id,
    ts: ts,
    type: TradeType.of(row['type'] as String),
    instrumentId: row['instrumentId'] as String,
    quantity: Dec.parse(row['quantity'] as String),
    price: Money.parse(row['price'] as String),
    grossAmount: Money.parse(row['grossAmount'] as String),
    fees: Money.parse(row['fees'] as String),
    currency: currency,
    funding: funding,
    fxSource: fxSource,
    fxDate: text('fxDate'),
    fxRate: rate,
    fxDirection: direction,
    linkId: text('linkId'),
    linkKind: text('linkKind'),
    account: row['account'] as String,
    source: row['source'] as String,
    externalId: text('externalId'),
  );
}

Object? at(Object? json, String path) {
  var node = json;
  for (final key in path.split('.')) {
    node = node is List ? node[int.parse(key)] : (node as Json)[key];
  }
  return node;
}

Map<String, Object?> byHandFigures(Json contractCase) =>
    ((contractCase['byHand'] as Json?)?['figures'] as Json?) ?? const {};
