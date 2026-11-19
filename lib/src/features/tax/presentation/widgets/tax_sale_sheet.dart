import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/tax/presentation/widgets/tax_year_panel.dart';
import 'package:quoin/src/ui/atoms/marked_span.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/count_list.dart';
import 'package:quoin/src/ui/molecules/fold_section.dart';
import 'package:quoin/src/ui/molecules/stat_columns.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

Future<void> showTaxSaleSheet(
  BuildContext context, {
  required RealizedGainDetail gain,
  required String name,
  required String type,
  required int year,
  required String zone,
  required String today,
  required Widget icon,
  VoidCallback? onOpenInstrument,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  return showQuoinSheet<void>(
    context,
    title: name,
    subtitle: l10n.taxSaleSubtitle(
      format.date(gain.ts, zone),
      unitsText(l10n, format, type, gain.sale.quantity),
    ),
    leading: icon,
    body: (sheet) => TaxSaleSheet(
      gain: gain,
      type: type,
      year: year,
      zone: zone,
      today: today,
      onOpenInstrument: onOpenInstrument == null
          ? null
          : () {
              Navigator.of(sheet).pop();
              onOpenInstrument();
            },
    ),
  );
}

class TaxSaleSheet extends StatelessWidget {
  const TaxSaleSheet({
    super.key,
    required this.gain,
    required this.type,
    required this.year,
    required this.zone,
    required this.today,
    this.onOpenInstrument,
  });

  final RealizedGainDetail gain;
  final String type;
  final int year;
  final String zone;
  final String today;
  final VoidCallback? onOpenInstrument;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final t = QuoinType.of(context);
    final sale = gain.sale;
    final wash = gain.washSale;
    final material = wash != null && !isDeferralMinor(gain);
    final result = format.signedMoney(gain.realizedPnL);
    final counts = format.signedMoney(gain.computablePnL);
    String units(Dec quantity) => unitsText(l10n, format, type, quantity);
    final until = windowOpenUntil(gain, today);
    final notice = gain.unlistedNotice;

    Widget pair(Widget label, Widget value) => MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QuoinSpace.xs),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: QuoinSpace.m,
            children: [
              Expanded(child: label),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.45),
                child: value,
              ),
            ],
          ),
        ),
      ),
    );
    Widget line(String label, String value) => pair(
      Text(label, style: t.secondary.copyWith(color: c.body)),
      Text(
        value,
        textAlign: TextAlign.end,
        style: t.secondary.mono.copyWith(color: c.text),
      ),
    );
    Widget held(String label, Dec quantity) => pair(
      Text(label, style: t.secondary.copyWith(color: c.body)),
      Text.rich(
        markedSpan(
          units(quantity),
          format.quantity(quantity),
          t.secondary.mono,
        ),
        textAlign: TextAlign.end,
        style: t.secondary.copyWith(color: c.text),
      ),
    );

    final notes = [
      if (wash != null && !material)
        l10n.taxMinorDeferralReason(
          format.percent(
            wash.assessment.fraction,
            decimals: 1,
            floorNonZero: true,
          ),
          format.money(Money.parse('0.01')),
        ),
      if (until != null)
        l10n.taxWindowOpenReason(format.day(CalendarDate.parse(until))),
      if (notice != null)
        l10n.taxUnlistedReason(format.date(notice.buyTs, zone)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: QuoinSpace.s),
          StatColumns(
            stats: [
              (label: l10n.saleResult, value: result.text, sign: result.sign),
              (
                label: l10n.taxCountsIn(year),
                value: counts.text,
                sign: counts.sign,
              ),
            ],
          ),
          if (material) ...[
            const SizedBox(height: QuoinSpace.gutter),
            _repurchase(context, wash, units),
          ],
          for (final note in notes) ...[
            const SizedBox(height: QuoinSpace.m),
            Text(note, style: t.secondary.copyWith(color: c.muted)),
          ],
          const SizedBox(height: QuoinSpace.gutter),
          CountList(
            closed: false,
            entries: [
              CountEntry(
                l10n.saleReceived,
                format.money(sale.gross.subtract(sale.fees)),
              ),
              CountEntry(l10n.saleCostLabel, format.money(sale.costRemoved)),
              CountEntry(l10n.saleFees, format.money(sale.fees)),
            ],
          ),
          FoldSection(
            title: l10n.taxLotsTitle,
            initiallyOpen: true,
            children: [
              for (final lot in sale.lots)
                pair(
                  Text(
                    l10n.taxLotLine(
                      units(lot.quantity),
                      format.date(lot.acquiredAt, zone),
                    ),
                    style: t.secondary.tabular.copyWith(color: c.body),
                  ),
                  switch (format.money(lot.unitCost)) {
                    final price => Text.rich(
                      markedSpan(
                        l10n.taxLotAt(price),
                        price,
                        t.secondary.mono.copyWith(color: c.text),
                      ),
                      textAlign: TextAlign.end,
                      style: t.secondary.copyWith(color: c.muted),
                    ),
                  },
                ),
            ],
          ),
          if (wash != null)
            FoldSection(
              title: l10n.taxHowRepurchase,
              summary: l10n.taxHowWashSource,
              children: [
                held(l10n.taxBefore(wash.windowMonths), wash.assessment.before),
                held(l10n.taxRemainingAfter, wash.assessment.remainingAfter),
                held(
                  l10n.taxRepurchaseBefore,
                  wash.assessment.repurchaseBefore,
                ),
                held(
                  l10n.taxRepurchaseAfter(wash.windowMonths),
                  wash.assessment.repurchaseAfter,
                ),
                held(l10n.taxRepurchased, wash.assessment.repurchased),
                line(
                  l10n.taxShare,
                  format.percent(
                    wash.assessment.fraction,
                    decimals: 2,
                    floorNonZero: true,
                  ),
                ),
                if (!gain.nonComputable.isZero)
                  line(
                    l10n.taxNonComputable,
                    deferredText(l10n, format, gain.nonComputable),
                  ),
                if (!gain.carriedOver.isZero)
                  line(
                    l10n.taxCarriedOver,
                    deferredText(l10n, format, gain.carriedOver),
                  ),
              ],
            ),
          if (wash != null && wash.recipients.isNotEmpty)
            FoldSection(
              title: l10n.taxWhereDeferred,
              children: [
                for (final r in wash.recipients)
                  line(
                    l10n.taxRecipientLine(
                      units(r.quantity),
                      format.date(r.acquiredAt, zone),
                    ),
                    deferredText(l10n, format, r.deferredLoss),
                  ),
              ],
            ),
          if (onOpenInstrument case final open?) ...[
            const SizedBox(height: QuoinSpace.section),
            OutlinedButton(
              onPressed: open,
              child: Text(l10n.saleOpenInstrument),
            ),
          ],
        ],
      ),
    );
  }

  Widget _repurchase(
    BuildContext context,
    WashSaleDetail wash,
    String Function(Dec quantity) units,
  ) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final t = QuoinType.of(context);
    final a = wash.assessment;
    final months = wash.windowMonths;
    final window = switch ((
      a.repurchaseBefore.isPositive,
      a.repurchaseAfter.isPositive,
    )) {
      (true, true) => l10n.taxWindowBoth(months),
      (true, false) => l10n.taxWindowBefore(months),
      _ => l10n.taxWindowAfter(months),
    };
    final deferred = deferredText(l10n, format, gain.nonComputable);
    final carried = deferredText(l10n, format, gain.carriedOver);
    final figure = t.secondary.mono.copyWith(color: c.text);
    return Container(
      padding: const EdgeInsets.all(QuoinSpace.card),
      decoration: ShapeDecoration(
        color: c.iconTile,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QuoinRadius.compact),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: QuoinSpace.m,
        children: [
          QuoinIcon(QuoinIcons.buyBack, size: QuoinIconSize.row, color: c.body),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.taxRepurchasedIn(
                      format.quantity(a.repurchased),
                      units(gain.sale.quantity),
                      window,
                    ),
                  ),
                  if (!gain.nonComputable.isZero) ...[
                    const TextSpan(text: ' '),
                    markedSpan(
                      l10n.taxDeferredPart(deferred),
                      deferred,
                      figure,
                    ),
                  ],
                  if (!gain.carriedOver.isZero) ...[
                    const TextSpan(text: ' '),
                    markedSpan(l10n.taxCarriedPart(carried), carried, figure),
                  ],
                ],
              ),
              style: t.secondary.copyWith(color: c.body, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
