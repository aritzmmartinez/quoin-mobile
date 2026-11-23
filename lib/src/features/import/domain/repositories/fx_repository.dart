import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';

/// The ECB's daily rates against the euro: the ones stored and the service
/// that publishes them.
abstract interface class FxRepository {
  /// The first and last stored day of [quote]'s series.
  Future<Result<({String? first, String? last})>> span(String quote);

  /// The published rates of [quote] from [from] to [to], both included; empty
  /// for a currency the ECB does not publish. `Err(NetworkFailure)` when the
  /// service cannot be used.
  Future<Result<List<FxRate>>> fetch(String quote, String from, String to);

  /// Stores [rates] of [quote], never overwriting a stored day (see
  /// [planFxWrite]).
  Future<Result<FxWritePlan>> save(String quote, List<FxRate> rates);

  /// The stored series of [quotes].
  Future<Result<RateBook>> book(List<String> quotes);
}
