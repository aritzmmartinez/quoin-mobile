import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/holding_order.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class PortfolioPage extends ConsumerStatefulWidget {
  const PortfolioPage({super.key});

  @override
  ConsumerState<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends ConsumerState<PortfolioPage> {
  /// The category shown, or null for all of them.
  String? _category;
  var _order = HoldingOrder.value;
  var _sortOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PortfolioView(
      title: l10n.tabPortfolio,
      overview: ref.watch(portfolioOverviewProvider),
      empty: EmptyState(message: l10n.portfolioEmpty),
      builder: (overview) => QuoinPage.list(
        title: l10n.tabPortfolio,
        children: _content(context, overview),
      ),
    );
  }

  List<Widget> _content(BuildContext context, PortfolioOverview overview) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final summary = overview.summary;

    final categories = {for (final h in overview.holdings) h.category};
    final category = categories.contains(_category) ? _category : null;
    final shown = sortHoldings([
      for (final h in overview.holdings)
        if (category == null || h.category == category) h,
    ], _order);

    final orders = {
      HoldingOrder.value: l10n.portfolioSortValue,
      HoldingOrder.gain: l10n.portfolioSortGain,
      HoldingOrder.name: l10n.portfolioSortName,
    };

    return [
      DisplayFigure(format.money(summary.totalValue)),
      const SizedBox(height: 6),
      Text(
        l10n.portfolioSummary(
          summary.pricedCount + summary.unpricedCount,
          format.money(summary.openCost),
        ),
        style: type.secondary.copyWith(color: c.muted),
      ),
      ...valuationNotices(context, overview),
      const SizedBox(height: QuoinSpace.section),
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  QuoinChip.text(
                    label: l10n.portfolioFilterAll,
                    selected: category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final key in categories)
                    QuoinChip.text(
                      label: categoryLabel(l10n, key),
                      selected: key == category,
                      onTap: () => setState(() => _category = key),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<HoldingOrder>(
            tooltip: l10n.portfolioSort,
            initialValue: _order,
            onOpened: () => setState(() => _sortOpen = true),
            onCanceled: () => setState(() => _sortOpen = false),
            onSelected: (order) => setState(() {
              _order = order;
              _sortOpen = false;
            }),
            itemBuilder: (context) => [
              for (final MapEntry(:key, :value) in orders.entries)
                CheckedPopupMenuItem(
                  value: key,
                  checked: key == _order,
                  child: Text(value),
                ),
            ],
            child: _SortButton(open: _sortOpen),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (shown.isEmpty)
        Text(
          l10n.portfolioNoneInCategory,
          style: type.secondary.copyWith(color: c.muted),
        )
      else
        holdingsCard(
          context,
          shown,
          detail: (h) => format.quantity(h.position.quantity),
        ),
      const SizedBox(height: QuoinSpace.section),
    ];
  }
}

/// The sort control, drawn as a control: an outlined circle near the chips'
/// height, tinted with the accent while its menu is open. The touch target
/// around it is the minimum 48.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return SizedBox.square(
      dimension: kMinInteractiveDimension,
      child: Center(
        child: SizedBox.square(
          dimension: 36,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: open ? c.accent.withValues(alpha: 0.15) : c.surface,
              shape: CircleBorder(
                side: BorderSide(color: open ? c.accent : c.border),
              ),
            ),
            child: Center(
              child: QuoinIcon(
                QuoinIcons.sort,
                size: 18,
                color: open ? c.accent : c.body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
