import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../money/money.dart';
import 'avco.dart';

final class Position {
  const Position({
    required this.instrumentId,
    required this.quantity,
    required this.costBasis,
    required this.averageCost,
    required this.realizedPnL,
  });

  final String instrumentId;
  final Dec quantity;
  final Money costBasis;
  final Money averageCost;
  final Money realizedPnL;

  bool get isOpen => !quantity.isZero;
}

/// Current positions by weighted-average cost (AVCO), one per instrument, in
/// the order of each instrument's first trade. The arithmetic is [walkAvco];
/// FIFO tax lots are a separate projection.
List<Position> computePositions(
  List<LedgerEvent> events,
  Jurisdiction jurisdiction,
) =>
    [
      for (final lot in walkAvco(events, jurisdiction).lots.values)
        Position(
          instrumentId: lot.instrumentId,
          quantity: lot.quantity,
          costBasis: lot.costBasis,
          averageCost: lot.averageCost,
          realizedPnL: lot.realizedPnL,
        ),
    ];
