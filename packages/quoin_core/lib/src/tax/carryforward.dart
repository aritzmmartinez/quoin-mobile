import '../decimal/dec.dart';
import 'config.dart';
import 'tax_lots.dart';
import 'territory.dart';

typedef CarryforwardStep = ({
  int year,
  Dec ownNet,
  Dec consumedFromCarryforward,
  Dec finalNet,
  Dec pendingLossRemaining,
});

typedef CarryforwardResult = ({
  int targetYear,
  List<CarryforwardStep> steps,
  Dec netSavingsBase,
});

/// A year's step in one pool. [crossOffset] is what the other pool moved into
/// it: positive absorbs a loss, negative gives up a gain.
typedef PoolStep = ({
  int year,
  Dec ownNet,
  Dec crossOffset,
  Dec consumedFromCarryforward,
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

  /// One year: the cross offset applies first, then a positive remainder
  /// consumes pending losses oldest first, and a negative one becomes a
  /// pending loss of that year.
  void settle(int year, Dec ownNet, Dec cross) {
    final afterCross = ownNet + cross;
    var consumed = Dec.zero;

    if (afterCross.isNegative) {
      pending.add((year: year, remaining: afterCross.abs()));
    } else if (afterCross.isPositive) {
      var remaining = afterCross;
      for (final (i, loss) in pending.indexed) {
        if (remaining <= Dec.zero) break;
        if (loss.remaining <= Dec.zero) continue;
        final applied = minDec(loss.remaining, remaining);
        pending[i] = (year: loss.year, remaining: loss.remaining - applied);
        remaining = remaining - applied;
        consumed = consumed + applied;
      }
    }

    steps.add((
      year: year,
      ownNet: ownNet,
      crossOffset: cross,
      consumedFromCarryforward: consumed,
      finalNet: afterCross - consumed,
      pendingLossRemaining: sumDec(pending.map((loss) => loss.remaining)),
    ));
  }
}

/// A year's negative balance in one pool offsets the other's positive balance
/// of that same year, up to [limit] of it. Only same-year balances cross:
/// régimen común also crosses pending losses from earlier years, which comes
/// with that territory.
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
PoolResult carryforwardPool(NetOf netOf, int year, int years) {
  final pool = _Pool();
  for (var y = year - years; y <= year; y++) {
    pool.settle(y, netOf(y), Dec.zero);
  }
  return pool.result;
}

/// Two pools advancing year by year together, because what one absorbs from
/// the other in a year is no longer a loss it carries. The savings base is
/// the sum of their positive final balances.
PoolsResult carryforwardPools(
  (NetOf, NetOf) netsOf,
  int year,
  int years,
  String crossOffsetLimit,
) {
  final limit = Dec.parse(crossOffsetLimit);
  final a = _Pool();
  final b = _Pool();
  for (var y = year - years; y <= year; y++) {
    final netA = netsOf.$1(y);
    final netB = netsOf.$2(y);
    final (crossA, crossB) = _crossOffsets(netA, netB, limit);
    a.settle(y, netA, crossA);
    b.settle(y, netB, crossB);
  }
  return (
    targetYear: year,
    pools: (a.result, b.result),
    savingsBase: maxDec(a.result.finalNet, Dec.zero) +
        maxDec(b.result.finalNet, Dec.zero),
  );
}

/// The capital-gains pool alone. A year's own net is its computable net: the
/// deferred losses that compute in it are already inside, so a year that ends
/// negative because of one starts that loss's window in that year, not in the
/// year of the sale that deferred it.
CarryforwardResult carryforwardFrom(TaxHistory history, int year) {
  final (:steps, :finalNet) = carryforwardPool(
    gainsNetOf(history),
    year,
    territoryRules(history.jurisdiction.territory).lossCarryforwardYears,
  );
  return (
    targetYear: year,
    steps: [
      for (final s in steps)
        (
          year: s.year,
          ownNet: s.ownNet,
          consumedFromCarryforward: s.consumedFromCarryforward,
          finalNet: s.finalNet,
          pendingLossRemaining: s.pendingLossRemaining,
        ),
    ],
    netSavingsBase: finalNet,
  );
}

NetOf gainsNetOf(TaxHistory history) =>
    (y) => taxYearOf(history, y).computableNet;
