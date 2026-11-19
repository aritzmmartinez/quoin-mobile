import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/features/tax/presentation/widgets/tax_sale_sheet.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/molecules/count_list.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';

/// One fiscal year of the Bizkaia view: the estimated tax, the chain of
/// figures from the sales' result down to the savings base, how it is
/// worked out, the year's FIFO sales, the deferred losses still waiting and
/// the income in kind, which no figure adds.
class TaxYearPanel extends StatelessWidget {
  const TaxYearPanel({
    super.key,
    required this.report,
    required this.view,
    required this.how,
    this.onOpenInstrument,
  });

  final RealizedReport report;
  final TaxYearView view;
  final Widget how;
  final void Function(String instrumentId)? onOpenInstrument;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    String signed(Dec value) => format.signedMoney(Money.of(value)).text;

    final year = view.year;
    final base = view.netSavingsBase;
    final quota = view.quota;
    final pending = view.result.pending;
    final inKind = view.inKindIncome;
    final earlier = view.carryforward.steps.last.consumedFromCarryforward;
    Widget note(String text) => Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: QuoinSpace.s),
        child: Text(text, style: type.secondary.copyWith(color: c.muted)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: QuoinSpace.xs,
            children: [
              Text(
                quota == null ? l10n.taxBaseOf(year) : l10n.taxEstimated(year),
                style: type.secondary.tabular.copyWith(color: c.muted),
              ),
              DisplayFigure(quota == null ? signed(base) : format.money(quota)),
              if (quota == null)
                Text(
                  l10n.taxNoScaleFor(year),
                  style: type.secondary.copyWith(color: c.muted),
                )
              else
                Text.rich(
                  TextSpan(
                    text: '${l10n.taxBase} ',
                    children: [
                      TextSpan(
                        text: signed(base),
                        style: type.secondary.mono.copyWith(color: c.body),
                      ),
                      TextSpan(text: ' · ${l10n.taxScaleOf(year)}'),
                    ],
                  ),
                  style: type.secondary.tabular.copyWith(color: c.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: QuoinSpace.gutter),
        CountList(
          entries: [
            CountEntry(l10n.taxSalesResult, signed(view.ownNet)),
            CountEntry(
              l10n.taxDeferredByRepurchase,
              signed(-view.nonComputableSum),
            ),
            CountEntry(l10n.taxDeferredCounting, signed(view.integratedSum)),
            if (earlier.isPositive) ...[
              CountEntry(
                l10n.taxCountsThisYear,
                signed(view.computableNet),
                strong: true,
              ),
              CountEntry(l10n.taxEarlierLosses, signed(-earlier)),
            ],
            CountEntry(l10n.taxBase, signed(base), strong: true),
          ],
        ),
        const SizedBox(height: QuoinSpace.gutter),
        how,
        GroupHeader(
          label: l10n.taxSalesOf(year),
          total: '${view.sales.length}',
        ),
        if (view.sales.isEmpty)
          note(l10n.taxEmptyYear)
        else
          for (final gain in view.sales) _saleRow(context, gain),
        if (pending.isNotEmpty) ...[
          GroupHeader(
            label: l10n.taxPendingTitle(year),
            total: signed(view.pendingSum),
          ),
          note(l10n.taxPendingBody),
          CountList(
            entries: [
              for (final p in pending)
                CountEntry(
                  report.nameOf(p.instrumentId),
                  deferredText(l10n, format, p.amount),
                  note: l10n.taxPendingLine(
                    format.date(p.acquiredAt, report.zone),
                  ),
                ),
            ],
          ),
        ],
        if (inKind.count > 0) ...[
          GroupHeader(label: l10n.taxInKindTitle),
          note(l10n.taxInKindBody),
          CountList(
            entries: [
              CountEntry(l10n.taxInKindCount, '${inKind.count}'),
              CountEntry(l10n.taxInKindGross, format.money(inKind.gross)),
              CountEntry(l10n.taxInKindWithheld, format.money(inKind.withheld)),
            ],
          ),
        ],
        const SizedBox(height: QuoinSpace.section),
      ],
    );
  }

  Widget _saleRow(BuildContext context, RealizedGainDetail gain) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final material = gain.washSale != null && !isDeferralMinor(gain);
    final result = format.signedMoney(gain.realizedPnL);
    final name = report.nameOf(gain.instrumentId);
    final instrument = report.instruments[gain.instrumentId];
    Widget icon() => instrumentMark(
      type: instrument?.type ?? '',
      name: name,
      kind: instrument?.exposureKind,
    );
    final open = onOpenInstrument;
    return SaleRow(
      leading: icon(),
      name: name,
      when: format.date(gain.ts, report.zone),
      tag: material
          ? l10n.taxRepurchaseTag
          : gain.unlistedNotice != null
          ? l10n.taxNoticeTag
          : null,
      result: result.text,
      sign: result.sign,
      note: material && gain.computablePnL.compareTo(gain.realizedPnL) != 0
          ? (
              label: l10n.taxCountsLabel,
              value: format.signedMoney(gain.computablePnL).text,
            )
          : null,
      onTap: () => showTaxSaleSheet(
        context,
        gain: gain,
        name: name,
        type: instrument?.type ?? '',
        year: view.year,
        zone: report.zone,
        today: report.today,
        icon: icon(),
        onOpenInstrument: open == null || instrument == null
            ? null
            : () => open(gain.instrumentId),
      ),
    );
  }
}

String deferredText(AppLocalizations l10n, QuoinFormat format, Money value) =>
    isBelowCent(value)
    ? l10n.taxBelowCent(format.money(Money.parse('0.01')))
    : format.signedMoney(value).text;
