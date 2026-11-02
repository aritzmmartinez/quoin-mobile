import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/ui/molecules/movement_row.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';

Widget movementTile(
  BuildContext context,
  Movement movement,
  String zone, {
  VoidCallback? onTap,
  bool showInstrument = true,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  final m = movement;
  final type = switch (m) {
    Movement(isSwap: true) => 'SWAP',
    Movement(inKind: true, type: 'BUY' || 'DIVIDEND') => '${m.type}_IN_KIND',
    _ => m.type,
  };
  final amount = m.amount;
  final route = m.swapRoute;
  return MovementRow(
    type: l10n.movementType(type),
    subject: route != null && route.isNotEmpty
        ? route
        : showInstrument
        ? m.instrumentName
        : null,
    date: format.date(m.ts, zone),
    amount: switch (amount) {
      null => '—',
      _ when m.isSwap => format.money(amount),
      _ => format.signedMoney(amount).text,
    },
    marks: [
      if (m.converted) l10n.movementConverted(m.currency),
      if (m.noRate) l10n.movementNoRate,
    ],
    onTap: onTap,
  );
}

Widget avcoSaleTile(
  BuildContext context,
  RealizedSale sale,
  String name,
  String zone,
) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  final result = format.signedMoney(sale.realizedPnL);
  final days = sale.holdingDays;
  final price = sale.price;
  return SaleRow(
    name: name,
    when: [
      format.date(sale.ts, zone),
      if (days != null) l10n.realizedDays(days),
    ].join(' · '),
    result: result.text,
    sign: result.sign,
    returnPct: switch (sale.returnPct) {
      null => null,
      final pct => format.percent(pct, signed: true),
    },
    details: [
      (l10n.saleUnits, format.quantity(sale.quantity)),
      (l10n.salePrice, price == null ? '—' : format.money(price)),
      (l10n.saleGross, format.money(sale.grossAmount)),
      (l10n.saleFees, sale.fees.isZero ? '—' : format.money(sale.fees)),
      (l10n.saleCost, format.money(sale.costBasis)),
      (l10n.saleResult, result.text),
    ],
  );
}
