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

/// Brings the ECB rates [needs] asks for (currency to the day of its first
/// use), asking the ECB only for what it may have published since the
/// stored series ends (`ecbFetchFrom`), and not again for a while after an
/// answer that lacked the expected day (`EcbHold`). Without [withBook] the
/// stored series are not read back, for callers that only need to know
/// what could not be brought.
class EnsureRates {
  EnsureRates(this._fx, {EcbHold? hold}) : _hold = hold ?? EcbHold();

  final FxRepository _fx;
  final EcbHold _hold;

  Future<Result<EnsuredRates>> call(
    Map<String, String> needs, {
    required DateTime now,
    required String zone,
    bool withBook = true,
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
      final from = ecbFetchFrom(
        needed: shiftDay(used, -firstUseMarginDays),
        firstUse: used,
        stored: stored,
        now: now,
      );
      if (from == null || (from == stored.last && _hold.holds(quote, now))) {
        continue;
      }
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
      final newest = [
        ?stored.last,
        for (final rate in rates) rate.day,
      ].fold<String?>(null, (a, b) => a == null || b.compareTo(a) > 0 ? b : a);
      _hold.answered(quote, newest, now);
    }

    if (!withBook) {
      return Ok(
        EnsuredRates(
          book: const {},
          unavailable: unavailable,
          conflicts: conflicts,
        ),
      );
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
