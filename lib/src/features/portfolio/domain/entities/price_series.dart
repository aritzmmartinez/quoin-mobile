import 'package:quoin_core/quoin_core.dart';

enum PriceSource { kraken, pc }

class PriceSeries {
  const PriceSeries({required this.history, required this.source});

  final List<PriceSnapshot> history;
  final PriceSource source;
}
