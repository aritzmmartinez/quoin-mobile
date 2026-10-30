import 'package:flutter/material.dart';

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
    final tools = [
      (QuoinIcons.projection, l10n.toolProjection, l10n.toolProjectionHint),
      (
        QuoinIcons.opportunityCost,
        l10n.toolOpportunityCost,
        l10n.toolOpportunityCostHint,
      ),
      (QuoinIcons.ter, l10n.toolTer, l10n.toolTerHint),
      (QuoinIcons.rebalance, l10n.toolRebalance, l10n.toolRebalanceHint),
    ];
    return QuoinPage.list(
      title: l10n.tabAnalysis,
      children: [
        for (final (i, (icon, title, hint)) in tools.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _ToolCard(icon: icon, title: title, hint: hint),
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
  });

  final QuoinIconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final type = QuoinType.of(context);
    return QuoinCard(
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
