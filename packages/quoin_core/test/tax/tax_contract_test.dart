import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

import '../support/ledger_rows.dart';

String iso(DateTime instant) => instant.toIso8601String();

Json day(CalendarDate d) => {'year': d.year, 'month': d.month, 'day': d.day};

Json window(WashSaleWindow w) => {'start': day(w.start), 'end': day(w.end)};

List<Json> pieces(List<DeferredLossPiece> pieces) => [
      for (final p in pieces)
        {'originEventId': p.originEventId, 'amount': '${p.amount}'},
    ];

Json gain(RealizedGainDetail g) {
  final wash = g.washSale;
  final a = wash?.assessment;
  return {
    'eventId': g.eventId,
    'ts': iso(g.ts),
    'instrumentId': g.instrumentId,
    'quantity': '${g.sale.quantity}',
    'grossAmount': '${g.sale.gross}',
    'fees': '${g.sale.fees}',
    'costBasis': '${g.sale.costRemoved}',
    'realizedPnL': '${g.realizedPnL}',
    'lots': [
      for (final lot in g.sale.lots)
        {
          'buyEventId': lot.lotId,
          'acquiredAt': iso(lot.acquiredAt),
          'quantity': '${lot.quantity}',
          'unitCost': '${lot.unitCost}',
        },
    ],
    'computablePnL': '${g.computablePnL}',
    'nonComputable': '${g.nonComputable}',
    'carriedOver': '${g.carriedOver}',
    'washSale': wash == null || a == null
        ? null
        : {
            'letter': wash.letter.name,
            'windowMonths': wash.windowMonths,
            'window': window(a.window),
            'before': '${a.before}',
            'remainingAfter': '${a.remainingAfter}',
            'repurchaseBefore': '${a.repurchaseBefore}',
            'repurchaseAfter': '${a.repurchaseAfter}',
            'repurchased': '${a.repurchased}',
            'fraction': '${a.fraction}',
            'recipients': [
              for (final r in wash.recipients)
                {
                  'buyEventId': r.buyEventId,
                  'acquiredAt': iso(r.acquiredAt),
                  'quantity': '${r.quantity}',
                  'deferredLoss': '${r.deferredLoss}',
                },
            ],
          },
    'repurchaseWindow': switch (g.repurchaseWindow) {
      null => null,
      (:final letter, window: final w) => {
          'letter': letter.name,
          'window': window(w),
        },
    },
    'unlistedNotice': switch (g.unlistedNotice) {
      null => null,
      (:final buyEventId, :final buyTs) => {
          'buyEventId': buyEventId,
          'buyTs': iso(buyTs),
        },
    },
  };
}

List<Json> integrations(List<DeferredLossIntegration> list) => [
      for (final i in list)
        {
          'originEventId': i.originEventId,
          'originTs': iso(i.originTs),
          'integratedByEventId': i.integratedByEventId,
          'ts': iso(i.ts),
          'instrumentId': i.instrumentId,
          'amount': '${i.amount}',
        },
    ];

List<Json> pending(List<PendingDeferredLossDetail> list) => [
      for (final p in list)
        {
          'buyEventId': p.buyEventId,
          'acquiredAt': iso(p.acquiredAt),
          'instrumentId': p.instrumentId,
          'pieces': pieces(p.pieces),
        },
    ];

/// The core's answer for one case, written the way the web writes it.
Json evaluate(Json input) {
  final jurisdiction =
      jurisdictionOf(Residence.values.byName(input['residence'] as String));
  final events = eventsOf(input);
  final instruments = [
    for (final i in (input['instruments'] as List<dynamic>).cast<Json>())
      Instrument(
        id: i['id'] as String,
        name: i['id'] as String,
        type: i['type'] as String,
      ),
  ];
  final scope = taxScopeFor(instruments, jurisdiction);
  final history = computeTaxHistory(events, scope);

  return {
    'assetClasses': {
      for (final MapEntry(:key, :value) in scope.assetClasses.entries)
        key: value.code,
    },
    'history': {
      'gains': history.gains.map(gain).toList(),
      'integrations': integrations(history.integrations),
      'pendingByYear': {
        for (final MapEntry(:key, :value) in history.pendingByYear.entries)
          '$key': pending(value),
      },
    },
    'years': {
      for (final year in (input['years'] as List<dynamic>).cast<int>())
        '$year': () {
          final taxYear = taxYearOf(history, year);
          final carry = carryforwardFrom(history, year);
          final view = buildTaxYearView(events, history, year);
          final scale = view.scale;
          return {
            'taxYear': {
              'year': taxYear.year,
              'territory': taxYear.territory.name,
              'gains': taxYear.gains.map(gain).toList(),
              'integrations': integrations(taxYear.integrations),
              'pending': pending(taxYear.pending),
              'computableNet': '${taxYear.computableNet}',
            },
            'carryforward': {
              'targetYear': carry.targetYear,
              'steps': [
                for (final s in carry.steps)
                  {
                    'year': s.year,
                    'ownNet': '${s.ownNet}',
                    'consumedFromCarryforward': '${s.consumedFromCarryforward}',
                    'finalNet': '${s.finalNet}',
                    'pendingLossRemaining': '${s.pendingLossRemaining}',
                  },
              ],
              'netSavingsBase': '${carry.netSavingsBase}',
            },
            'view': {
              'affectedCount': view.affectedCount,
              'ownNet': view.ownNet.toFixed(2),
              'nonComputableSum': view.nonComputableSum.toFixed(2),
              'integratedSum': view.integratedSum.toFixed(2),
              'computableNet': '${view.computableNet}',
              'pendingSum': view.pendingSum.toFixed(2),
              'netSavingsBase': '${view.netSavingsBase}',
              'scale': scale == null
                  ? null
                  : {
                      'source': scale.source,
                      'brackets': [
                        for (final b in scale.brackets)
                          {'from': b.from, 'to': b.to, 'rate': b.rate},
                      ],
                    },
              'quota': view.quota?.toString(),
              'inKindIncome': {
                'count': view.inKindIncome.count,
                'gross': view.inKindIncome.gross.amount.toFixed(2),
                'withheld': view.inKindIncome.withheld.amount.toFixed(2),
              },
            },
          };
        }(),
    },
  };
}

void main() {
  group('tax contract', () {
    for (final c in contractCases('tax')) {
      group(c['name'] as String, () {
        final actual = evaluate(c);
        final expected = c['expect'] as Json;
        for (final part in ['assetClasses', 'history', 'years']) {
          test(part, () => expect(actual[part], expected[part]));
        }
        for (final MapEntry(key: path, value: figure)
            in byHandFigures(c).entries) {
          test('by hand: $path', () => expect(at(actual, path), figure));
        }
      });
    }
  });
}
