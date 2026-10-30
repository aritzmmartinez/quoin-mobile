import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

const topPositions = 5;

class GetPortfolioOverview {
  const GetPortfolioOverview(this._repository);

  final PortfolioRepository _repository;

  Future<Result<PortfolioOverview>> call(DateTime now) async =>
      switch (await _repository.load()) {
        Ok(:final value) => Ok(overviewOf(value, now)),
        Err(:final failure) => Err(failure),
      };
}

/// The web's home chain (routes/summary.tsx), at [now].
PortfolioOverview overviewOf(PortfolioLedger ledger, DateTime now) {
  final jurisdiction = jurisdictionOf(ledger.residence);
  final positions = computePositions(ledger.events, jurisdiction);
  final valued = pricesInBase(
    ledger.latestPrices,
    rateBookFrom(ledger.rates),
    now,
    jurisdiction.zone,
  );
  final marketValues = computeMarketValues(positions, valued.prices);

  final instruments = {for (final i in ledger.instruments) i.id: i};
  String nameOf(String id) => instruments[id]?.name ?? id;
  final categories = {
    for (final i in ledger.instruments)
      if (i.exposureKind case final kind?) i.id: kind.code,
  };

  final holdings = sortHoldings([
    for (final p in positions)
      if (p.isOpen)
        Holding(
          instrumentId: p.instrumentId,
          name: nameOf(p.instrumentId),
          category: categories[p.instrumentId] ?? otherCategory,
          position: p,
          value: marketValues[p.instrumentId]!,
        ),
  ], HoldingOrder.value);
  final byId = {for (final h in holdings) h.instrumentId: h};
  final open = holdings.map((h) => h.instrumentId).toSet();

  return PortfolioOverview(
    hasLedger: ledger.events.isNotEmpty,
    summary: computePortfolioSummary(positions, marketValues),
    holdings: holdings,
    allocation: computeAllocation(positions, marketValues, categories),
    top: [
      for (final row in computeTopPositions(
        positions,
        marketValues,
        topPositions,
      ))
        byId[row.instrumentId]!,
    ],
    unrated: [
      for (final id in valued.unrated.keys)
        if (open.contains(id)) nameOf(id),
    ]..sort(compareNamesEs),
    unconvertible: [
      for (final id in unconvertibleInstrumentIds(ledger.events)) nameOf(id),
    ]..sort(compareNamesEs),
  );
}
