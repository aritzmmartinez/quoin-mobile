import 'package:quoin_core/src/prices/kraken.dart';

const staleSeriesAfter = Duration(days: 7);
const krakenOverlap = Duration(days: 7);
const maxLiveAge = Duration(days: 7);

DateTime utcDay(DateTime instant) {
  final t = instant.toUtc();
  return DateTime.utc(t.year, t.month, t.day);
}

DateTime newestClosedCandle(DateTime now) =>
    utcDay(now).subtract(const Duration(days: 1));

bool isStaleSeries(DateTime? newestCandle, DateTime now) =>
    newestCandle == null ||
    newestCandle.isBefore(newestClosedCandle(now).subtract(staleSeriesAfter));

bool isFreshLive(KrakenQuote quote, DateTime now) =>
    quote.asOf.isAfter(now.subtract(maxLiveAge));

sealed class SeriesOrigin {
  const SeriesOrigin();
}

final class NoOrigin extends SeriesOrigin {
  const NoOrigin();
}

final class PcOrigin extends SeriesOrigin {
  const PcOrigin(this.newestCandle);

  final DateTime? newestCandle;
}

final class KrakenOrigin extends SeriesOrigin {
  const KrakenOrigin(this.symbol, this.newestCandle);

  final String symbol;
  final DateTime? newestCandle;
}

sealed class KrakenStep {
  const KrakenStep();
}

final class KrakenLeave extends KrakenStep {
  const KrakenLeave();
}

final class KrakenDrop extends KrakenStep {
  const KrakenDrop();
}

/// Everything Kraken has (720 daily candles), replacing whatever is stored:
/// a series of another origin or another pair is never mixed in.
final class KrakenFull extends KrakenStep {
  const KrakenFull(this.symbol);

  final String symbol;
}

final class KrakenTail extends KrakenStep {
  const KrakenTail(this.symbol, this.since);

  final String symbol;
  final DateTime? since;
}

KrakenStep planKrakenStep(String? symbol, SeriesOrigin origin, DateTime now) {
  if (symbol == null) {
    return origin is KrakenOrigin ? const KrakenDrop() : const KrakenLeave();
  }
  return switch (origin) {
    PcOrigin(:final newestCandle) when !isStaleSeries(newestCandle, now) =>
      const KrakenLeave(),
    KrakenOrigin(symbol: final held, newestCandle: final newest?)
        when held == symbol =>
      KrakenTail(
        symbol,
        newest.isBefore(newestClosedCandle(now))
            ? newest.subtract(krakenOverlap)
            : null,
      ),
    _ => KrakenFull(symbol),
  };
}

final class StoredPrice {
  const StoredPrice(this.asOf, {required this.live});

  final DateTime asOf;
  final bool live;
}

final class KrakenWrite {
  const KrakenWrite({required this.remove, required this.candles, this.live});

  final List<DateTime> remove;
  final List<KrakenQuote> candles;
  final KrakenQuote? live;
}

KrakenWrite planKrakenWrite(
  List<StoredPrice> stored,
  List<KrakenQuote> candles,
  KrakenQuote? live,
) {
  final candleDays = {for (final c in candles) utcDay(c.asOf)};
  final remove = <DateTime>{
    for (final row in stored)
      if (candleDays.contains(utcDay(row.asOf))) row.asOf,
  };
  KrakenQuote? keep;
  if (live != null) {
    final day = utcDay(live.asOf);
    final covered = candleDays.contains(day) ||
        stored.any((r) => !r.live && utcDay(r.asOf) == day);
    if (!covered) {
      remove.addAll([
        for (final row in stored)
          if (row.live) row.asOf,
      ]);
      keep = live;
    }
  }
  return KrakenWrite(remove: remove.toList(), candles: candles, live: keep);
}
