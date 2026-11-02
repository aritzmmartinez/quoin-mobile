import '../calendar/day.dart';
import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../domain/residence.dart';
import '../money/money.dart';
import 'config.dart';
import 'deferred_loss.dart';
import 'fifo.dart';
import 'wash_sale.dart';

final class WashSaleRecipientDetail {
  const WashSaleRecipientDetail({
    required this.buyEventId,
    required this.acquiredAt,
    required this.quantity,
    required this.deferredLoss,
  });

  final String buyEventId;
  final DateTime acquiredAt;
  final Dec quantity;
  final Money deferredLoss;
}

final class WashSaleDetail {
  const WashSaleDetail({required this.assessment, required this.recipients});

  final WashSaleAssessment assessment;
  final List<WashSaleRecipientDetail> recipients;

  RepurchaseLetter get letter => assessment.rule.letter;
  int get windowMonths => assessment.rule.windowMonths;
}

final class RealizedGainDetail {
  const RealizedGainDetail({
    required this.sale,
    required this.computablePnL,
    required this.nonComputable,
    required this.carriedOver,
    required this.washSale,
    required this.repurchaseWindow,
    required this.unlistedNotice,
  });

  final FifoSale sale;
  final Money computablePnL;
  final Money nonComputable;
  final Money carriedOver;
  final WashSaleDetail? washSale;
  final ({RepurchaseLetter letter, WashSaleWindow window})? repurchaseWindow;
  final UnlistedRepurchaseNotice? unlistedNotice;

  String get eventId => sale.trade.id;
  DateTime get ts => sale.trade.ts;
  String get instrumentId => sale.trade.instrumentId;
  Money get realizedPnL => sale.realizedPnL;
}

final class DeferredLossIntegration {
  const DeferredLossIntegration({
    required this.originEventId,
    required this.originTs,
    required this.integratedByEventId,
    required this.ts,
    required this.instrumentId,
    required this.amount,
  });

  final String originEventId;
  final DateTime originTs;
  final String integratedByEventId;
  final DateTime ts;
  final String instrumentId;
  final Money amount;
}

final class PendingDeferredLossDetail {
  const PendingDeferredLossDetail({
    required this.buyEventId,
    required this.acquiredAt,
    required this.instrumentId,
    required this.pieces,
  });

  final String buyEventId;
  final DateTime acquiredAt;
  final String instrumentId;
  final List<DeferredLossPiece> pieces;

  Money get amount =>
      pieces.fold(Money.zero, (sum, piece) => sum.add(piece.amount));
}

final class TaxHistory {
  const TaxHistory({
    required this.jurisdiction,
    required this.gains,
    required this.integrations,
    required this.pendingByYear,
  });

  final Jurisdiction jurisdiction;
  final List<RealizedGainDetail> gains;
  final List<DeferredLossIntegration> integrations;
  final Map<int, List<PendingDeferredLossDetail>> pendingByYear;
}

final class TaxYearResult {
  const TaxYearResult({
    required this.year,
    required this.territory,
    required this.gains,
    required this.integrations,
    required this.pending,
    required this.computableNet,
  });

  final int year;
  final Territory territory;
  final List<RealizedGainDetail> gains;
  final List<DeferredLossIntegration> integrations;
  final List<PendingDeferredLossDetail> pending;
  final Dec computableNet;
}

