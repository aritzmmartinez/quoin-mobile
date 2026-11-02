import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tools = <(QuoinIconData, String, String, VoidCallback?)>[
      (
        QuoinIcons.realized,
        l10n.realizedTitle,
        l10n.realizedHint,
        () => context.push(Routes.realized),
      ),
      (
        QuoinIcons.projection,
        l10n.toolProjection,
        l10n.toolProjectionHint,
        null,
      ),
      (
        QuoinIcons.opportunityCost,
        l10n.toolOpportunityCost,
        l10n.toolOpportunityCostHint,
        null,
      ),
      (QuoinIcons.ter, l10n.toolTer, l10n.toolTerHint, null),
      (QuoinIcons.rebalance, l10n.toolRebalance, l10n.toolRebalanceHint, null),
    ];
    return QuoinPage.list(
      title: l10n.tabAnalysis,
      children: [
        for (final (i, (icon, title, hint, onTap)) in tools.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _ToolCard(icon: icon, title: title, hint: hint, onTap: onTap),
        ],
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.hint,
    this.onTap,
  });

  final QuoinIconData icon;
  final String title;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = QuoinType.of(context);
    return QuoinCard(
      onTap: onTap,
      child: Row(
        spacing: 14,
        children: [
          IconTile(icon: icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  title,
                  style: type.row.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  hint,
                  style: type.secondary.copyWith(
                    color: QuoinColors.of(context).muted,
                  ),
                ),
              ],
            ),
          ),
          QuoinIcon(
            QuoinIcons.chevronRight,
            size: 16,
            color: QuoinColors.of(context).faint,
          ),
        ],
      ),
    );
  }
}
