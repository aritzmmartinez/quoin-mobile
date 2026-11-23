import '../decimal/dec.dart';
import 'config.dart';
import 'tax_lots.dart';

/// A year's step in one pool. [crossOffset] is what the other pool's balance
/// of the year moved into it: positive absorbs a loss, negative gives up a
/// gain. [absorbedFromOther] is the other pool's pending losses that this
/// pool's positive balance took; [crossedToOther] is this pool's pending
/// losses that the other took.
typedef PoolStep = ({
  int year,
  Dec ownNet,
  Dec crossOffset,
  Dec consumedFromCarryforward,
  Dec absorbedFromOther,
  Dec crossedToOther,
  Dec finalNet,
  Dec pendingLossRemaining,
});

typedef PoolResult = ({List<PoolStep> steps, Dec finalNet});

typedef PoolsResult = ({
  int targetYear,
  (PoolResult, PoolResult) pools,
  Dec savingsBase,
});

typedef NetOf = Dec Function(int year);

final class _Pool {
  final pending = <({int year, Dec remaining})>[];
  final steps = <PoolStep>[];

  PoolResult get result => (steps: steps, finalNet: steps.last.finalNet);

  Dec get pendingSum => sumDec(pending.map((loss) => loss.remaining));

  /// Takes up to [amount] of the pending losses, oldest year first, and
  /// returns what it took.
  Dec consumePending(Dec amount) {
    var consumed = Dec.zero;
    for (final (i, loss) in pending.indexed) {
      final left = amount - consumed;
      if (left <= Dec.zero) break;
      final applied = minDec(loss.remaining, left);
      pending[i] = (year: loss.year, remaining: loss.remaining - applied);
      consumed = consumed + applied;
    }
    return consumed;
  }
}

/// A year's negative balance in one pool offsets the other's positive balance
/// of that same year, up to [limit] of it.
(Dec, Dec) _crossOffsets(Dec a, Dec b, Dec limit) {
  if (a.isNegative && b.isPositive) {
    final x = minDec(a.abs(), b * limit);
    return (x, -x);
  }
  if (b.isNegative && a.isPositive) {
    final x = minDec(b.abs(), a * limit);
    return (-x, x);
  }
  return (Dec.zero, Dec.zero);
}

/// Nothing here is stored. Every call recomputes year - years..year, and that
/// window is what makes a pending loss expire: it can offset any year up to
/// [years] after the one it originated in.
PoolResult carryforwardPool(NetOf netOf, int year, int years) =>
    carryforwardPools((netOf, (_) => Dec.zero), year, years, '0').pools.$1;

/// Two pools advancing year by year together, because what one absorbs from
/// the other is no longer a loss it carries. Each year:
///
/// 1. A pool's negative balance offsets the other's positive one, up to
///    [crossOffsetLimit] of that positive balance.
/// 2. Each positive remainder consumes its own pool's pending losses, oldest
///    first, without limit.
/// 3. Pending losses still left in one pool offset what remains positive in
///    the other, oldest first, up to what the limit has left after step 1:
///    the limit is one per year and receiving pool, over its own positive
///    balance.
///
/// Only earlier years' losses are pending in step 3; the year's own negative
/// balance joins them after it. The savings base is the sum of the positive
/// final balances.
PoolsResult carryforwardPools(
  (NetOf, NetOf) netsOf,
  int year,
  int years,
  String crossOffsetLimit,
) {
  final limit = Dec.parse(crossOffsetLimit);
  final pair = [_Pool(), _Pool()];
  for (var y = year - years; y <= year; y++) {
    final own = [netsOf.$1(y), netsOf.$2(y)];
    final (crossA, crossB) = _crossOffsets(own[0], own[1], limit);
    final cross = [crossA, crossB];
    final after = [for (var i = 0; i < 2; i++) own[i] + cross[i]];
    final consumed = [
      for (var i = 0; i < 2; i++)
        after[i].isPositive ? pair[i].consumePending(after[i]) : Dec.zero,
    ];
    final absorbed = [
      for (var i = 0; i < 2; i++)
        () {
          final room =
              limit * maxDec(own[i], Dec.zero) - maxDec(cross[1 - i], Dec.zero);
          final rest = after[i] - consumed[i];
          return rest.isPositive && room.isPositive
              ? pair[1 - i].consumePending(minDec(rest, room))
              : Dec.zero;
        }(),
    ];

    for (var i = 0; i < 2; i++) {
      final pool = pair[i];
      final finalNet = after[i] - consumed[i] - absorbed[i];
      if (finalNet.isNegative) {
        pool.pending.add((year: y, remaining: finalNet.abs()));
      }
      pool.steps.add((
        year: y,
        ownNet: own[i],
        crossOffset: cross[i],
        consumedFromCarryforward: consumed[i],
        absorbedFromOther: absorbed[i],
        crossedToOther: absorbed[1 - i],
        finalNet: finalNet,
        pendingLossRemaining: pool.pendingSum,
      ));
    }
  }
  final (a, b) = (pair[0].result, pair[1].result);
  return (
    targetYear: year,
    pools: (a, b),
    savingsBase: maxDec(a.finalNet, Dec.zero) + maxDec(b.finalNet, Dec.zero),
  );
}

/// The capital-gains pool's net of a year is its computable net: the deferred
/// losses that compute in it are already inside, so a year that ends negative
/// because of one starts that loss's window in that year, not in the year of
/// the sale that deferred it.
NetOf gainsNetOf(TaxHistory history) =>
    (y) => taxYearOf(history, y).computableNet;