TaxHistory computeTaxHistory(List<LedgerEvent> events, RepurchaseScope scope) {
  final sales = walkFifo(events, scope.jurisdiction);
  final trades = sortTrades(events);
  final tradesById = {for (final t in trades) t.id: t};
  final deferrals = walkDeferredLosses(sales, trades, scope);

  final gains = <RealizedGainDetail>[];
  final integrations = <DeferredLossIntegration>[];
  for (final sale in sales) {
    final deferral = deferrals.bySale[sale.trade.id]!;
    final assessment = deferral.assessment;
    gains.add(RealizedGainDetail(
      sale: sale,
      computablePnL: deferral.ownComputable,
      nonComputable: deferral.ownNonComputable,
      carriedOver: _total(deferral.carriedOver),
      washSale: assessment != null && assessment.repurchased > Dec.zero
          ? _washSaleDetail(assessment, deferral.shares)
          : null,
      repurchaseWindow: assessment == null
          ? null
          : (letter: assessment.rule.letter, window: assessment.window),
      unlistedNotice: deferral.notice,
    ));
    for (final piece in deferral.integrated) {
      integrations.add(DeferredLossIntegration(
        originEventId: piece.originEventId,
        originTs: tradesById[piece.originEventId]?.ts ?? sale.trade.ts,
        integratedByEventId: sale.trade.id,
        ts: sale.trade.ts,
        instrumentId: sale.trade.instrumentId,
        amount: piece.amount,
      ));
    }
  }

  return TaxHistory(
    jurisdiction: scope.jurisdiction,
    gains: gains,
    integrations: integrations,
    pendingByYear: {
      for (final MapEntry(key: year, value: pending)
          in deferrals.pendingByYear.entries)
        year: [
          for (final p in pending)
            PendingDeferredLossDetail(
              buyEventId: p.buyEventId,
              acquiredAt: p.acquiredAt,
              instrumentId: tradesById[p.buyEventId]?.instrumentId ?? '',
              pieces: p.pieces,
            ),
        ],
    },
  );
}

TaxYearResult taxYearOf(TaxHistory history, int year) {
  final zone = history.jurisdiction.zone;
  final gains = [
    for (final g in history.gains)
      if (fiscalYearOf(g.ts, zone) == year) g,
  ];
  final integrations = [
    for (final i in history.integrations)
      if (fiscalYearOf(i.ts, zone) == year) i,
  ];
  final recorded = [
    for (final y in history.pendingByYear.keys)
      if (y <= year) y,
  ];
  return TaxYearResult(
    year: year,
    territory: history.jurisdiction.territory,
    gains: gains,
    integrations: integrations,
    pending: recorded.isEmpty
        ? const []
        : history.pendingByYear[recorded.reduce((a, b) => a > b ? a : b)]!,
    computableNet: sumDec([
      for (final g in gains) g.computablePnL.amount,
      for (final i in integrations) i.amount.amount,
    ]),
  );
}

WashSaleDetail _washSaleDetail(
  WashSaleAssessment assessment,
  List<DeferredLossShare> shares,
) {
  final deferredByBuy = {
    for (final s in shares) s.buyEventId: _total(s.pieces),
  };
  return WashSaleDetail(
    assessment: assessment,
    recipients: [
      for (final r in assessment.recipients)
        WashSaleRecipientDetail(
          buyEventId: r.buyEventId,
          acquiredAt: r.acquiredAt,
          quantity: r.quantity,
          deferredLoss: deferredByBuy[r.buyEventId] ?? Money.zero,
        ),
    ],
  );
}

Money _total(List<DeferredLossPiece> pieces) =>
    pieces.fold(Money.zero, (sum, p) => sum.add(p.amount));

typedef CarryforwardStep = ({
  int year,
  Dec ownNet,
  Dec consumedFromCarryforward,
  Dec finalNet,
  Dec pendingLossRemaining,
});

typedef CarryforwardResult = ({
  int targetYear,
  List<CarryforwardStep> steps,
  Dec netSavingsBase,
});

CarryforwardResult carryforwardFrom(TaxHistory history, int year) {
  final pending = <({int year, Dec remaining})>[];
  final steps = <CarryforwardStep>[];

  for (var y = year - lossCarryforwardYears; y <= year; y++) {
    final ownNet = taxYearOf(history, y).computableNet;
    var consumed = Dec.zero;
    var finalNet = ownNet;

    if (ownNet.isNegative) {
      pending.add((year: y, remaining: ownNet.abs()));
    } else if (ownNet.isPositive) {
      var remaining = ownNet;
      for (final (i, loss) in pending.indexed) {
        if (remaining <= Dec.zero) break;
        if (loss.remaining <= Dec.zero) continue;
        final applied = minDec(loss.remaining, remaining);
        pending[i] = (year: loss.year, remaining: loss.remaining - applied);
        remaining = remaining - applied;
        consumed = consumed + applied;
      }
      finalNet = ownNet - consumed;
    }

    steps.add((
      year: y,
      ownNet: ownNet,
      consumedFromCarryforward: consumed,
      finalNet: finalNet,
      pendingLossRemaining: sumDec(pending.map((loss) => loss.remaining)),
    ));
  }

  return (targetYear: year, steps: steps, netSavingsBase: steps.last.finalNet);
}
