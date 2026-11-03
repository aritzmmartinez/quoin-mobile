import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';

typedef EnsureRatesFrom = Future<Result<List<String>>> Function(
  Map<String, String> needs, {
  required String zone,
});

class RunEffects {
  const RunEffects(this._ensureRates);

  final EnsureRatesFrom _ensureRates;

  Future<List<EffectOutcome>> call(
    List<Effect> effects, {
    required String zone,
  }) async {
    final outcomes = <EffectOutcome>[];
    for (final effect in effects) {
      outcomes.add(switch (effect) {
        RatesEffect(:final currency, :final since) => await _rates(
          effect,
          currency,
          dayOf(DateTime.parse(since), zone),
          zone,
        ),
        PricesEffect() => EffectPending(effect),
      });
    }
    return outcomes;
  }

  Future<EffectOutcome> _rates(
    Effect effect,
    String currency,
    String since,
    String zone,
  ) async => switch (await _ensureRates({currency: since}, zone: zone)) {
    Ok(:final value) when value.contains(currency) => EffectFailed(
      effect,
      const NetworkFailure(),
    ),
    Ok() => EffectDone(effect),
    Err(:final failure) => EffectFailed(effect, failure),
  };
}
