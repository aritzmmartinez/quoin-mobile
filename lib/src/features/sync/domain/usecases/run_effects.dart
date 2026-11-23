import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';

typedef EnsureRatesFrom = Future<Result<List<String>>> Function(
  Map<String, String> needs, {
  required String zone,
});

typedef DropPricesOf = Future<Result<void>> Function(String instrumentId);

class RunEffects {
  const RunEffects(this._ensureRates, this._dropPrices);

  final EnsureRatesFrom _ensureRates;
  final DropPricesOf _dropPrices;

  Future<List<EffectOutcome>> call(
    List<Effect> effects, {
    required Result<String> zone,
  }) async {
    final outcomes = <EffectOutcome>[];
    for (final effect in effects) {
      outcomes.add(switch ((effect, zone)) {
        (RatesEffect(:final currency, :final since), Ok(value: final tz)) =>
          await _rates(effect, currency, dayOf(DateTime.parse(since), tz), tz),
        (RatesEffect(), Err(:final failure)) => EffectFailed(effect, failure),
        (PricesEffect(:final instrumentId), _) => switch (await _dropPrices(
          instrumentId,
        )) {
          Ok() => EffectDone(effect),
          Err(:final failure) => EffectFailed(effect, failure),
        },
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
