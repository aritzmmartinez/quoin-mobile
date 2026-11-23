import 'rates.dart';

/// A stored rate and a fetched one for the same day that disagree.
typedef FxConflict = ({FxRate stored, FxRate incoming});

/// What saving fetched rates would do: the rates to [write], how many were
/// already stored as they are, and the days that disagree with the store.
final class FxWritePlan {
  const FxWritePlan({
    required this.write,
    required this.unchanged,
    required this.conflicts,
  });

  final List<FxRate> write;
  final int unchanged;
  final List<FxConflict> conflicts;
}

/// Plans saving [incoming] over [stored], both of one series. A stored rate is
/// never overwritten: a day that disagrees is a conflict, and any conflict
/// writes nothing for the series, so a revised publication is noticed instead
/// of mixed in.
FxWritePlan planFxWrite(
  ({String source, String base, String quote}) series,
  List<FxRate> stored,
  List<FxRate> incoming,
) {
  for (final rate in incoming) {
    if (rate.source != series.source ||
        rate.base != series.base ||
        rate.quote != series.quote) {
      throw ArgumentError(
        'Rate ${rate.source}:${rate.base}:${rate.quote} on ${rate.day} does '
        'not belong to ${series.source}:${series.base}:${series.quote}',
      );
    }
  }

  final byDay = {for (final rate in stored) rate.day: rate};
  final fresh = <String, FxRate>{};
  final conflicts = <FxConflict>[];
  var unchanged = 0;
  for (final rate in incoming) {
    final held = byDay[rate.day] ?? fresh[rate.day];
    if (held == null) {
      fresh[rate.day] = rate;
    } else if (held.rate.compareTo(rate.rate) == 0) {
      unchanged += 1;
    } else {
      conflicts.add((stored: held, incoming: rate));
    }
  }

  if (conflicts.isNotEmpty) {
    return FxWritePlan(
        write: const [], unchanged: unchanged, conflicts: conflicts);
  }
  final write = fresh.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  return FxWritePlan(write: write, unchanged: unchanged, conflicts: const []);
}
