import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';

class PullPrices {
  const PullPrices(
    this._repository,
    this._ensureRates, {
    this.attempts = 4,
    this.interval = const Duration(seconds: 3),
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  final SyncRepository _repository;
  final EnsureRatesFrom _ensureRates;
  final int attempts;
  final Duration interval;
  final Future<void> Function(Duration) _wait;

  Future<Result<PricesOutcome>> call(
    Pairing pairing,
    String deviceId, {
    required Result<String> zone,
  }) async {
    var updated = 0;
    var pending = <String>[];
    final firstOf = <String, String>{};
    Set<String>? only;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) await _wait(interval);
      final List<PriceHolding> holdings;
      switch (await _repository.priceHoldings()) {
        case Ok(:final value):
          holdings = [
            for (final h in value)
              if (only == null || only.contains(h.instrumentId)) h,
          ];
        case Err(:final failure):
          return Err(failure);
      }
      if (holdings.isEmpty) break;

      final List<PriceAnswer> answers;
      switch (await _repository.fetchPrices(pairing, deviceId, holdings)) {
        case Ok(:final value):
          answers = value;
        case Err(:final failure):
          return Err(failure);
      }
      switch (await _repository.savePrices(answers)) {
        case Ok(:final value):
          for (final MapEntry(key: currency, value: at) in value.entries) {
            final known = firstOf[currency];
            if (known == null ||
                DateTime.parse(at).isBefore(DateTime.parse(known))) {
              firstOf[currency] = at;
            }
          }
        case Err(:final failure):
          return Err(failure);
      }
      pending = [
        for (final a in answers)
          if (a is PendingPrices) a.instrumentId,
      ];
      updated += answers.length - pending.length;
      if (pending.isEmpty) break;
      only = pending.toSet();
    }

    var unavailable = const <String>[];
    if (firstOf.isNotEmpty) {
      switch (zone) {
        case Ok(value: final tz):
          final needs = {
            for (final MapEntry(key: currency, value: at) in firstOf.entries)
              currency: dayOf(DateTime.parse(at), tz),
          };
          unavailable = switch (await _ensureRates(needs, zone: tz)) {
            Ok(:final value) => value,
            Err() => (needs.keys.toList()..sort()),
          };
        case Err():
          unavailable = firstOf.keys.toList()..sort();
      }
    }
    return Ok(
      PricesOutcome(
        updated: updated,
        pending: pending,
        unavailableRates: unavailable,
      ),
    );
  }
}
