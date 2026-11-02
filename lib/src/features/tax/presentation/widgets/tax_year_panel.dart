import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/tax/domain/entities/realized_report.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/figure_block.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';

/// One fiscal year of the Bizkaia view, as the web's TaxYearPanel lays it
/// out: the base and the tax, the year's net, its FIFO sales with their
/// repurchases, the deferred losses that compute or wait, the carryforward
/// and the income in kind, which no figure adds.
class TaxYearPanel extends StatelessWidget {
  const TaxYearPanel({super.key, required this.report, required this.view});

  final RealizedReport report;
  final TaxYearView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final zone = report.zone;
    String money(Dec value) => format.money(Money.of(value));
    String signed(Dec value) => format.signedMoney(Money.of(value)).text;
    String deferred(Money value) => isBelowCent(value)
        ? l10n.taxBelowCent(format.money(Money.parse('0.01')))
        : format.signedMoney(value).text;

    final base = view.netSavingsBase;
    final quota = view.quota;
    final pending = view.result.pending;
    final integrations = view.result.integrations;
    final inKind = view.inKindIncome;
    final steps = [
      for (final s in view.carryforward.steps)
        if (s.year == view.year ||
            !(s.ownNet.isZero && s.pendingLossRemaining.isZero))
          s,
    ];

