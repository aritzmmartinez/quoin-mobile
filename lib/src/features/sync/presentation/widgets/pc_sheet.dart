import 'package:flutter/material.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_detail_view.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';

Future<void> showPcSheet(
  BuildContext context, {
  required Pairing pc,
  required Failure? failure,
  required LastSync? last,
  required VoidCallback onCheckAgain,
  required VoidCallback onSearch,
  required VoidCallback onRescan,
  required VoidCallback onPairAgain,
  required VoidCallback onUnpair,
}) async {
  final l10n = AppLocalizations.of(context);
  final chosen = await showModalBottomSheet<VoidCallback>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheet) {
      SettingsRow action(QuoinIconData icon, String label, VoidCallback run) =>
          SettingsRow(
            icon: icon,
            label: label,
            onTap: () => Navigator.of(sheet).pop(run),
          );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(pc.pcName, style: QuoinType.of(sheet).title),
              if (failure != null)
                Text(
                  syncFailureDetail(l10n, failure),
                  style: QuoinType.of(sheet).secondary,
                ),
              if (last != null) ...[
                sectionLabel(sheet, l10n.syncDetailLast),
                ...syncDetailSections(
                  sheet,
                  toPhone: last.toPhone,
                  toPc: last.toPc,
                ),
              ],
              if (pc.shared)
                action(QuoinIcons.sync, l10n.syncCheckAgain, onCheckAgain),
              if (failure != null && searchable(failure))
                action(QuoinIcons.search, l10n.syncSearch, onSearch),
              if (failure
                  case PcUnreachableFailure() || PcNotFoundOnNetworkFailure())
                action(QuoinIcons.offline, l10n.syncRescan, onRescan),
              if (failure
                  case CertificateMismatchFailure() || PairingRevokedFailure())
                action(QuoinIcons.certificate, l10n.syncPairAgain, onPairAgain),
              action(QuoinIcons.unpair, l10n.syncUnpair, onUnpair),
            ],
          ),
        ),
      );
    },
  );
  chosen?.call();
}
