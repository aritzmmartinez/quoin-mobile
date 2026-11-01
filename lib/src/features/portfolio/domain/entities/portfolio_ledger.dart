import 'package:quoin_core/quoin_core.dart';

/// Everything stored that the portfolio is computed from.
class PortfolioLedger {
  const PortfolioLedger({
    required this.residence,
    required this.instruments,
    required this.events,
    required this.latestPrices,
    required this.rates,
  });

  final Residence residence;
  final List<Instrument> instruments;
  final List<LedgerEvent> events;

  /// The newest price of each instrument, in its own currency.
  final Map<String, PriceSnapshot> latestPrices;
  final List<FxRate> rates;
}
