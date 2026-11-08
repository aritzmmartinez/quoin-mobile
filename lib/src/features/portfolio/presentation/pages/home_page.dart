import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/presentation/providers/tax_providers.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/allocation_donut.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/figure_block.dart';
import 'package:quoin/src/ui/molecules/gain_badge.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PortfolioView(
      title: l10n.tabHome,
      overview: ref.watch(portfolioOverviewProvider),
      onRefresh: () => refreshFromPc(context, ref),
      empty: EmptyState(
        message: l10n.homeEmpty,
        actionLabel: l10n.importCsv,
        onAction: () => context.push(Routes.import),
      ),
      builder: (overview) => QuoinPage.list(
        title: l10n.tabHome,
        onRefresh: () => refreshFromPc(context, ref),
        children: _content(context, overview, switch (ref
            .watch(realizedReportProvider)
            .value) {
          Ok(:final value) => value,
          _ => null,
        }),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    PortfolioOverview overview,
    RealizedReport? report,
  ) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final summary = overview.summary;
    final gain = format.signedMoney(summary.unrealizedPnL);
    final returnPct = summary.returnPct;

    return [
      Text(l10n.homeTotal, style: type.secondary.copyWith(color: c.muted)),
      const SizedBox(height: 6),
      if (summary.pricedCount == 0)
        Text(l10n.homeNoPriced, style: type.row.copyWith(color: c.muted))
      else ...[
        DisplayFigure(format.money(summary.totalValue)),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GainBadge(
            text: returnPct == null
                ? gain.text
                : '${gain.text} (${format.percent(returnPct, signed: true)})',
            sign: gain.sign,
          ),
        ),
      ],
      if (summary.unpricedCount > 0) ...[
        const SizedBox(height: 10),
        Text(
          l10n.homeUnpriced(
            summary.unpricedCount,
            format.money(summary.unpricedCost),
          ),
          style: type.secondary.copyWith(color: c.muted),
        ),
      ],
      ...valuationNotices(context, overview),
      if (report != null && report.sales.isNotEmpty) ...[
        const SizedBox(height: QuoinSpace.section),
        _RealizedCard(report: report),
      ],
      if (overview.allocation.isNotEmpty) ...[
        sectionLabel(context, l10n.homeAllocation),
        QuoinCard(
          child: AllocationDonut(
            slices: [
              for (final slice in overview.allocation)
                DonutSlice(
                  label: categoryLabel(l10n, slice.category),
                  fraction: slice.weight.toDouble(),
                  percent: format.percent(slice.weight),
                ),
            ],
          ),
        ),
      ],
      if (overview.top.isNotEmpty) ...[
        sectionLabel(
          context,
          l10n.homePositions,
          action: TextButton(
            onPressed: () => context.go(Routes.portfolio),
            child: Text(l10n.homeSeeAll),
          ),
        ),
        holdingsCard(
          context,
          overview.top,
          detail: (h) => format.percent(h.value.weight!),
        ),
      ],
      const SizedBox(height: QuoinSpace.section),
    ];
  }
}

class _RealizedCard extends StatelessWidget {
  const _RealizedCard({required this.report});

  final RealizedReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final year = report.sales
        .map((s) => s.year)
        .reduce((a, b) => a > b ? a : b);
    final totals = SalesTotals([
      for (final s in report.sales)
        if (s.year == year) s,
    ]);
    final realized = format.signedMoney(totals.realized);
    return QuoinCard(
      onTap: () => context.push(Routes.realized),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: FigureBlock(
              label: l10n.homeRealized(year),
              value: realized.text,
              sign: realized.sign,
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
