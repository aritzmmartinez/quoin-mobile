import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/below_cent.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/portfolio/domain/entities/movement.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/sale_sheet.dart';
import 'package:quoin/src/ui/atoms/instrument_icon.dart';
import 'package:quoin/src/ui/molecules/movement_row.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';

Widget movementTile(
  BuildContext context,
  Movement movement,
  String zone, {
  VoidCallback? onTap,
  bool inMonth = true,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  final m = movement;
  final kind = l10n.movementType(switch (m) {
    Movement(isSwap: true) => 'SWAP',
    Movement(inKind: true, type: 'BUY' || 'DIVIDEND') => '${m.type}_IN_KIND',
    _ => m.type,
  });
  final belowCent = m.amount != null && isBelowCent(m.amount!);
  final amount = switch (m.amount) {
    null => '—',
    _ when belowCent => belowCentText(l10n, format),
    final amount when m.isSwap => format.money(amount),
    final amount => format.signedMoney(amount).text,
  };
  final marks = [
    if (m.converted) l10n.movementConverted(m.currency),
    if (m.noRate) l10n.movementNoRate,
  ];
  if (!inMonth) {
    return MovementRow(
      title: kind,
      detail: [format.date(m.ts, zone), ...marks].join(' · '),
      amount: amount,
      quiet: m.isSwap || belowCent,
      onTap: onTap,
    );
  }

  final route = m.swapRoute;
  final subject = route != null && route.isNotEmpty ? route : m.instrumentName;
  final name = m.instrumentName;
  return MovementRow(
    leading: name == null
        ? const InstrumentIcon.tile(QuoinIcons.cashFlow)
        : instrumentMark(
            type: m.instrumentType ?? '',
            name: name,
            kind: m.exposureKind,
          ),
    title: subject ?? kind,
    detail: [
      if (subject != null) kind,
      format.dayMonth(m.ts, zone),
      ...marks,
    ].join(' · '),
    amount: amount,
    quiet: m.isSwap || belowCent,
    onTap: onTap,
  );
}

Widget avcoSaleTile(
  BuildContext context,
  RealizedSale sale,
  String name,
  String zone, {
  required Widget icon,
  VoidCallback? onOpenInstrument,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  final result = format.signedMoney(sale.realizedPnL);
  final days = sale.holdingDays;
  return SaleRow(
    name: name,
    when: [
      format.date(sale.ts, zone),
      if (days != null) l10n.realizedDays(days),
    ].join(' · '),
    result: result.text,
    sign: result.sign,
    onTap: () => showSaleSheet(
      context,
      sale: sale,
      name: name,
      zone: zone,
      icon: icon,
      onOpenInstrument: onOpenInstrument,
    ),
  );
}
