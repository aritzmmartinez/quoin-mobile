import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

import '../support/ledger_rows.dart';

NetOf netOf(Json nets) =>
    (year) => Dec.parse((nets['$year'] as String?) ?? '0');

Json step(PoolStep s) => {
      'year': s.year,
      'ownNet': '${s.ownNet}',
      'crossOffset': '${s.crossOffset}',
      'consumedFromCarryforward': '${s.consumedFromCarryforward}',
      'finalNet': '${s.finalNet}',
      'pendingLossRemaining': '${s.pendingLossRemaining}',
    };

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

  // No contract pins a positive limit yet; régimen común will.
  test(
      'a positive cross limit lets a loss in one pool take that share of '
      "the other's gain", () {
    final result = carryforwardPools(
      (netOf({'2026': '-100'}), netOf({'2026': '200'})),
      2026,
      4,
      '0.25',
    );
    final (gains, income) = result.pools;
    expect(gains.steps.last.crossOffset, Dec.parse('50'));
    expect(gains.finalNet, Dec.parse('-50'));
    expect(gains.steps.last.pendingLossRemaining, Dec.parse('50'));
    expect(income.steps.last.crossOffset, Dec.parse('-50'));
    expect(income.finalNet, Dec.parse('150'));
    expect(result.savingsBase, Dec.parse('150'));
  });

  test('a positive cross limit never takes more than the loss', () {
    final (gains, income) = carryforwardPools(
      (netOf({'2026': '300'}), netOf({'2026': '-10'})),
      2026,
      4,
      '0.25',
    ).pools;
    expect(gains.finalNet, Dec.parse('290'));
    expect(income.finalNet, Dec.parse('0'));
    expect(income.steps.last.pendingLossRemaining, Dec.zero);
  });
}
