import 'package:quoin_core/src/sync/exchange.dart';

/// What every invented id carries: the instruments and ledger keys of the
/// debug sample portfolio and of the debug sample import. Nothing a broker
/// issues contains it (an ISIN's country code is two letters, a crypto code
/// is the asset's).
const sampleMarker = 'QSAMPLE';

/// Whether [state] holds invented data. A sync refuses such a state whole:
/// filtering it out would leave references to what was filtered.
bool containsSample(SyncState state) =>
    state.instruments.any((i) => i.id.contains(sampleMarker)) ||
    state.ledger.any(
      (r) =>
          r.externalId.contains(sampleMarker) ||
          (r.instrumentId?.contains(sampleMarker) ?? false),
    );
