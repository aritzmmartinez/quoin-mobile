import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show FxRateRow, InstrumentRow, LedgerEntryRow, PriceSnapshotRow;
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';

class UnreadableRow implements Exception {
  const UnreadableRow(this.message);

  final String message;

  @override
  String toString() => 'UnreadableRow: $message';
}

extension PortfolioRowsModel on PortfolioRows {
  PortfolioLedger toEntity() {
    final latest = <String, PriceSnapshot>{};
    for (final row in prices) {
      latest[row.instrumentId] = row.toEntity();
    }
    return PortfolioLedger(
      residence:
          Residence.values.asNameMap()[settings.residence] ??
          (throw UnsupportedResidenceException(settings.residence)),
      instruments: [for (final row in instruments) row.toEntity()],
      events: [for (final row in entries) row.toEntity()],
      latestPrices: latest,
      rates: [for (final row in rates) row.toEntity()],
    );
  }
}

extension InstrumentRowModel on InstrumentRow {
  Instrument toEntity() => Instrument(
    id: id,
    name: name,
    type: type,
    assetClass: assetClass,
    exposureKind: exposureKind == null ? null : ExposureKind.of(exposureKind!),
  );
}

extension PriceSnapshotRowModel on PriceSnapshotRow {
  PriceSnapshot toEntity() => PriceSnapshot(
    instrumentId: instrumentId,
    price: Money.parse(price),
    currency: currency,
    asOf: asOf.toUtc(),
    source: source,
  );
}

extension FxRateRowModel on FxRateRow {
  FxRate toEntity() => FxRate(
    source: source,
    base: base,
    quote: quote,
    day: day,
    rate: Dec.parse(rate),
  );
}

extension LedgerEntryRowModel on LedgerEntryRow {
  LedgerEvent toEntity() {
    String need(String? value, String field) =>
        value ?? (throw UnreadableRow('$type $id has no $field'));
    final at = ts.toUtc();
    final source = FxSource.of(fxSource);
    final rate = fxRate == null ? null : Dec.parse(fxRate!);
    final direction = fxDirection == null ? null : FxDirection.of(fxDirection!);
    return switch (type) {
      'BUY' || 'SELL' => TradeEvent(
        id: id,
        ts: at,
        type: TradeType.of(type),
        instrumentId: need(instrumentId, 'instrumentId'),
        quantity: Dec.parse(need(quantity, 'quantity')),
        price: Money.parse(need(price, 'price')),
        grossAmount: Money.parse(grossAmount),
        fees: Money.parse(fees),
        currency: currency,
        funding: Funding.of(funding),
        fxSource: source,
        fxDate: fxDate,
        fxRate: rate,
        fxDirection: direction,
        linkId: linkId,
        linkKind: linkKind,
        account: account,
        source: this.source,
        externalId: externalId,
      ),
      'DIVIDEND' => DividendEvent(
        id: id,
        ts: at,
        instrumentId: need(instrumentId, 'instrumentId'),
        grossAmount: Money.parse(grossAmount),
        taxWithheld: Money.parse(taxWithheld),
        currency: currency,
        funding: Funding.of(funding),
        fxSource: source,
        fxDate: fxDate,
        fxRate: rate,
        fxDirection: direction,
        account: account,
        source: this.source,
        externalId: externalId,
      ),
      _ => CashEvent(
        id: id,
        ts: at,
        type: CashType.of(type),
        grossAmount: Money.parse(grossAmount),
        currency: currency,
        fxSource: source,
        fxDate: fxDate,
        fxRate: rate,
        fxDirection: direction,
        account: account,
        source: this.source,
        externalId: externalId,
      ),
    };
  }
}
