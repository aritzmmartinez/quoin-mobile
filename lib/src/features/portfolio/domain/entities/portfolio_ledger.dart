import 'package:quoin_core/quoin_core.dart';

/// Everything stored that the portfolio is computed from.
class PortfolioLedger {
  const PortfolioLedger({
    required this.residence,
    this.residenceChosen = false,
    required this.instruments,
    required this.events,
    required this.latestPrices,
    required this.rates,
  });

  final Residence residence;
  final bool residenceChosen;
  final List<Instrument> instruments;
  final List<LedgerEvent> events;
  final Map<String, PriceSnapshot> latestPrices;
  final List<FxRate> rates;
}
