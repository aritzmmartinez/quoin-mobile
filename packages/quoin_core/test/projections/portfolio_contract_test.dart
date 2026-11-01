import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

typedef Json = Map<String, dynamic>;

/// An absent fxSource is IDENTITY and an absent funding is CASH, as the
/// contract says.
LedgerEvent eventOf(Json row) {
  String? text(String key) => row[key] as String?;
  final fxRate = text('fxRate');
  final fxDirection = text('fxDirection');
  final common = (
    id: row['id'] as String,
    ts: DateTime.parse(row['ts'] as String),
    currency: row['currency'] as String,
    fxSource: FxSource.of(text('fxSource') ?? 'IDENTITY'),
    fxRate: fxRate == null ? null : Dec.parse(fxRate),
    fxDirection: fxDirection == null ? null : FxDirection.of(fxDirection),
  );
  return TradeEvent(
    id: common.id,
    ts: common.ts,
    type: TradeType.of(row['type'] as String),
    instrumentId: row['instrumentId'] as String,
    quantity: Dec.parse(row['quantity'] as String),
    price: Money.parse(row['price'] as String),
    grossAmount: Money.parse(row['grossAmount'] as String),
    fees: Money.parse(row['fees'] as String),
    currency: common.currency,
    funding: Funding.of(text('funding') ?? 'CASH'),
    fxSource: common.fxSource,
    fxDate: text('fxDate'),
    fxRate: common.fxRate,
    fxDirection: common.fxDirection,
    linkId: text('linkId'),
    linkKind: text('linkKind'),
    account: row['account'] as String,
    source: row['source'] as String,
    externalId: text('externalId'),
  );
}

String? fixed(Dec? value) => value?.toFixed(ratioDecimals);

Json priceJson(PriceSnapshot p) => {
      'instrumentId': p.instrumentId,
      'price': '${p.price}',
      'currency': p.currency,
      'asOf': p.asOf.toIso8601String(),
    };

/// The core's answer for one case, written the way the web writes it.
Json evaluate(Json input) {
  final jurisdiction = jurisdictionOf(
    Residence.values.byName(input['residence'] as String),
  );
  final events = [
    for (final row in (input['events'] as List<dynamic>).cast<Json>())
      eventOf(row),
  ];
  final positions = computePositions(events, jurisdiction);
  final valued = pricesInBase(
    {
      for (final p in (input['prices'] as List<dynamic>).cast<Json>())
        p['instrumentId'] as String: PriceSnapshot(
          instrumentId: p['instrumentId'] as String,
          price: Money.parse(p['price'] as String),
          currency: p['currency'] as String,
          asOf: DateTime.parse(p['asOf'] as String),
        ),
    },
    rateBookFrom([
      for (final r in (input['rates'] as List<dynamic>).cast<Json>())
        FxRate(
          source: r['source'] as String,
          base: r['base'] as String,
          quote: r['quote'] as String,
          day: r['day'] as String,
          rate: Dec.parse(r['rate'] as String),
        ),
    ]),
    DateTime.parse(input['now'] as String),
    jurisdiction.zone,
  );
  final marketValues = computeMarketValues(positions, valued.prices);
  final summary = computePortfolioSummary(positions, marketValues);

  return {
    'unconvertible': unconvertibleInstrumentIds(events),
    'positions': [
      for (final p in positions)
        {
          'instrumentId': p.instrumentId,
          'quantity': '${p.quantity}',
          'costBasis': '${p.costBasis}',
          'averageCost': '${p.averageCost}',
          'realizedPnL': '${p.realizedPnL}',
        },
    ],
    'pricesInBase': {
      'prices': valued.prices.map((id, p) => MapEntry(id, priceJson(p))),
      'unrated': valued.unrated,
    },
    'marketValues': marketValues.map(
      (id, v) => MapEntry(id, {
        'marketValue': v.marketValue?.toString(),
        'unrealizedPnL': v.unrealizedPnL?.toString(),
        'weight': fixed(v.weight),
      }),
    ),
    'summary': {
      'totalValue': '${summary.totalValue}',
      'totalInvested': '${summary.totalInvested}',
      'openCost': '${summary.openCost}',
      'pricedCost': '${summary.pricedCost}',
      'unpricedCost': '${summary.unpricedCost}',
      'unrealizedPnL': '${summary.unrealizedPnL}',
      'realizedPnL': '${summary.realizedPnL}',
      'returnPct': fixed(summary.returnPct),
      'pricedCount': summary.pricedCount,
      'unpricedCount': summary.unpricedCount,
    },
    'allocation': [
      for (final slice in computeAllocation(
        positions,
        marketValues,
        (input['categories'] as Json).cast<String, String>(),
      ))
        {
          'category': slice.category,
          'value': '${slice.value}',
          'weight': fixed(slice.weight),
        },
    ],
    'top': [
      for (final row in computeTopPositions(
        positions,
        marketValues,
        input['topLimit'] as int,
      ))
        {
          'instrumentId': row.instrumentId,
          'marketValue': '${row.marketValue}',
          'weight': fixed(row.weight),
          'unrealizedPnL': '${row.unrealizedPnL}',
          'unrealizedPnLPct': fixed(row.unrealizedPnLPct),
        },
    ],
  };
}

void main() {
  final contract =
      jsonDecode(File('test/contract/portfolio.json').readAsStringSync())
          as Json;
  final cases = (contract['cases'] as List<dynamic>).cast<Json>();

  group('portfolio contract', () {
    for (final c in cases) {
      group(c['name'] as String, () {
        final actual = evaluate(c);
        final expected = c['expect'] as Json;

        for (final step in expected.keys) {
          test(step, () => expect(actual[step], expected[step]));
        }

        final byHand = c['byHand'] as Json?;
        if (byHand != null) {
          test('agrees with the figures worked out by hand', () {
            final summary = actual['summary'] as Json;
            final held = {
              for (final p
                  in (actual['positions'] as List<dynamic>).cast<Json>())
                p['instrumentId']: {
                  'quantity': p['quantity'],
                  'costBasis': p['costBasis'],
                },
            };
            for (final MapEntry(key: id, value: figures)
                in (byHand['positions'] as Json).entries) {
              expect(held[id], figures, reason: id);
            }
            expect(summary['totalValue'], byHand['totalValue']);
            expect(summary['unrealizedPnL'], byHand['unrealizedPnL']);
            for (final optional in ['openCost', 'realizedPnL']) {
              if (byHand.containsKey(optional)) {
                expect(summary[optional], byHand[optional], reason: optional);
              }
            }
          });
        }
      });
    }

    test('works at least three cases out by hand', () {
      expect(cases.where((c) => c['byHand'] != null).length,
          greaterThanOrEqualTo(3));
    });
  });
}