    Widget card(List<Widget> children) => QuoinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: children,
      ),
    );
    Widget body(String text) =>
        Text(text, style: type.secondary.copyWith(color: c.muted));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card([
          FigureBlock(
            label: l10n.taxNetBase,
            value: signed(base),
            sign: base.sign,
          ),
          FigureBlock(
            label: l10n.taxQuota,
            value: quota == null ? l10n.taxNoScale : format.money(quota),
            muted: quota == null,
            caption: view.scale == null ? null : l10n.taxScale(view.year),
          ),
        ]),
        const SizedBox(height: 12),
        card([
          Text(
            l10n.taxCounts(view.sales.length, view.affectedCount),
            style: type.secondary.copyWith(color: c.muted),
          ),
          DetailLine(label: l10n.taxNetOwn, value: signed(view.ownNet)),
          DetailLine(
            label: l10n.taxNetNonComputable,
            value: signed(view.nonComputableSum),
          ),
          DetailLine(
            label: l10n.taxNetIntegrated,
            value: signed(view.integratedSum),
          ),
          DetailLine(
            label: l10n.taxNetComputable,
            value: signed(view.computableNet),
            color: c.text,
          ),
        ]),
        sectionLabel(context, l10n.taxSalesTitle),
        if (view.sales.isEmpty)
          body(l10n.taxEmptyYear)
        else
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, gain) in view.sales.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _saleRow(context, gain, deferred),
                ],
              ],
            ),
          ),
        if (integrations.isNotEmpty) ...[
          sectionLabel(context, l10n.taxIntegrationsTitle),
          card([
            body(l10n.taxIntegrationsBody),
            for (final i in integrations)
              DetailLine(
                label:
                    '${report.nameOf(i.instrumentId)}: '
                    '${l10n.taxIntegrationLine(format.date(i.originTs, zone), format.date(i.ts, zone))}',
                value: deferred(i.amount),
              ),
          ]),
        ],
        if (pending.isNotEmpty) ...[
          sectionLabel(context, l10n.taxPendingTitle(view.year)),
          card([
            body(l10n.taxPendingBody),
            for (final p in pending)
              DetailLine(
                label:
                    '${report.nameOf(p.instrumentId)}: '
                    '${l10n.taxPendingLine(format.date(p.acquiredAt, zone))}',
                value: deferred(p.amount),
              ),
            DetailLine(
              label: l10n.taxTotal,
              value: signed(view.pendingSum),
              color: c.text,
            ),
          ]),
        ],
        sectionLabel(context, l10n.taxCarryforwardTitle),
        card([
          for (final (i, s) in steps.indexed) ...[
            if (i > 0) const Divider(height: 1),
            Text('${s.year}', style: type.row.mono),
            DetailLine(label: l10n.taxCfOwnNet, value: signed(s.ownNet)),
            DetailLine(
              label: l10n.taxCfConsumed,
              value: money(s.consumedFromCarryforward),
            ),
            DetailLine(label: l10n.taxCfFinal, value: signed(s.finalNet)),
            DetailLine(
              label: l10n.taxCfPending,
              value: money(s.pendingLossRemaining),
            ),
          ],
        ]),
        if (inKind.count > 0) ...[
          sectionLabel(context, l10n.taxInKindTitle),
          card([
            body(l10n.taxInKindBody),
            DetailLine(label: l10n.taxInKindCount, value: '${inKind.count}'),
            DetailLine(
              label: l10n.taxInKindGross,
              value: format.money(inKind.gross),
            ),
            DetailLine(
              label: l10n.taxInKindWithheld,
              value: format.money(inKind.withheld),
            ),
          ]),
        ],
        const SizedBox(height: QuoinSpace.section),
      ],
    );
  }

  Widget _saleRow(
    BuildContext context,
    RealizedGainDetail gain,
    String Function(Money value) deferred,
  ) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final zone = report.zone;
    final sale = gain.sale;
    final wash = gain.washSale;
    final material = wash != null && !isDeferralMinor(gain);
    final result = format.signedMoney(gain.realizedPnL);
    final until = windowOpenUntil(gain, report.today);
    final notice = gain.unlistedNotice;
    String share(int decimals) => format.percent(
      wash!.assessment.fraction,
      decimals: decimals,
      floorNonZero: true,
    );

    return SaleRow(
      name: report.nameOf(gain.instrumentId),
      when: format.date(gain.ts, zone),
      result: result.text,
      sign: result.sign,
      badge: material
          ? l10n.taxWashSaleBadge
          : notice != null
          ? l10n.taxUnlistedBadge
          : null,
      notes: [
        if (wash != null && !material)
          l10n.taxMinorDeferralReason(
            share(1),
            format.money(Money.parse('0.01')),
          ),
        if (wash != null && material)
          [
            l10n.taxWashSaleReason(
              format.quantity(wash.assessment.repurchased),
              format.quantity(sale.quantity),
            ),
            if (!gain.nonComputable.isZero)
              l10n.taxOwnDeferredReason(
                share(1),
                format.signedMoney(gain.nonComputable).text,
              ),
            if (!gain.carriedOver.isZero)
              l10n.taxCarriedOverReason(
                format.signedMoney(gain.carriedOver).text,
              ),
          ].join(' '),
        if (until != null)
          l10n.taxWindowOpenReason(format.day(CalendarDate.parse(until))),
        if (notice != null)
          l10n.taxUnlistedReason(format.date(notice.buyTs, zone)),
      ],
      details: [
        (l10n.saleUnits, format.quantity(sale.quantity)),
        (l10n.saleGross, format.money(sale.gross)),
        (l10n.saleFees, sale.fees.isZero ? '—' : format.money(sale.fees)),
        (l10n.saleCost, format.money(sale.costRemoved)),
        (l10n.saleResult, result.text),
      ],
      more: [
        if (wash != null) ...[
          _subtitle(context, l10n.taxBreakdownTitle(wash.letter.name)),
          for (final (label, value) in [
            (
              l10n.taxBefore(wash.windowMonths),
              format.quantity(wash.assessment.before),
            ),
            (
              l10n.taxRemainingAfter,
              format.quantity(wash.assessment.remainingAfter),
            ),
            (
              l10n.taxRepurchaseBefore,
              format.quantity(wash.assessment.repurchaseBefore),
            ),
            (
              l10n.taxRepurchaseAfter(wash.windowMonths),
              format.quantity(wash.assessment.repurchaseAfter),
            ),
            (l10n.taxRepurchased, format.quantity(wash.assessment.repurchased)),
            (l10n.taxShare, share(2)),
            if (!gain.nonComputable.isZero)
              (l10n.taxNonComputable, deferred(gain.nonComputable)),
            if (!gain.carriedOver.isZero)
              (l10n.taxCarriedOver, deferred(gain.carriedOver)),
          ])
            DetailLine(label: label, value: value),
          _subtitle(context, l10n.taxRecipientsTitle),
          for (final r in wash.recipients)
            DetailLine(
              label: l10n.taxRecipientLine(
                format.quantity(r.quantity),
                format.date(r.acquiredAt, zone),
              ),
              value: deferred(r.deferredLoss),
            ),
        ],
        _subtitle(context, l10n.taxLotsTitle),
        for (final lot in sale.lots)
          Text(
            l10n.taxLotLine(
              format.quantity(lot.quantity),
              format.date(lot.acquiredAt, zone),
              format.money(lot.unitCost),
            ),
            style: QuoinType.of(context).secondary.mono
                .copyWith(color: QuoinColors.of(context).body),
          ),
      ],
    );
  }

  Widget _subtitle(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: QuoinType.of(context).secondary
          .copyWith(color: QuoinColors.of(context).text),
    ),
  );
}
