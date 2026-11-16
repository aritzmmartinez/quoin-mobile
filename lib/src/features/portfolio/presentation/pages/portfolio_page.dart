import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
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
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/organisms/quoin_dropdown.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PortfolioView(
      title: l10n.tabPortfolio,
      overview: ref.watch(portfolioOverviewProvider),
      onRefresh: () => refreshFromPc(context, ref),
      empty: EmptyState(
        icon: QuoinIcons.portfolio,
        title: l10n.emptyPortfolioTitle,
        body: l10n.emptyPortfolioBody,
        actionLabel: l10n.importCsv,
        onAction: () => context.push(Routes.import),
      ),
      builder: (overview) => QuoinPage.list(
        title: l10n.tabPortfolio,
        onRefresh: () => refreshFromPc(context, ref),
        trailing: IconButton(
          icon: const QuoinIcon(QuoinIcons.movements),
          tooltip: l10n.movementsTitle,
          onPressed: () => context.push(Routes.movements),
        ),
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
      const SizedBox(height: QuoinSpace.tight),
      Text(
        l10n.portfolioSummary(
          summary.pricedCount + summary.unpricedCount,
          format.money(summary.openCost),
        ),
        style: type.secondary.copyWith(color: c.muted),
      ),
      ...valuationNotices(context, overview),
      const SizedBox(height: QuoinSpace.section),
      Wrap(
        spacing: QuoinSpace.s,
        children: [
          QuoinDropdown<String?>(
            label: l10n.portfolioFilterCategory,
            value: category,
            options: [
              (value: null, label: l10n.portfolioFilterAllCategories),
              for (final key in categories)
                (value: key, label: categoryLabel(l10n, key)),
            ],
            onChanged: (key) => setState(() => _category = key),
          ),
          QuoinDropdown<HoldingOrder>(
            label: l10n.portfolioSort,
            value: _order,
            options: [
              for (final MapEntry(:key, :value) in orders.entries)
                (value: key, label: value),
            ],
            onChanged: (order) => setState(() => _order = order),
          ),
        ],
      ),
      const SizedBox(height: QuoinSpace.m),
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
