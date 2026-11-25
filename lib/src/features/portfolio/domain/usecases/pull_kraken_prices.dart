import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/kraken_target.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/kraken_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';

class KrakenHold {
  KrakenHold({
    this.afterAnswer = const Duration(minutes: 5),
    this.afterNothing = const Duration(hours: 12),
  });

  final Duration afterAnswer;
  final Duration afterNothing;
  final _until = <String, DateTime>{};

  bool holds(String symbol, DateTime now) =>
      _until[symbol]?.isAfter(now) ?? false;

  void answered(String symbol, DateTime now, {required bool empty}) =>
      _until[symbol] = now.add(empty ? afterNothing : afterAnswer);
}

final class KrakenOutcome {
  const KrakenOutcome({
    required this.updated,
    this.unavailableRates = const [],
  });

  final int updated;
  final List<String> unavailableRates;
}

class PullKrakenPrices {
  PullKrakenPrices(
    this._repository,
    this._ensureRates,
    this._hold, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final KrakenRepository _repository;
  final EnsureRatesFrom _ensureRates;
  final KrakenHold _hold;
  final DateTime Function() _now;

  Future<Result<KrakenOutcome>> call() async {
    final List<KrakenTarget> targets;
    switch (await _repository.targets()) {
      case Ok(:final value):
        targets = value;
      case Err(:final failure):
        return Err(failure);
    }
    var updated = 0;
    final firstOf = <String, String>{};
    for (final target in targets) {
      final now = _now();
      final step = planKrakenStep(target.symbol, target.origin, now);
      final String symbol;
      final DateTime? since;
      switch (step) {
        case KrakenLeave():
          continue;
        case KrakenDrop():
          if (await _repository.drop(target.instrumentId) case Err(
            :final failure,
          )) {
            return Err(failure);
          }
          continue;
        case KrakenFull(symbol: final s):
          (symbol, since) = (s, null);
        case KrakenTail(symbol: final s, since: final from):
          (symbol, since) = (s, from);
      }
      if (_hold.holds(symbol, now)) continue;

      var candles = const <KrakenQuote>[];
      if (step is KrakenFull || since != null) {
        switch (await _repository.candles(symbol, since)) {
          case Ok(:final value):
            candles = value;
          case Err(:final failure):
            return Err(failure);
        }
      }
      KrakenQuote? live;
      switch (await _repository.lastTrade(symbol)) {
        case Ok(:final value?) when isFreshLive(value, now):
          live = value;
        case Ok():
          break;
        case Err(:final failure):
          return Err(failure);
      }
      final empty = candles.isEmpty && live == null;
      _hold.answered(symbol, now, empty: empty);
      if (empty) continue;

      switch (await _repository.write(
        target.instrumentId,
        step,
        candles,
        live,
      )) {
        case Ok(:final value):
          updated += 1;
          for (final MapEntry(key: currency, value: at) in value.entries) {
            final known = firstOf[currency];
            if (known == null || at.compareTo(known) < 0) {
              firstOf[currency] = at;
            }
          }
        case Err(:final failure):
          return Err(failure);
      }
    }

    if (firstOf.isEmpty) return Ok(KrakenOutcome(updated: updated));
    final zone = switch (await _repository.zone()) {
      Ok(:final value) => value,
      Err() => null,
    };
    final unavailable = zone == null
        ? (firstOf.keys.toList()..sort())
        : switch (await _ensureRates({
            for (final MapEntry(key: currency, value: at) in firstOf.entries)
              currency: dayOf(DateTime.parse(at), zone),
          }, zone: zone)) {
            Ok(:final value) => value,
            Err() => (firstOf.keys.toList()..sort()),
          };
    return Ok(KrakenOutcome(updated: updated, unavailableRates: unavailable));
  }
}
