import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

typedef Json = Map<String, dynamic>;

void main() {
  final contract =
      jsonDecode(File('test/contract/ingest.json').readAsStringSync()) as Json;

  for (final c in (contract['cases'] as List).cast<Json>()) {
    test(c['name'] as String, () {
      expect(_evaluate(c), _normalized(c['expect'] as Json));
    });
  }
}

Json _evaluate(Json input) {
  final csv = input['csv'] as String;
  final bytes =
      input['encoding'] == 'latin1' ? latin1.encode(csv) : utf8.encode(csv);
  final String text;
  try {
    text = decodeCsv(bytes);
  } on IngestRejection catch (e) {
    return {'broker': null, 'rejected': _rejection(e)};
  }
  final broker = detectBroker(text);
  if (broker == null) {
    return {
      'broker': null,
      'rejected': {'reason': 'unknown-broker'},
    };
  }

  final stored = input['stored'] as Json;
  final context = IngestContext(
    zone: input['zone'] as String,
    rates: rateBookFrom([
      for (final r in (input['rates'] as List).cast<Json>())
        FxRate(
          source: r['source'] as String,
          base: r['base'] as String,
          quote: r['quote'] as String,
          day: r['day'] as String,
          rate: Dec.parse(r['rate'] as String),
        ),
    ]),
    prices: [
      for (final p in (input['prices'] as List).cast<Json>())
        PriceSnapshot(
          instrumentId: p['instrumentId'] as String,
          price: Money.parse(p['price'] as String),
          currency: p['currency'] as String,
          asOf: DateTime.parse(p['asOf'] as String),
          source: p['source'] as String,
        ),
    ],
    names: (stored['names'] as Json).cast<String, String>(),
    rewardRefids: (stored['rewardRefids'] as List).cast<String>().toSet(),
  );

  final MappedBatch batch;
  try {
    batch = planIngest(broker, text, context);
  } on IngestRejection catch (e) {
    return {'broker': broker.code, 'rejected': _rejection(e)};
  }
  final existing = {
    for (final key in (stored['existing'] as List).cast<String>())
      (key.split('::').first, key.split('::').last),
  };
  final (:imported, :completed, :duplicates) = countOperations(batch, existing);
  final discarded = batch.discarded.values.fold(0, (sum, n) => sum + n);
  expect(
    imported + completed + duplicates + discarded + batch.failed,
    batch.total,
    reason: 'every operation is counted once',
  );
  expect(batch.failed, batch.errors.length);
  return {
    'broker': broker.code,
    'total': batch.total,
    'instruments': [
      for (final i in batch.instruments)
        {
          'id': i.id,
          'name': i.name,
          'type': i.type,
          'assetClass': i.assetClass,
          'thesis': 'CORE',
        },
    ],
    'events': [for (final e in batch.events) _event(e)],
    'operationOf': batch.operationOf,
    'discarded': {
      for (final MapEntry(:key, :value) in batch.discarded.entries)
        key.code: value,
    },
    'discardedDetails': {
      for (final MapEntry(:key, :value) in batch.discardedDetails.entries)
        key.code: [for (final d in value) _detail(d)],
    },
    'noticed': {
      for (final MapEntry(:key, :value) in batch.noticed.entries)
        key.code: [for (final d in value) _detail(d)],
    },
    'errors': [for (final e in batch.errors) _error(e)],
    'ratesNeeded': batch.ratesNeeded,
    'failed': batch.failed,
    'imported': imported,
    'completed': completed,
    'duplicates': duplicates,
  };
}

Json _rejection(IngestRejection rejection) => switch (rejection) {
      CsvFileError(:final reason, :final column, :final row) => {
          'reason': reason.code,
          if (column != null) 'column': column,
          if (row != null) 'row': _row(row),
        },
      KrakenLegacyExport() => {'reason': 'kraken-legacy-export'},
      KrakenBalanceMismatch(:final asset, :final wallet, :final date) => {
          'reason': 'kraken-balance-mismatch',
          'asset': asset,
          'wallet': wallet,
          'date': date,
        },
      InvalidLedgerEvent(:final date, :final type, :final currency) => {
          'reason': 'invalid-ledger-event',
          'date': date,
          'type': type,
          'currency': currency,
        },
    };

Json _row(RowRef row) => {
      'externalId': row.externalId,
      'position': row.position,
      'date': row.date,
      'type': row.type,
    };

Json _error(RowError e) => {
      ..._row(e.row),
      'reason': e.reason.code,
      if (e.rows.isNotEmpty) 'rows': [for (final r in e.rows) _error(r)],
    };

Json _detail(DiscardDetail d) => {
      'date': d.date,
      'type': d.type,
      'subtype': d.subtype,
      'instrument': d.instrument,
      if (d.unpriced != null) 'unpriced': d.unpriced,
      if (d.affectsPosition != null) 'affectsPosition': d.affectsPosition,
      if (d.rows.isNotEmpty) 'rows': [for (final r in d.rows) _detail(r)],
    };

Json _event(LedgerEvent e) => {
      'ts': isoInstant(e.ts),
      'currency': e.currency,
      'fxSource': e.fxSource.code,
      'fxDate': e.fxDate,
      'fxRate': e.fxRate?.text,
      'fxDirection': e.fxDirection?.code,
      'originalAmount': e.originalAmount?.text,
      'originalCurrency': e.originalCurrency,
      'valuationSource': e.valuationSource,
      'linkId': e.linkId,
      'linkKind': e.linkKind,
      'account': e.account,
      'source': e.source,
      'externalId': e.externalId,
      'note': e.note,
      'type': ledgerTypeOf(e),
      ...switch (e) {
        TradeEvent() => {
            'instrumentId': e.instrumentId,
            'quantity': e.quantity.text,
            'price': e.price.text,
            'grossAmount': e.grossAmount.text,
            'fees': e.fees.text,
            'funding': e.funding.code,
          },
        DividendEvent() => {
            'instrumentId': e.instrumentId,
            'grossAmount': e.grossAmount.text,
            'taxWithheld': e.taxWithheld.text,
            'funding': e.funding.code,
          },
        CashEvent() => {'grossAmount': e.grossAmount.text},
      },
    };

Json _normalized(Json expected) {
  final events = expected['events'] as List?;
  if (events == null) return expected;
  return {
    ...expected,
    'events': [
      for (final e in events.cast<Json>())
        {
          'fxSource': 'IDENTITY',
          for (final key in [
            'fxDate',
            'fxRate',
            'fxDirection',
            'originalAmount',
            'originalCurrency',
            'valuationSource',
            'linkId',
            'linkKind',
            'externalId',
            'note',
          ])
            key: null,
          if (e['type'] case 'BUY' || 'SELL' || 'DIVIDEND') 'funding': 'CASH',
          ...e,
        },
    ],
  };
}
