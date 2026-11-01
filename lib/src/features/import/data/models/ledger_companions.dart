import 'package:drift/drift.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/import/domain/usecases/commit_import.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show InstrumentCompanion, LedgerEntryCompanion;

/// The instrument fields an import writes. The manual ones (quote symbol,
/// exposure, TER, hedging, thesis) are left as they are, as Quoin's
/// `InstrumentWriteData`.
extension InstrumentWrite on Instrument {
  InstrumentCompanion toInsert(DateTime createdAt) =>
      InstrumentCompanion.insert(
        id: id,
        name: name,
        type: type,
        assetClass: Value(assetClass),
        createdAt: createdAt,
      );

  InstrumentCompanion toUpdate() => InstrumentCompanion(
    name: Value(name),
    type: Value(type),
    assetClass: Value(assetClass),
  );
}

/// A ledger row as Quoin's `eventToCreateData` writes it: the original amount
/// and currency default to the gross amount and currency.
extension LedgerEventWrite on LedgerEvent {
  LedgerEntryCompanion toInsert(DateTime createdAt) {
    final (gross, extra) = switch (this) {
      TradeEvent e => (
        e.grossAmount,
        LedgerEntryCompanion(
          instrumentId: Value(e.instrumentId),
          quantity: Value('${e.quantity}'),
          price: Value('${e.price.amount}'),
          fees: Value('${e.fees.amount}'),
          funding: Value(e.funding.code),
        ),
      ),
      DividendEvent e => (
        e.grossAmount,
        LedgerEntryCompanion(
          instrumentId: Value(e.instrumentId),
          taxWithheld: Value('${e.taxWithheld.amount}'),
          funding: Value(e.funding.code),
        ),
      ),
      CashEvent e => (e.grossAmount, const LedgerEntryCompanion()),
    };
    return extra.copyWith(
      id: Value(id),
      ts: Value(ts.toUtc()),
      type: Value(typeCodeOf(this)),
      grossAmount: Value('${gross.amount}'),
      currency: Value(currency),
      fxSource: Value(fxSource.code),
      fxDate: Value(fxDate),
      fxRate: Value(fxRate?.toString()),
      fxDirection: Value(fxDirection?.code),
      originalAmount: Value('${(originalAmount ?? gross).amount}'),
      originalCurrency: Value(originalCurrency ?? currency),
      valuationSource: Value(valuationSource),
      linkId: Value(linkId),
      linkKind: Value(linkKind),
      account: Value(account),
      source: Value(source),
      externalId: Value(externalId),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }
}
