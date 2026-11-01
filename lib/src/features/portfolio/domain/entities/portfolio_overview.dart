import 'package:quoin_core/quoin_core.dart';

/// An open position with what the screens show of it.
class Holding {
  const Holding({
    required this.instrumentId,
    required this.name,
    required this.category,
    required this.position,
    required this.value,
  });

  final String instrumentId;
  final String name;

  /// An [ExposureKind] code, or [otherCategory].
  final String category;
  final Position position;
  final MarketValue value;

  bool get isPriced => value.marketValue != null;

  /// Unrealized P&L over cost; null when unpriced or it cost nothing.
  Dec? get unrealizedPnLPct {
    final pnl = value.unrealizedPnL;
    if (pnl == null || position.costBasis.isZero) return null;
    return ratio(pnl, position.costBasis);
  }
}

/// The home and portfolio screens, computed at one instant.
class PortfolioOverview {
  const PortfolioOverview({
    required this.hasLedger,
    required this.summary,
    required this.holdings,
    required this.allocation,
    required this.top,
    required this.unrated,
    required this.unconvertible,
  });

  /// Whether anything was ever imported; false shows the empty state.
  final bool hasLedger;
  final PortfolioSummary summary;

  /// Every open position, priced or not, largest value first.
  final List<Holding> holdings;
  final List<AllocationSlice> allocation;

  /// The largest priced positions.
  final List<Holding> top;

  /// Names of the instruments left unvalued for want of a recent rate.
  final List<String> unrated;

  /// Names of the instruments left out because a trade has no rate.
  final List<String> unconvertible;
}
