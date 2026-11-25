import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/instrument_chart.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/entities/price_series.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

class LoadPriceSeries {
  const LoadPriceSeries(this._repository);

  final PortfolioRepository _repository;

  Future<Result<PriceSeries?>> call(String instrumentId) =>
      _repository.priceSeries(instrumentId);
}

InstrumentChart? instrumentChartOf(
  PortfolioLedger ledger,
  PriceSeries series,
  DateTime now,
) {
  final zone = jurisdictionOf(ledger.residence).zone;
  final (:history, :unrated) = historyInBase(
    series.history,
    rateBookFrom(ledger.rates),
    zone,
  );
  final points = dailyCloses(history, zone);
  if (points.length < 2) return null;
  return InstrumentChart(
    points: points,
    source: series.source,
    today: today(zone, now),
    unrated: unrated,
  );
}
