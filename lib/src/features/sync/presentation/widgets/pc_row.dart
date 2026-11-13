import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';

SettingsRow pcRow(
  BuildContext context, {
  required Pairing pairing,
  required String? twin,
  required bool running,
  required Failure? failure,
  required VoidCallback onTap,
}) {
  final l10n = AppLocalizations.of(context);
  final shown = pairing.shared ? SharedIdentityFailure(twin ?? '') : failure;
  return SettingsRow(
    icon: switch (shown) {
      null => QuoinIcons.computer,
      PcUnreachableFailure() => QuoinIcons.offline,
      CertificateMismatchFailure() ||
      PairingRevokedFailure() => QuoinIcons.certificate,
      _ => QuoinIcons.alert,
    },
    label: pairing.pcName,
    value: switch (shown) {
      final failure? => syncFailureText(l10n, failure),
      null when running => l10n.syncRunning(pairing.pcName),
      null => _lastSync(context, pairing),
    },
    onTap: onTap,
  );
}

String _lastSync(BuildContext context, Pairing pairing) {
  final l10n = AppLocalizations.of(context);
  final at = pairing.lastSyncAt;
  if (at == null) return l10n.syncNever;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return l10n.syncLastSync(
    DateFormat.yMMMd(locale).add_Hm().format(at.toLocal()),
  );
}
