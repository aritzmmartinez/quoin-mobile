import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/molecules/stat_columns.dart';
import 'package:quoin/src/ui/organisms/quoin_sheet.dart';

Future<void> showSaleSheet(
  BuildContext context, {
  required RealizedSale sale,
  required String name,
  required String zone,
  required Widget icon,
  VoidCallback? onOpenInstrument,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  return showQuoinSheet<void>(
    context,
    title: name,
    subtitle: l10n.saleOn(format.date(sale.ts, zone)),
    leading: icon,
    body: (sheet) => SaleSheet(
      sale: sale,
      onOpenInstrument: onOpenInstrument == null
          ? null
          : () {
              Navigator.of(sheet).pop();
              onOpenInstrument();
            },
    ),
  );
}

class SaleSheet extends StatelessWidget {
  const SaleSheet({super.key, required this.sale, this.onOpenInstrument});

  final RealizedSale sale;
  final VoidCallback? onOpenInstrument;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final result = format.signedMoney(sale.realizedPnL);
    final color = switch (result.sign) {
      > 0 => c.positive,
      < 0 => c.negative,
      _ => c.text,
    };
    final days = sale.holdingDays;
    final price = sale.price;
    final pct = sale.returnPct;
    const none = '—';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QuoinSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: QuoinSpace.s),
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: QuoinSpace.xxs,
              children: [
                Text(
                  l10n.saleResult,
                  style: type.secondary.copyWith(color: c.muted),
                ),
                DisplayFigure(result.text, color: color),
                if (pct != null)
                  Text(
                    format.percent(pct, signed: true),
                    style: type.row.mono.copyWith(color: color),
                  ),
                if (days != null)
                  Text(
                    l10n.saleHeld(days),
                    style: type.secondary.tabular.copyWith(color: c.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: QuoinSpace.section),
          StatColumns(
            stats: [
              (
                label: l10n.saleUnitsLabel,
                value: format.quantity(sale.quantity),
                sign: 0,
              ),
              (
                label: l10n.salePriceLabel,
                value: price == null ? none : format.money(price),
                sign: 0,
              ),
            ],
          ),
          const SizedBox(height: QuoinSpace.card),
          StatColumns(
            stats: [
              (
                label: l10n.saleReceived,
                value: format.money(sale.grossAmount.subtract(sale.fees)),
                sign: 0,
              ),
              (
                label: l10n.saleCostLabel,
                value: format.money(sale.costBasis),
                sign: 0,
              ),
            ],
          ),
          const SizedBox(height: QuoinSpace.card),
          Text(
            [
              if (!sale.fees.isZero)
                l10n.saleFeesIncluded(format.money(sale.fees)),
              l10n.saleCostBasis,
            ].join(' '),
            style: type.secondary.copyWith(color: c.muted),
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
}
