import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/instrument_detail.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/get_portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/movements_of.dart';

InstrumentDetail? instrumentDetailOf(
  PortfolioLedger ledger,
  String id,
  DateTime now,
) {
  final instrument = ledger.instruments.where((i) => i.id == id).firstOrNull;
  if (instrument == null) return null;
  final jurisdiction = jurisdictionOf(ledger.residence);
  final buys = [
    for (final e in ledger.events)
      if (e is TradeEvent && e.instrumentId == id && e.type == TradeType.buy)
        e.ts,
  ];

  return InstrumentDetail(
    instrument: instrument,
    zone: jurisdiction.zone,
    position: computePositions(
      ledger.events,
      jurisdiction,
    ).where((p) => p.instrumentId == id).firstOrNull,
    value: overviewOf(ledger, now).holdings
        .where((h) => h.instrumentId == id && h.isPriced)
        .firstOrNull
        ?.value,
    firstBuy: buys.isEmpty
        ? null
        : buys.reduce((a, b) => a.isBefore(b) ? a : b),
    sales: computeRealizedGains(
      ledger.events,
      jurisdiction,
    ).where((s) => s.instrumentId == id).toList().reversed.toList(),
    movements: [
      for (final m in movementsOf(ledger))
        if (m.instrumentId == id) m,
    ],
  );
}
