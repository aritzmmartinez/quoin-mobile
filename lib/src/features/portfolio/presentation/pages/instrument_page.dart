import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/instrument_detail.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/figure_block.dart';
import 'package:quoin/src/ui/molecules/gain_badge.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

/// Movements shown on the page before «Ver movimientos».
const _recentMovements = 5;

class InstrumentPage extends ConsumerWidget {
  const InstrumentPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ResultView(
      title: id,
      value: ref.watch(instrumentDetailProvider(id)),
      builder: (detail) => detail == null
          ? QuoinPage(
              title: id,
              body: EmptyState(message: l10n.instrumentNotFound),
            )
          : QuoinPage.list(
              title: detail.instrument.name,
              children: _content(context, detail),
            ),
    );
  }

  List<Widget> _content(BuildContext context, InstrumentDetail d) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final position = d.position;
    final held = position != null && position.isOpen;
    final value = d.value;
    final marketValue = value?.marketValue;
    final pnl = value?.unrealizedPnL;
    final firstBuy = d.firstBuy;

    Widget grid(List<Widget> blocks) => Wrap(
      spacing: QuoinSpace.card,
      runSpacing: QuoinSpace.card,
      children: [
        for (final block in blocks)
          FractionallySizedBox(widthFactor: 0.46, child: block),
      ],
    );

    return [
      Text(
        '${d.instrument.id} · ${d.instrument.type}',
        style: type.secondary.mono.copyWith(color: c.muted),
      ),
      const SizedBox(height: QuoinSpace.section),
      Text(
        l10n.instrumentValue,
        style: type.secondary.copyWith(color: c.muted),
      ),
      const SizedBox(height: 6),
      if (!held)
        Text(l10n.instrumentClosed, style: type.row.copyWith(color: c.muted))
      else if (marketValue == null)
        Text(l10n.instrumentNoPrice, style: type.row.copyWith(color: c.muted))
      else ...[
        DisplayFigure(format.money(marketValue)),
        if (pnl != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GainBadge(
              text: format.signedMoney(pnl).text,
              sign: pnl.amount.sign,
            ),
          ),
        ],
      ],
      const SizedBox(height: QuoinSpace.section),
      QuoinCard(
        child: SizedBox(
          height: 96,
          child: Center(
            child: Text(
              l10n.instrumentNoHistory,
              textAlign: TextAlign.center,
              style: type.secondary.copyWith(color: c.muted),
            ),
          ),
        ),
      ),
      if (position != null) ...[
        const SizedBox(height: QuoinSpace.section),
        grid([
          FigureBlock(
            label: l10n.instrumentQuantity,
            value: format.quantity(position.quantity),
          ),
          FigureBlock(
            label: l10n.instrumentCost,
            value: format.money(position.costBasis),
          ),
          FigureBlock(
            label: l10n.instrumentAverageCost,
            value: format.money(position.averageCost),
          ),
          if (firstBuy != null)
            FigureBlock(
              label: l10n.instrumentFirstBuy,
              value: format.date(firstBuy, d.zone),
            ),
          if (d.sales.isNotEmpty)
            FigureBlock(
              label: l10n.instrumentRealized,
              value: format.signedMoney(position.realizedPnL).text,
              sign: position.realizedPnL.amount.sign,
            ),
        ]),
      ],
      if (d.sales.isNotEmpty) ...[
        sectionLabel(context, l10n.instrumentSales),
        QuoinCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, sale) in d.sales.indexed) ...[
                if (i > 0) const Divider(height: 1),
                avcoSaleTile(context, sale, d.instrument.name, d.zone),
              ],
            ],
          ),
        ),
      ],
      if (d.movements.isNotEmpty) ...[
        sectionLabel(context, l10n.instrumentMovements),
        QuoinCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, m)
                  in d.movements.take(_recentMovements).indexed) ...[
                if (i > 0) const Divider(height: 1),
                movementTile(context, m, d.zone, showInstrument: false),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.push(Routes.movementsOf(d.instrument.id)),
          child: Text(l10n.seeMovements),
        ),
      ],
      const SizedBox(height: QuoinSpace.section),
    ];
  }
}
