import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin_core/quoin_core.dart';

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
import 'package:quoin/src/features/portfolio/presentation/widgets/valuation_sheet.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_stamp.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/presentation/providers/tax_providers.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_section_label.dart';
import 'package:quoin/src/ui/molecules/allocation_bar.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/notice_row.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/molecules/stat_tile.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PortfolioView(
      title: l10n.tabHome,
      overview: ref.watch(portfolioOverviewProvider),
      onRefresh: () => refreshPrices(context, ref),
      empty: EmptyState(
        icon: QuoinIcons.portfolio,
        title: l10n.emptyPortfolioTitle,
        body: l10n.emptyPortfolioBody,
        actionLabel: l10n.importCsv,
        onAction: () => context.push(Routes.import),
      ),
      builder: (overview) => QuoinPage.list(
        title: l10n.tabHome,
        trailing: const SyncStamp(),
        onRefresh: () => refreshPrices(context, ref),
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
    final gain = format.gainLine(summary.unrealizedPnL, summary.returnPct);
    final notice = valuationNotice(l10n, overview);
    final year = report?.defaultYear;

    return [
      Text(l10n.homeTotal, style: type.secondary.copyWith(color: c.muted)),
      const SizedBox(height: QuoinSpace.xs),
      if (summary.pricedCount == 0)
        Text(l10n.homeNoPriced, style: type.row.copyWith(color: c.muted))
      else ...[
        DisplayFigure(format.money(summary.totalValue)),
        const SizedBox(height: QuoinSpace.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: gain.text,
                style: type.row.mono.copyWith(
                  color: switch (gain.sign) {
                    > 0 => c.positive,
                    < 0 => c.negative,
                    _ => c.text,
                  },
                ),
              ),
              TextSpan(text: ' ${l10n.homeSinceStart}'),
            ],
          ),
          style: type.row.copyWith(color: c.muted, fontWeight: FontWeight.w400),
        ),
      ],
      if (notice != null) ...[
        const SizedBox(height: QuoinSpace.gutter),
        NoticeRow(
          text: notice,
          action: l10n.noticeReview,
          onTap: () => showValuationSheet(context, overview.issues),
        ),
      ],
      if (report != null && year != null) ..._yearTiles(context, report, year),
      if (overview.allocation.isNotEmpty) ...[
        QuoinSectionLabel.heading(l10n.homeAllocation),
        AllocationBar(segments: _segments(l10n, format, overview)),
      ],
      if (overview.top.isNotEmpty) ...[
        QuoinSectionLabel.heading(
          l10n.homePositions,
          padding: const EdgeInsets.only(top: QuoinSpace.block),
          action: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: c.muted,
              textStyle: type.secondary,
            ),
            onPressed: () => context.go(Routes.portfolio),
            child: Text(l10n.homeSeeAll),
          ),
        ),
        PositionList(
          children: [
            for (final h in overview.top)
              holdingRow(
                context,
                h,
                detail: l10n.homeWeight(
                  format.percent(
                    h.value.weight!,
                    decimals: 0,
                    floorNonZero: true,
                  ),
                ),
                compact: true,
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _yearTiles(
    BuildContext context,
    RealizedReport report,
    int year,
  ) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final realized = format.signedMoney(
      SalesTotals([
        for (final s in report.sales)
          if (s.year == year) s,
      ]).realized,
    );
    final quota = report.taxYear(year).quota;
    final tiles = [
      StatTile(
        label: l10n.homeRealized(year),
        value: realized.text,
        sign: realized.sign,
        onTap: () => context.push(Routes.realized),
      ),
      if (quota != null)
        StatTile(
          label: l10n.homeTaxEstimate(year),
          value: format.money(quota),
          onTap: () => context.push(Routes.realizedTax),
        ),
    ];
    return [
      const SizedBox(height: QuoinSpace.m),
      if (QuoinType.largeText(context))
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: QuoinSpace.row,
          children: tiles,
        )
      else
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: QuoinSpace.row,
            children: [
              for (final tile in tiles) Expanded(child: tile),
              if (tiles.length == 1) const Spacer(),
            ],
          ),
        ),
    ];
  }

  List<AllocationSegment> _segments(
    AppLocalizations l10n,
    QuoinFormat format,
    PortfolioOverview overview,
  ) {
    AllocationSegment segment(AllocationSlice slice) => AllocationSegment(
      label: categoryLabel(l10n, slice.category),
      fraction: slice.weight.toDouble(),
      percent: format.percent(slice.weight, decimals: 0, floorNonZero: true),
      unclassified: slice.category == otherCategory,
    );
    return [
      for (final slice in overview.allocation)
        if (slice.category != otherCategory) segment(slice),
      for (final slice in overview.allocation)
        if (slice.category == otherCategory) segment(slice),
    ];
  }
}
