import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';

class InstrumentDetail {
  const InstrumentDetail({
    required this.instrument,
    required this.zone,
    required this.position,
    required this.value,
    required this.firstBuy,
    required this.sales,
    required this.movements,
  });

  final Instrument instrument;
  final String zone;
  final Position? position;
  final MarketValue? value;
  final DateTime? firstBuy;
  final List<RealizedSale> sales;
  final List<Movement> movements;
}
