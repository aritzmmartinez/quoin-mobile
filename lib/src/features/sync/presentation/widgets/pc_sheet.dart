import 'package:flutter/material.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_detail_view.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_section_label.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

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
  final chosen = await showQuoinSheet<VoidCallback>(
    context,
    title: pc.pcName,
    body: (sheet) {
      SettingsRow action(QuoinIconData icon, String label, VoidCallback run) =>
          SettingsRow(
            icon: icon,
            label: label,
            onTap: () => Navigator.of(sheet).pop(run),
          );
      final actions = [
        if (pc.shared)
          action(QuoinIcons.sync, l10n.syncCheckAgain, onCheckAgain),
        if (failure != null && searchable(failure))
          action(QuoinIcons.search, l10n.syncSearch, onSearch),
        if (failure case PcUnreachableFailure() || PcNotFoundOnNetworkFailure())
          action(QuoinIcons.offline, l10n.syncRescan, onRescan),
        if (failure
            case CertificateMismatchFailure() || PairingRevokedFailure())
          action(QuoinIcons.certificate, l10n.syncPairAgain, onPairAgain),
        action(QuoinIcons.unpair, l10n.syncUnpair, onUnpair),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null) ...[
              Text(
                syncFailureDetail(l10n, failure),
                style: QuoinType.of(sheet).secondary
                    .copyWith(color: QuoinColors.of(sheet).body),
              ),
              const SizedBox(height: QuoinSpace.card),
            ],
            QuoinCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, row) in actions.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    row,
                  ],
                ],
              ),
            ),
            if (last != null) ...[
              QuoinSectionLabel(l10n.syncDetailLast),
              ...syncDetailSections(
                sheet,
                toPhone: last.toPhone,
                toPc: last.toPc,
              ),
            ],
          ],
        ),
      );
    },
  );
  chosen?.call();
}
