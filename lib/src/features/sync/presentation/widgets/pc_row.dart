import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_detail_view.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';

SettingsRow pcRow(
  BuildContext context, {
  required Pairing pairing,
  required String? twin,
  required bool running,
  required bool searching,
  required Failure? failure,
  required LastSync? last,
  required VoidCallback onTap,
}) {
  final l10n = AppLocalizations.of(context);
  final shown = pairing.shared ? SharedIdentityFailure(twin ?? '') : failure;
  if (searching && !pairing.shared) {
    return SettingsRow(
      icon: QuoinIcons.search,
      label: pairing.pcName,
      value: l10n.syncSearching,
      onTap: onTap,
    );
  }
  return SettingsRow(
    icon: switch (shown) {
      null => QuoinIcons.computer,
      PcUnreachableFailure() ||
      PcNotFoundOnNetworkFailure() ||
      NoLocalNetworkFailure() ||
      LocalNetworkDeniedFailure() => QuoinIcons.offline,
      CertificateMismatchFailure() ||
      PairingRevokedFailure() => QuoinIcons.certificate,
      _ => QuoinIcons.alert,
    },
    label: pairing.pcName,
    value: switch (shown) {
      final failure? => syncFailureText(l10n, failure),
      null when running => l10n.syncRunning(pairing.pcName),
      null => switch (last) {
        final last? when pairing.lastSyncAt != null => [
          _lastSync(context, pairing),
          syncDetailSummary(l10n, last),
        ].join(' · '),
        _ => _lastSync(context, pairing),
      },
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
