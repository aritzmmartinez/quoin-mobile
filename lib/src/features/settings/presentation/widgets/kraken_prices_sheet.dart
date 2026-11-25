import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';
import 'package:quoin/src/ui/organisms/quoin_toast.dart';

Future<void> openKrakenPrices(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final on = ref.read(krakenPricesProvider);
  final chosen = await showQuoinSheet<bool>(
    context,
    title: l10n.krakenSheetTitle,
    subtitle: l10n.krakenAttribution,
    body: (sheet) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: QuoinSpace.card,
        children: [
          Text(
            l10n.krakenSheetBody,
            style: QuoinType.of(sheet).secondary
                .copyWith(color: QuoinColors.of(sheet).body),
          ),
          QuoinCard(
            padding: EdgeInsets.zero,
            child: SettingsRow(
              icon: on ? QuoinIcons.clearData : QuoinIcons.crypto,
              label: on ? l10n.krakenTurnOff : l10n.krakenTurnOn,
              subtitle: on ? l10n.krakenTurnOffDetail : null,
              onTap: () => Navigator.of(sheet).pop(!on),
            ),
          ),
        ],
      ),
    ),
  );
  if (chosen == null) return;
  final result = await ref.read(krakenPricesProvider.notifier).set(chosen);
  if (result is Err<void> && context.mounted) {
    showQuoinToast(
      context,
      tone: QuoinToastTone.negative,
      title: l10n.settingsSaveFailed,
    );
  }
}
