import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show
        EtfHoldingBlockRow,
        EtfHoldingRow,
        InstrumentRow,
        LedgerEntryRow,
        PortfolioTargetLineRow,
        PortfolioTargetRow,
        SecurityIdentityRow,
        SettingsRow,
        SyncPeerRow,
        SyncTombstoneRow;

/// Stored rows as the exchange carries them: every text as stored, never
/// reformatted, and every instant as UTC ISO-8601 with milliseconds, as
/// Quoin's `toISOString()` writes it.
extension LedgerEntryRecord on LedgerEntryRow {
  /// The original amount and currency go out as Quoin stores them: when a row
  /// has none, Quoin's insert writes the gross amount and currency, so a row
  /// sent without them would differ from its copy there and be set aside as a
  /// conflict on every sync after.
  LedgerRecord toRecord() => LedgerRecord(
    source: source,
    externalId: externalId ?? '',
    ts: isoInstant(ts),
    type: type,
    instrumentId: instrumentId,
    quantity: quantity,
    price: price,
    grossAmount: grossAmount,
    fees: fees,
    taxWithheld: taxWithheld,
    currency: currency,
    fxSource: fxSource,
    fxDate: fxDate,
    fxRate: fxRate,
    fxDirection: fxDirection,
    originalAmount: originalAmount ?? grossAmount,
    originalCurrency: originalCurrency ?? currency,
    valuationSource: valuationSource,
    linkId: linkId,
    linkKind: linkKind,
    funding: funding,
    account: account,
    note: note,
  );
}

extension InstrumentRecordRow on InstrumentRow {
  InstrumentRecord toRecord() => InstrumentRecord(
    id: id,
    name: name,
    type: type,
    assetClass: assetClass,
    quoteSymbol: quoteSymbol,
    quoteSymbolHlc: quoteSymbolHlc,
    exposureKind: exposureKind,
    exposureLeafId: exposureLeafId,
    exposureHlc: exposureHlc,
    ter: ter,
    terHlc: terHlc,
    hedgedToBase: hedgedToBase,
    hedgedToBaseHlc: hedgedToBaseHlc,
    thesis: thesis,
    thesisHlc: thesisHlc,
  );
}

extension TargetRecordRow on PortfolioTargetRow {
  /// [lines] must be this version's, ordered by instrument.
  TargetRecord toRecord(List<PortfolioTargetLineRow> lines) => TargetRecord(
    id: id,
    name: name,
    activeFrom: activeFrom ?? '',
    note: note,
    createdAt: isoInstant(createdAt),
    lines: [
      for (final line in lines)
        TargetLine(
          instrumentId: line.instrumentId,
          monthlyAmount: line.monthlyAmount,
        ),
    ],
  );
}

extension TombstoneRecordRow on SyncTombstoneRow {
  Tombstone toRecord() => Tombstone(key: key, hlc: hlc);
}

extension HoldingsBlockRecordRow on EtfHoldingBlockRow {
  /// [rows] must be this fund's, ordered by identity.
  HoldingsBlock toRecord(List<EtfHoldingRow> rows) => HoldingsBlock(
    instrumentId: instrumentId,
    asOf: asOf,
    asOfInferred: asOfInferred,
    hlc: hlc,
    rows: [
      for (final row in rows)
        HoldingLine(
          identity: row.identity,
          identityKind: row.identityKind,
          name: row.name,
          weight: row.weight,
        ),
    ],
  );
}

extension IdentityRecordRow on SecurityIdentityRow {
  IdentityRecord toRecord() => IdentityRecord(
    identity: identity,
    identityKind: identityKind,
    canonicalId: canonicalId,
    exchCode: exchCode,
    status: status,
    source: source,
    resolvedAt: isoInstant(resolvedAt),
  );
}

extension SettingsRecordRow on SettingsRow {
  SettingsRecord toRecord() =>
      SettingsRecord(residence: residence, residenceHlc: residenceHlc);
}

extension PeerRecordRow on SyncPeerRow {
  Peer toRecord() => Peer(deviceId: deviceId, seen: seen);
}
