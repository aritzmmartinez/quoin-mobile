import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/presentation/providers/tax_providers.dart';
import 'package:quoin/src/ui/molecules/quoin_disclosure.dart';
import 'package:quoin/src/features/tax/presentation/widgets/tax_year_panel.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/organisms/quoin_segmented_pages.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';
import 'package:quoin/src/ui/atoms/quoin_section_label.dart';

class RealizedPage extends ConsumerStatefulWidget {
  const RealizedPage({super.key});

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
                segments: [
                  (0, l10n.realizedTabSales),
                  (1, l10n.realizedTabTax),
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
      QuoinDisclosure(
        title: l10n.realizedHow,
        paragraphs: [l10n.realizedIntro, l10n.realizedAvcoWarning],
      ),
      const SizedBox(height: QuoinSpace.m),
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
    final realized = format.gain(totals.realized, totals.returnPct);
    return [
      QuoinSectionLabel('$year'),
      DisplayFigure(
        realized.text,
        color: realized.sign > 0
            ? c.positive
            : realized.sign < 0
            ? c.negative
            : null,
      ),
      const SizedBox(height: QuoinSpace.tight),
      Text(
        l10n.realizedYearSummary(totals.count, year, format.money(totals.cost)),
        style: type.secondary.copyWith(color: c.muted),
      ),
      const SizedBox(height: QuoinSpace.m),
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
        const SizedBox(height: QuoinSpace.m),
      ],
      QuoinDisclosure(
        title: l10n.realizedHow,
        paragraphs: [l10n.taxHowRules, l10n.taxHowOwnRules],
      ),
      const SizedBox(height: QuoinSpace.m),
      if (year == null)
        Text(l10n.taxNoYears, style: type.secondary.copyWith(color: c.muted))
      else ...[
        Text(l10n.taxYearLabel, style: type.small.copyWith(color: c.muted)),
        const SizedBox(height: QuoinSpace.s),
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
        TaxYearPanel(report: report, view: report.taxYear(year)),
      ],
    ];
  }
}
