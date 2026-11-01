import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/fx_repository.dart';

const firstUseMarginDays = 7;

final class EnsuredRates {
  const EnsuredRates({
    required this.book,
    required this.unavailable,
    this.conflicts = const [],
  });

  final RateBook book;
  final List<String> unavailable;
  final List<RateConflict> conflicts;
}

String syncStart(
  String needed,
  String? firstUse,
  ({String? first, String? last}) stored,
) {
  final (:first, :last) = stored;
  if (first == null || last == null) return needed;
  if (firstUse != null && firstUse.compareTo(first) < 0) return needed;
  return last;
}

class EnsureRates {
  const EnsureRates(this._fx);

  final FxRepository _fx;

  Future<Result<EnsuredRates>> call(
    Map<String, String> needs, {
    required DateTime now,
    required String zone,
  }) async {
    final currencies = [
      for (final currency in needs.keys)
        if (currency != baseCurrency) currency,
    ]..sort();
    if (currencies.isEmpty) {
      return const Ok(EnsuredRates(book: {}, unavailable: []));
    }

    final to = today(zone, now);
    final unavailable = <String>[];
    final conflicts = <RateConflict>[];
    for (final quote in currencies) {
      final used = needs[quote]!;
      final ({String? first, String? last}) stored;
      switch (await _fx.span(quote)) {
        case Ok(:final value):
          stored = value;
        case Err(:final failure):
          return Err(failure);
      }
      final from = syncStart(shiftDay(used, -firstUseMarginDays), used, stored);
      final List<FxRate> rates;
      switch (await _fx.fetch(quote, from, to)) {
        case Ok(:final value):
          rates = value;
        case Err(failure: NetworkFailure()):
          unavailable.add(quote);
          continue;
        case Err(:final failure):
          return Err(failure);
      }
      switch (await _fx.save(quote, rates)) {
        case Ok(value: FxWritePlan(conflicts: [_, ...] && final found)):
          final days = [for (final c in found) c.stored.day]..sort();
          conflicts.add((currency: quote, day: days.first));
        case Ok():
          break;
        case Err(:final failure):
          return Err(failure);
      }
    }

    return switch (await _fx.book(currencies)) {
      Ok(:final value) => Ok(
        EnsuredRates(
          book: value,
          unavailable: unavailable,
          conflicts: conflicts,
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
