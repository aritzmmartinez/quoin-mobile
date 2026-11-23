import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/presentation/providers/tax_providers.dart';
import 'package:quoin/src/features/tax/presentation/widgets/tax_year_panel.dart';
import 'package:quoin/src/features/tax/presentation/widgets/territory_names.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/info_row.dart';
import 'package:quoin/src/ui/organisms/explain_sheet.dart';
import 'package:quoin/src/ui/organisms/quoin_segmented_pages.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class RealizedPage extends ConsumerStatefulWidget {
  const RealizedPage({super.key, this.tax = false});

  final bool tax;

  @override
  ConsumerState<RealizedPage> createState() => _RealizedPageState();
}

class _RealizedPageState extends ConsumerState<RealizedPage> {
  var _order = SaleOrder.date;
  int? _taxYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultView(
      title: l10n.realizedTitle,
      value: ref.watch(realizedReportProvider),
      builder: (report) => report.hasLedger
          ? QuoinPage(
              title: l10n.realizedTitle,
              body: QuoinSegmentedPages(
                initialIndex: widget.tax ? 1 : 0,
                segments: [
                  (0, l10n.realizedTabSales),
                  (
                    1,
                    l10n.realizedTabTax(
                      taxResidenceName(l10n, report.residence),
                    ),
                  ),
                ],
                pages: [_sales(context, report), _tax(context, report)],
              ),
            )
          : QuoinPage(
              title: l10n.realizedTitle,
              body: EmptyState(
                icon: QuoinIcons.realized,
                title: l10n.emptySalesTitle,
                body: l10n.realizedEmpty,
              ),
            ),
    );
  }

  List<Widget> _sales(BuildContext context, RealizedReport report) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    if (report.sales.isEmpty) {
      return [
        Text(
          l10n.realizedEmpty,
          style: type.secondary.copyWith(color: c.muted),
        ),
      ];
    }
    final years = {for (final s in report.sales) s.year}.toList()
      ..sort((a, b) => b.compareTo(a));
    final orders = {
      SaleOrder.date: l10n.realizedSortDate,
      SaleOrder.result: l10n.realizedSortResult,
      SaleOrder.name: l10n.realizedSortName,
    };

    return [
      InfoRow(
        label: l10n.realizedHow,
        onTap: () => showExplainSheet(
          context,
          title: l10n.realizedHow,
          points: [
            (
              icon: QuoinIcons.averageCost,
              title: l10n.avcoCostTitle,
              body: l10n.avcoCostBody,
              source: null,
            ),
            (
              icon: QuoinIcons.fees,
              title: l10n.avcoFeesTitle,
              body: l10n.avcoFeesBody,
              source: null,
            ),
            (
              icon: QuoinIcons.taxRule,
              title: l10n.avcoNotTaxTitle,
              body: l10n.avcoNotTaxBody,
              source: null,
            ),
          ],
          detailTitle: l10n.realizedHowDetail,
          detail: [l10n.realizedIntro, l10n.realizedAvcoWarning],
        ),
      ),
      const SizedBox(height: QuoinSpace.section),
      Wrap(
        spacing: QuoinSpace.s,
        runSpacing: QuoinSpace.s,
        children: [
          for (final MapEntry(:key, :value) in orders.entries)
            QuoinChip.text(
              label: value,
              selected: key == _order,
              onTap: () => setState(() => _order = key),
            ),
        ],
      ),
      for (final year in years) ..._year(context, report, year),
      const SizedBox(height: QuoinSpace.section),
    ];
  }

  List<Widget> _year(BuildContext context, RealizedReport report, int year) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final lines = [
      for (final s in report.sales)
        if (s.year == year) s,
    ];
    final totals = SalesTotals(lines);
    final realized = format.signedMoney(totals.realized);
    final router = GoRouter.of(context);
    return [
      const SizedBox(height: QuoinSpace.section),
      MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: QuoinSpace.xs,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.realizedYearHeader(year),
                style: type.secondary.tabular.copyWith(color: c.muted),
              ),
            ),
            DisplayFigure(
              realized.text,
              color: realized.sign > 0
                  ? c.positive
                  : realized.sign < 0
                  ? c.negative
                  : null,
            ),
            Text(
              l10n.realizedYearSummary(totals.count, format.money(totals.cost)),
              style: type.secondary.tabular.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: QuoinSpace.m),
      for (final line in sortSales(lines, _order))
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.borderSubtle)),
          ),
          child: avcoSaleTile(
            context,
            line.sale,
            line.name,
            report.zone,
            icon: instrumentMark(
              type: line.instrument?.type ?? '',
              name: line.name,
              kind: line.instrument?.exposureKind,
            ),
            onOpenInstrument: line.instrument == null
                ? null
                : () => router.push(Routes.instrument(line.sale.instrumentId)),
          ),
        ),
    ];
  }

  List<Widget> _tax(BuildContext context, RealizedReport report) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final years = report.taxYears;
    final year = years.contains(_taxYear) ? _taxYear! : report.defaultYear;
    final view = year == null ? null : report.taxYear(year);
    final router = GoRouter.of(context);
    final territory = report.history.jurisdiction.territory;
    final rules = territoryRules(territory);
    final exemption = rules.dividendExemption;
    final comun = territory == Territory.comun;
    final how = InfoRow(
      label: l10n.realizedHow,
      onTap: () => showExplainSheet(
        context,
        title: l10n.realizedHow,
        intro: comun ? l10n.taxHowIntroComun : l10n.taxHowIntro,
        points: [
          (
            icon: QuoinIcons.oldestFirst,
            title: l10n.taxHowFifoTitle,
            body: l10n.taxHowFifoBody,
            source: null,
          ),
          (
            icon: QuoinIcons.buyBack,
            title: l10n.taxHowWashTitle,
            body: comun ? l10n.taxHowWashBodyComun : l10n.taxHowWashBody,
            source: rules.citations.repurchase,
          ),
          (
            icon: QuoinIcons.swap,
            title: l10n.taxHowSwapTitle,
            body: l10n.taxHowSwapBody,
            source: comun ? l10n.taxHowSwapSourceComun : l10n.taxHowSwapSource,
          ),
          (
            icon: QuoinIcons.earlierYears,
            title: l10n.taxHowCarryTitle,
            body: l10n.taxHowCarryBody,
            source: rules.citations.gainsCarryforward,
          ),
          (
            icon: QuoinIcons.cashFlow,
            title: comun ? l10n.taxHowIncomeTitleComun : l10n.taxHowIncomeTitle,
            body: comun ? l10n.taxHowIncomeBodyComun : l10n.taxHowIncomeBody,
            source: rules.citations.incomeCarryforward,
          ),
          if (exemption != null)
            (
              icon: QuoinIcons.taxRule,
              title: l10n.taxHowExemptTitle,
              body: l10n.taxHowExemptBody(
                QuoinFormat.of(context)
                    .money(Money.parse(exemption.limit), decimals: 0),
              ),
              source: exemption.source,
            ),
        ],
        detailTitle: l10n.realizedHowDetail,
        detail: [
          comun ? l10n.taxHowRulesComun : l10n.taxHowRules,
          l10n.taxHowOwnRules(
            comun ? l10n.taxHowSwapSourceComun : l10n.taxHowSwapSource,
          ),
          if (view?.scale case final scale?) l10n.taxScaleSource(scale.source),
        ],
      ),
    );

    return [
      if (!report.residenceChosen) ...[
        _ResidenceDefault(onTap: () => router.go(Routes.settings)),
        const SizedBox(height: QuoinSpace.m),
      ],
      for (final notice in [
        if (report.noRate.isNotEmpty) l10n.taxNoRate(report.noRate.join(', ')),
        if (report.unclassified.isNotEmpty)
          l10n.taxUnclassified(report.unclassified.join(', ')),
      ]) ...[
        Text(notice, style: type.secondary.copyWith(color: c.muted)),
        const SizedBox(height: QuoinSpace.m),
      ],
      if (year == null)
        Text(l10n.taxNoYears, style: type.secondary.copyWith(color: c.muted))
      else ...[
        Wrap(
          spacing: QuoinSpace.s,
          runSpacing: QuoinSpace.s,
          children: [
            for (final y in years)
              QuoinChip.code(
                label: '$y',
                selected: y == year,
                onTap: () => setState(() => _taxYear = y),
              ),
          ],
        ),
        const SizedBox(height: QuoinSpace.section),
        TaxYearPanel(
          report: report,
          view: view!,
          how: how,
          onOpenInstrument: (id) => router.push(Routes.instrument(id)),
        ),
      ],
    ];
  }
}

class _ResidenceDefault extends StatelessWidget {
  const _ResidenceDefault({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = QuoinType.of(context);
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppLocalizations.of(context).taxResidenceDefault,
              style: type.secondary.copyWith(
                color: QuoinColors.of(context).accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
