import 'package:quoin_core/quoin_core.dart';

class KrakenTarget {
  const KrakenTarget({
    required this.instrumentId,
    required this.symbol,
    required this.origin,
  });

  final String instrumentId;
  final String? symbol;
  final SeriesOrigin origin;
}
