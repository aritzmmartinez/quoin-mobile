import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';

String syncFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NotPairedFailure() => l10n.syncFailNotPaired,
      PcUnreachableFailure() => l10n.syncUnreachable,
      CertificateMismatchFailure() => l10n.syncCertificateChanged,
      PairingRevokedFailure() => l10n.syncRevoked,
      InvalidQrFailure() => l10n.syncFailInvalidQr,
      PairingTokenUsedFailure() => l10n.syncFailTokenUsed,
      PairingExpiredFailure() => l10n.syncFailExpired,
      PairingRejectedFailure() => l10n.syncFailRejected,
      UpdateRequiredFailure(side: UpdateSide.app) => l10n.syncFailUpdateApp,
      UpdateRequiredFailure(side: UpdateSide.quoin) => l10n.syncFailUpdateQuoin,
      PcBusyFailure() => l10n.syncFailBusy,
      StateChangedFailure() => l10n.syncFailStateChanged,
      DeviceIdentityFailure() => l10n.syncFailDeviceIdentity,
      SampleDataFailure() => l10n.syncFailSample,
      ConflictsChangedFailure() => l10n.syncFailConflictsChanged,
      PcRefusedFailure(:final code) => l10n.syncFailRefused(code),
      UnsupportedResidenceFailure() => l10n.residenceUnsupported,
      StorageFailure() => l10n.syncFailStorage,
      NetworkFailure() || ImportFailure() => l10n.syncFailNetwork,
    };

String syncFailureDetail(AppLocalizations l10n, Failure failure) {
  final help = switch (failure) {
    PcUnreachableFailure() => l10n.syncUnreachableHint,
    CertificateMismatchFailure() => l10n.syncCertificateHint,
    PairingRevokedFailure() => l10n.syncRevokedHint,
    _ => null,
  };
  final title = syncFailureText(l10n, failure);
  return help == null ? title : '$title\n\n$help';
}

bool needsPairing(Failure failure) => switch (failure) {
  PcUnreachableFailure() ||
  CertificateMismatchFailure() ||
  PairingRevokedFailure() ||
  NotPairedFailure() => true,
  _ => false,
};
