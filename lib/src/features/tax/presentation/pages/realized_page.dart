import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/presentation/providers/tax_providers.dart';
import 'package:quoin/src/features/tax/presentation/widgets/how_calculated.dart';
import 'package:quoin/src/features/tax/presentation/widgets/tax_year_panel.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

enum _Tab { sales, tax }

class RealizedPage extends ConsumerStatefulWidget {
  const RealizedPage({super.key});

  @override
  ConsumerState<RealizedPage> createState() => _RealizedPageState();
}

class _RealizedPageState extends ConsumerState<RealizedPage> {
  var _tab = _Tab.sales;
  var _order = SaleOrder.date;
  int? _taxYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResultView(
      title: l10n.realizedTitle,
      value: ref.watch(realizedReportProvider),
      builder: (report) => report.hasLedger
          ? QuoinPage.list(
              title: l10n.realizedTitle,
              children: [
                QuoinSegmented<_Tab>(
                  segments: [
                    (_Tab.sales, l10n.realizedTabSales),
                    (_Tab.tax, l10n.realizedTabTax),
                  ],
                  selected: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: QuoinSpace.section),
                ...switch (_tab) {
                  _Tab.sales => _sales(context, report),
                  _Tab.tax => _tax(context, report),
                },
              ],
            )
          : QuoinPage(
              title: l10n.realizedTitle,
              body: EmptyState(message: l10n.homeEmpty),
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
      HowCalculated(paragraphs: [l10n.realizedIntro, l10n.realizedAvcoWarning]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
    final pct = totals.returnPct;
    return [
      sectionLabel(context, '$year'),
      DisplayFigure(
        pct == null
            ? realized.text
            : '${realized.text} (${format.percent(pct, signed: true)})',
        color: realized.sign > 0
            ? c.positive
            : realized.sign < 0
            ? c.negative
            : null,
      ),
      const SizedBox(height: 6),
      Text(
        l10n.realizedYearSummary(totals.count, year, format.money(totals.cost)),
        style: type.secondary.copyWith(color: c.muted),
      ),
      const SizedBox(height: 12),
      QuoinCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, line) in sortSales(lines, _order).indexed) ...[
              if (i > 0) const Divider(height: 1),
              avcoSaleTile(context, line.sale, line.name, report.zone),
            ],
          ],
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

    return [
      for (final notice in [
        if (report.noRate.isNotEmpty) l10n.taxNoRate(report.noRate.join(', ')),
        if (report.unclassified.isNotEmpty)
          l10n.taxUnclassified(report.unclassified.join(', ')),
      ]) ...[
        Text(notice, style: type.secondary.copyWith(color: c.muted)),
        const SizedBox(height: 12),
      ],
      HowCalculated(paragraphs: [l10n.taxHowRules, l10n.taxHowOwnRules]),
      const SizedBox(height: 12),
      if (year == null)
        Text(l10n.taxNoYears, style: type.secondary.copyWith(color: c.muted))
      else ...[
        Text(l10n.taxYearLabel, style: type.small.copyWith(color: c.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        TaxYearPanel(report: report, view: report.taxYear(year)),
      ],
    ];
  }
}
