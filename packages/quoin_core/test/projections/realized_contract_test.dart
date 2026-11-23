import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

import '../support/ledger_rows.dart';

List<Json> evaluate(Json input) => [
      for (final s in computeRealizedGains(
        eventsOf(input),
        jurisdictionOf(Residence.values.byName(input['residence'] as String)),
      ))
        {
          'eventId': s.eventId,
          'ts': s.ts.toIso8601String(),
          'instrumentId': s.instrumentId,
          'quantity': '${s.quantity}',
          'price': s.price?.toString(),
          'grossAmount': '${s.grossAmount}',
          'fees': '${s.fees}',
          'costBasis': '${s.costBasis}',
          'realizedPnL': '${s.realizedPnL}',
          'returnPct': s.returnPct?.toFixed(6),
          'holdingDays': s.holdingDays,
        },
    ];

void main() {
  group('realized contract', () {
    for (final c in contractCases('realized')) {
      group(c['name'] as String, () {
        final actual = evaluate(c);
        test('matches the web', () => expect(actual, c['expect']));
        for (final MapEntry(key: path, value: figure)
            in byHandFigures(c).entries) {
          test('by hand: $path', () => expect(at(actual, path), figure));
        }
      });
    }
  });
}
