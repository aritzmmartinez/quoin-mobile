import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin_core/quoin_core.dart';

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
import 'package:quoin/src/features/portfolio/presentation/widgets/category_sheet.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:quoin/src/features/settings/presentation/widgets/kraken_prices_sheet.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/atoms/quoin_pill_button.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
import 'package:quoin/src/ui/molecules/notice_row.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/molecules/stat_columns.dart';
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
      onRefresh: () => refreshPrices(context, ref),
      empty: EmptyState(
        icon: QuoinIcons.portfolio,
        title: l10n.emptyPortfolioTitle,
        body: l10n.emptyPortfolioBody,
        actionLabel: l10n.importCsv,
        onAction: () => context.push(Routes.import),
      ),
      builder: (overview) => QuoinPage.list(
        title: l10n.tabPortfolio,
        onRefresh: () => refreshPrices(context, ref),
        trailing: QuoinType.largeText(context)
            ? IconButton(
                icon: const QuoinIcon(QuoinIcons.movements),
                tooltip: l10n.movementsTitle,
                onPressed: () => context.push(Routes.movements),
              )
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: QuoinSpace.m),
                child: QuoinPillButton(
                  icon: QuoinIcons.movements,
                  label: l10n.movementsTitle,
                  onTap: () => context.push(Routes.movements),
                ),
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

    final result = summary.returnPct;
    final resultSign = summary.unrealizedPnL.amount.sign;
    String detail(Holding h) => quantityText(l10n, format, h);

    return [
      StatColumns(
        stats: [
          (
            label: l10n.portfolioValue,
            value: format.money(summary.totalValue),
            sign: 0,
          ),
          (
            label: l10n.portfolioCost,
            value: format.money(summary.totalInvested),
            sign: 0,
          ),
          (
            label: l10n.portfolioResult,
            value: format.percent(result ?? Dec.zero, signed: true),
            sign: result == null ? 0 : resultSign,
          ),
        ],
      ),
      ...unconvertibleNote(context, overview),
      if (!ref.watch(krakenPricesProvider) &&
          overview.holdings.any((h) => h.type == 'CRYPTO' && !h.isPriced)) ...[
        const SizedBox(height: QuoinSpace.gutter),
        NoticeRow(
          text: l10n.krakenInvite,
          action: l10n.krakenTurnOn,
          onTap: () => openKrakenPrices(context, ref),
        ),
      ],
      const SizedBox(height: QuoinSpace.gutter),
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
      if (shown.isEmpty) ...[
        const SizedBox(height: QuoinSpace.m),
        Text(
          l10n.portfolioNoneInCategory,
          style: type.secondary.copyWith(color: c.muted),
        ),
      ] else ...[
        const SizedBox(height: QuoinSpace.s),
        PositionList(
          children: [
            if (category != null)
              for (final h in shown) holdingRow(context, h, detail: detail(h))
            else
              for (final group in groupByCategory(
                shown,
                overview.allocation,
              )) ...[
                GroupHeader(
                  label: categoryLabel(l10n, group.category),
                  total: switch (group.value) {
                    final value? => format.money(value),
                    null => null,
                  },
                  action: group.category == otherCategory
                      ? TextButton(
                          onPressed: () => classifyInstruments(context, [
                            for (final h in group.holdings)
                              Instrument(
                                id: h.instrumentId,
                                name: h.name,
                                type: h.type,
                              ),
                          ]),
                          child: Text(l10n.categoryClassify),
                        )
                      : null,
                ),
                for (final h in group.holdings)
                  holdingRow(context, h, detail: detail(h)),
              ],
          ],
        ),
      ],
    ];
  }
}
