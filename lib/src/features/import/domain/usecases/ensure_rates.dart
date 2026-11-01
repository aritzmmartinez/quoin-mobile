import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/repositories/fx_repository.dart';

/// Days fetched before a currency's first use, so a row on a holiday finds
/// the rate before it.
const firstUseMarginDays = 7;

/// The stored series of the currencies an import needs, and the ones the ECB
/// could not be asked for.
final class EnsuredRates {
  const EnsuredRates({required this.book, required this.unavailable});

  final RateBook book;
  final List<String> unavailable;
}

/// Where fetching a series starts: [needed] when nothing is stored or the
/// currency is first used before the stored series begins, else its last
/// stored day (fetched again, to notice a revision).
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

/// Brings the ECB series of each currency in [needs] (currency → first day it
/// is used) up to today and returns them, as Quoin's `ensureRates`. A currency
/// the service cannot be asked for is listed as unavailable, not an error: its
/// rows become warnings. A series whose fetched rates disagree with the stored
/// ones keeps the stored ones.
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
      if (await _fx.save(quote, rates) case Err(:final failure)) {
        return Err(failure);
      }
    }

    return switch (await _fx.book(currencies)) {
      Ok(:final value) => Ok(
        EnsuredRates(book: value, unavailable: unavailable),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
