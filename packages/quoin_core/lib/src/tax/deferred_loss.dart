import '../calendar/day.dart';
import '../decimal/dec.dart';
import '../domain/ledger.dart';
import '../money/money.dart';
import 'config.dart';
import 'fifo.dart';
import 'wash_sale.dart';

typedef DeferredLossPiece = ({String originEventId, Money amount});

final class DeferredLossShare {
  DeferredLossShare(this.buyEventId, this.acquiredAt, this.quantity);

  final String buyEventId;
  final DateTime acquiredAt;
  final Dec quantity;
  final List<DeferredLossPiece> pieces = [];
}

final class SaleDeferral {
  const SaleDeferral({
    required this.assessment,
    required this.notice,
    required this.ownNonComputable,
    required this.ownComputable,
    required this.integrated,
    required this.carriedOver,
    required this.shares,
  });

  final WashSaleAssessment? assessment;
  final UnlistedRepurchaseNotice? notice;
  final Money ownNonComputable;
  final Money ownComputable;
  final List<DeferredLossPiece> integrated;
  final List<DeferredLossPiece> carriedOver;
  final List<DeferredLossShare> shares;
}

typedef PendingDeferredLoss = ({
  String buyEventId,
  DateTime acquiredAt,
  List<DeferredLossPiece> pieces,
});

typedef DeferredLossWalk = ({
  Map<String, SaleDeferral> bySale,
  Map<int, List<PendingDeferredLoss>> pendingByYear,
});

final class _LotDeferral {
  _LotDeferral(this.acquiredAt);

  final DateTime acquiredAt;

  final pieces = <String, Money>{};
}

DeferredLossWalk walkDeferredLosses(
  List<FifoSale> sales,
  List<TradeEvent> trades,
  RepurchaseScope scope,
) {
  final assessor = WashSaleAssessor(trades, scope);
  final zone = scope.jurisdiction.zone;
  final lots = <String, _LotDeferral>{};
  final bySale = <String, SaleDeferral>{};
  final pendingByYear = <int, List<PendingDeferredLoss>>{};

  for (final (index, sale) in sales.indexed) {
    final carriedIn = _consume(sale, lots);
    final isLoss = sale.realizedPnL.isNegative;

    WashSaleAssessment? assessment;
    UnlistedRepurchaseNotice? notice;
    final rule = assessor.ruleFor(sale);
    if (rule == null) {
      notice = isLoss &&
              assessor.assetClassOf(sale.trade.instrumentId) ==
                  RepurchaseAssetClass.fungibleCrypto
          ? assessor.unlistedNotice(sale)
          : null;
    } else if (isLoss || carriedIn.isNotEmpty) {
      assessment = assessor.assess(sale, rule);
    }
    final fraction = assessment?.fraction ?? Dec.zero;

    final ownNonComputable = isLoss && !fraction.isZero
        ? sale.realizedPnL.scaleBy(fraction)
        : Money.zero;
    final carriedOver = [
      for (final p in carriedIn)
        (originEventId: p.originEventId, amount: p.amount.scaleBy(fraction)),
    ];
    final integrated = [
      for (final (i, p) in carriedIn.indexed)
        (
          originEventId: p.originEventId,
          amount: p.amount.subtract(carriedOver[i].amount),
        ),
    ];

    final outgoing = _nonZero([
      ...carriedOver,
      (originEventId: sale.trade.id, amount: ownNonComputable),
    ]);
    final shares = assessment != null && assessment.repurchased > Dec.zero
        ? _split(outgoing, assessment.recipients, assessment.repurchased)
        : <DeferredLossShare>[];
    for (final share in shares) {
      final lot = lots.putIfAbsent(
        share.buyEventId,
        () => _LotDeferral(share.acquiredAt),
      );
      for (final piece in share.pieces) {
        lot.pieces[piece.originEventId] =
            (lot.pieces[piece.originEventId] ?? Money.zero).add(piece.amount);
      }
    }

    bySale[sale.trade.id] = SaleDeferral(
      assessment: assessment,
      notice: notice,
      ownNonComputable: ownNonComputable,
      ownComputable: sale.realizedPnL.subtract(ownNonComputable),
      integrated: _nonZero(integrated),
      carriedOver: _nonZero(carriedOver),
      shares: shares,
    );

    final year = fiscalYearOf(sale.trade.ts, zone);
    if (index == sales.length - 1 ||
        fiscalYearOf(sales[index + 1].trade.ts, zone) != year) {
      pendingByYear[year] = _snapshot(lots);
    }
  }

  return (bySale: bySale, pendingByYear: pendingByYear);
}

List<DeferredLossPiece> _consume(
  FifoSale sale,
  Map<String, _LotDeferral> lots,
) {
  final taken = <String, Money>{};
  for (final consumption in sale.lots) {
    final lot = lots[consumption.lotId];
    if (lot == null) continue;
    var left = Dec.zero;
    for (final balance in sale.lotsAfter) {
      if (balance.lotId == consumption.lotId) {
        left = balance.quantity;
        break;
      }
    }
    final ratio = left.isZero
        ? Dec.one
        : consumption.quantity.dividedBy(consumption.quantity + left);

    for (final MapEntry(key: origin, value: amount)
        in lot.pieces.entries.toList()) {
      final moved = ratio == Dec.one ? amount : amount.scaleBy(ratio);
      taken[origin] = (taken[origin] ?? Money.zero).add(moved);
      lot.pieces[origin] = amount.subtract(moved);
    }
    if (left.isZero) lots.remove(consumption.lotId);
  }
  return _nonZero([
    for (final MapEntry(key: originEventId, value: amount) in taken.entries)
      (originEventId: originEventId, amount: amount),
  ]);
}

List<DeferredLossShare> _split(
  List<DeferredLossPiece> pieces,
  List<WashSaleRecipient> recipients,
  Dec total,
) {
  final shares = [
    for (final r in recipients)
      DeferredLossShare(r.buyEventId, r.acquiredAt, r.quantity),
  ];
  for (final piece in pieces) {
    var left = piece.amount;
    for (final (i, share) in shares.indexed) {
      final amount = i == shares.length - 1
          ? left
          : piece.amount.scaleBy(share.quantity.dividedBy(total));
      left = left.subtract(amount);
      share.pieces.add((originEventId: piece.originEventId, amount: amount));
    }
  }
  return shares;
}

List<PendingDeferredLoss> _snapshot(Map<String, _LotDeferral> lots) {
  final pending = <PendingDeferredLoss>[
    for (final MapEntry(key: buyEventId, value: lot) in lots.entries)
      if (_nonZero([
        for (final MapEntry(key: origin, value: amount) in lot.pieces.entries)
          (originEventId: origin, amount: amount),
      ])
          case final pieces when pieces.isNotEmpty)
        (buyEventId: buyEventId, acquiredAt: lot.acquiredAt, pieces: pieces),
  ];
  pending.sort((a, b) {
    final byTime = a.acquiredAt.compareTo(b.acquiredAt);
    return byTime != 0 ? byTime : compareCodeUnits(a.buyEventId, b.buyEventId);
  });
  return pending;
}

List<DeferredLossPiece> _nonZero(List<DeferredLossPiece> pieces) => [
      for (final p in pieces)
        if (!p.amount.isZero) p
    ];
