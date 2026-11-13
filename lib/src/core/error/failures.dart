sealed class Failure {
  const Failure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnsupportedResidenceFailure extends Failure {
  const UnsupportedResidenceFailure(this.residence);

  final String residence;
}

sealed class ImportFailure extends Failure {
  const ImportFailure();
}

final class UnreadableFileFailure extends ImportFailure {
  const UnreadableFileFailure();
}

final class InvalidEncodingFailure extends ImportFailure {
  const InvalidEncodingFailure();
}

final class UnparseableCsvFailure extends ImportFailure {
  const UnparseableCsvFailure();
}

final class UnknownBrokerFailure extends ImportFailure {
  const UnknownBrokerFailure();
}

final class MissingColumnFailure extends ImportFailure {
  const MissingColumnFailure(this.column);

  final String column;
}

final class RowRejectedFailure extends ImportFailure {
  const RowRejectedFailure({
    this.externalId,
    this.position,
    required this.reason,
  });

  final String? externalId;
  final int? position;
  final String reason;
}

final class KrakenLegacyExportFailure extends ImportFailure {
  const KrakenLegacyExportFailure();
}

final class KrakenBalanceMismatchFailure extends ImportFailure {
  const KrakenBalanceMismatchFailure({
    required this.asset,
    required this.wallet,
    required this.date,
  });

  final String asset;
  final String wallet;

  final String date;
}

final class InvalidLedgerEventFailure extends ImportFailure {
  const InvalidLedgerEventFailure({
    required this.day,
    required this.type,
    required this.currency,
  });

  final String day;
  final String type;
  final String currency;
}

/// What can stop pairing with the PC or syncing with it.
sealed class SyncFailure extends Failure {
  const SyncFailure();
}

/// No PC is paired.
final class NotPairedFailure extends SyncFailure {
  const NotPairedFailure();
}

/// The PC could not be reached at its address: «No encuentro tu Quoin».
final class PcUnreachableFailure extends SyncFailure {
  const PcUnreachableFailure();
}

/// The PC showed another certificate: only a new pairing trusts it.
final class CertificateMismatchFailure extends SyncFailure {
  const CertificateMismatchFailure();
}

/// The PC no longer accepts this phone (revoked, or a token it does not
/// know): pair again.
final class PairingRevokedFailure extends SyncFailure {
  const PairingRevokedFailure();
}

/// A code that is not a Quoin pairing QR.
final class InvalidQrFailure extends SyncFailure {
  const InvalidQrFailure();
}

/// The QR's token was used already, or no pairing is under way on the PC.
final class PairingTokenUsedFailure extends SyncFailure {
  const PairingTokenUsedFailure();
}

/// The pairing ran out of time on the PC.
final class PairingExpiredFailure extends SyncFailure {
  const PairingExpiredFailure();
}

/// The owner rejected the pairing on the PC.
final class PairingRejectedFailure extends SyncFailure {
  const PairingRejectedFailure();
}

enum UpdateSide { app, quoin }

/// The two sides read no common exchange version: [side] must be updated.
final class UpdateRequiredFailure extends SyncFailure {
  const UpdateRequiredFailure(this.side);

  final UpdateSide side;
}

/// The PC is busy (another write, or too many failed attempts) for longer
/// than is worth waiting.
final class PcBusyFailure extends SyncFailure {
  const PcBusyFailure();
}

/// The PC changed during the sync twice in a row.
final class StateChangedFailure extends SyncFailure {
  const StateChangedFailure();
}

/// The database could not claim this install's device id, so it may be a
/// copy signing as the original: the sync stops.
final class DeviceIdentityFailure extends SyncFailure {
  const DeviceIdentityFailure();
}

/// The phone holds the invented sample portfolio, which never syncs.
final class SampleDataFailure extends SyncFailure {
  const SampleDataFailure();
}

/// The conflicts changed since they were resolved: show them again.
final class ConflictsChangedFailure extends SyncFailure {
  const ConflictsChangedFailure();
}

/// This PC has the same sync identity as [otherPcName], another paired PC:
/// a database restored from one onto the other. Syncing with both would let
/// their values diverge silently, so only the other one syncs.
final class SharedIdentityFailure extends SyncFailure {
  const SharedIdentityFailure(this.otherPcName);

  final String otherPcName;
}

/// The PC refused the request for a reason the phone cannot act on; [code]
/// is its error code.
final class PcRefusedFailure extends SyncFailure {
  const PcRefusedFailure(this.code);

  final String code;
}
