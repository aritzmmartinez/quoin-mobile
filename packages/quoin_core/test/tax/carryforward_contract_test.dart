import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

import '../support/ledger_rows.dart';

NetOf netOf(Json nets) =>
    (year) => Dec.parse((nets['$year'] as String?) ?? '0');

Json pool(PoolResult p) => {
      'steps': p.steps.map(step).toList(),
      'finalNet': '${p.finalNet}',
    };

/// The core's answer for one case, written the way the web writes it.
Json evaluate(Json input) {
  final pools = (input['pools'] as List<dynamic>).cast<Json>();
  final year = input['targetYear'] as int;
  final years = input['years'] as int;
  if (pools.length == 1) {
    return pool(carryforwardPool(netOf(pools.single), year, years));
  }
  final result = carryforwardPools(
    (netOf(pools[0]), netOf(pools[1])),
    year,
    years,
    (input['crossOffsetLimit'] as String?) ?? '0',
  );
  return {
    'targetYear': result.targetYear,
    'pools': [pool(result.pools.$1), pool(result.pools.$2)],
    'savingsBase': '${result.savingsBase}',
  };
}

void main() {
  group('carryforward contract', () {
    for (final c in contractCases('carryforward')) {
      group(c['name'] as String, () {
        final actual = evaluate(c);
        test('expect', () => expect(actual, c['expect']));
        for (final MapEntry(key: path, value: figure)
            in byHandFigures(c).entries) {
          test('by hand: $path', () => expect(at(actual, path), figure));
        }
      });
    }
  });
}
