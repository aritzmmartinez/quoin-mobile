import 'package:drift/drift.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show InstrumentCompanion, LedgerEntryCompanion;

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
/// and currency default to the gross amount and currency, and every amount
/// keeps the text it was read from ([Dec.text]).
extension LedgerEventWrite on LedgerEvent {
  LedgerEntryCompanion toInsert(DateTime createdAt) {
    final (gross, extra) = switch (this) {
      TradeEvent e => (
        e.grossAmount,
        LedgerEntryCompanion(
          instrumentId: Value(e.instrumentId),
          quantity: Value(e.quantity.text),
          price: Value(e.price.text),
          fees: Value(e.fees.text),
          funding: Value(e.funding.code),
        ),
      ),
      DividendEvent e => (
        e.grossAmount,
        LedgerEntryCompanion(
          instrumentId: Value(e.instrumentId),
          taxWithheld: Value(e.taxWithheld.text),
          funding: Value(e.funding.code),
        ),
      ),
      CashEvent e => (e.grossAmount, const LedgerEntryCompanion()),
    };
    return extra.copyWith(
      id: Value(id),
      ts: Value(ts.toUtc()),
      type: Value(ledgerTypeOf(this)),
      grossAmount: Value(gross.text),
      currency: Value(currency),
      fxSource: Value(fxSource.code),
      fxDate: Value(fxDate),
      fxRate: Value(fxRate?.text),
      fxDirection: Value(fxDirection?.code),
      originalAmount: Value((originalAmount ?? gross).text),
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
