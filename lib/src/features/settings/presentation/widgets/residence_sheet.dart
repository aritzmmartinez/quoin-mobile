import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/residence_name.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

/// The residence picked, or null when the sheet is closed without one.
/// [current] is the stored text, which may be one this version does not know.
Future<Residence?> showResidenceSheet(BuildContext context, String current) {
  final l10n = AppLocalizations.of(context);
  return showQuoinSheet<Residence>(
    context,
    title: l10n.settingsResidence,
    body: (sheet) {
      final c = QuoinColors.of(sheet);
      final type = QuoinType.of(sheet);
      Widget note(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(
          QuoinSpace.gutter,
          QuoinSpace.m,
          QuoinSpace.gutter,
          0,
        ),
        child: Text(text, style: type.secondary.copyWith(color: c.muted)),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final residence in Residence.values)
            QuoinChoiceRow(
              label: residenceName(l10n, residence.name),
              detail: switch (residence) {
                Residence.bizkaia => l10n.residenceBizkaiaDetail,
                Residence.comun => l10n.residenceComunDetail,
                Residence.canarias => l10n.residenceCanariasDetail,
              },
              selected: residence.name == current,
              onTap: () => Navigator.of(sheet).pop(residence),
            ),
          note(l10n.settingsResidenceHelp),
          note(l10n.settingsResidenceCeutaMelilla),
        ],
      );
    },
  );
}
