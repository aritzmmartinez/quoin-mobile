import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/instrument_detail.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/fact_grid.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/ledger_tiles.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/result_view.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/instrument_icon.dart';
import 'package:quoin/src/ui/atoms/marked_span.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';
import 'package:quoin/src/ui/atoms/quoin_section_label.dart';

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
              body: EmptyState(
                icon: QuoinIcons.search,
                title: l10n.instrumentNotFoundTitle,
                body: l10n.instrumentNotFound,
              ),
            )
          : QuoinPage.list(title: '', children: _content(context, detail)),
    );
  }

  List<Widget> _content(BuildContext context, InstrumentDetail d) {
    final l10n = AppLocalizations.of(context);
    final format = QuoinFormat.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final i = d.instrument;
    final position = d.position;
    final held = position != null && position.isOpen;
    final value = d.value;
    final marketValue = value?.marketValue;
    final pnl = value?.unrealizedPnL;
    final firstBuy = d.firstBuy;
    final typeLabel = l10n.instrumentType(i.type);
    final category = switch (i.exposureKind) {
      null => null,
      final kind => categoryLabel(l10n, kind.code),
    };
    final isin = i.type == 'CRYPTO' ? null : i.id;

    return [
      Row(
        spacing: QuoinSpace.m,
        children: [
          instrumentMark(
            type: i.type,
            name: i.name,
            kind: i.exposureKind,
            extent: InstrumentIcon.large,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: QuoinSpace.xxs,
              children: [
                Semantics(header: true, child: Text(i.name, style: type.title)),
                Text.rich(
                  TextSpan(
                    text: [
                      typeLabel,
                      if (category != null && category != typeLabel) category,
                      if (isin != null) '',
                    ].join(' · '),
                    children: [
                      if (isin != null)
                        TextSpan(text: isin, style: type.secondary.mono),
                    ],
                  ),
                  style: type.secondary.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: QuoinSpace.section),
      MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: QuoinSpace.tight,
          children: [
            Text(
              l10n.instrumentValue,
              style: type.secondary.copyWith(color: c.muted),
            ),
            if (!held)
              Text(
                l10n.instrumentClosed,
                style: type.row.copyWith(color: c.muted),
              )
            else if (marketValue == null)
              Text(
                l10n.instrumentNoPrice,
                style: type.row.copyWith(color: c.muted),
              )
            else ...[
              DisplayFigure(format.money(marketValue)),
              if (pnl != null)
                switch (format.gainLine(pnl, d.unrealizedPnLPct)) {
                  final gain => Text.rich(
                    TextSpan(
                      text: gain.text,
                      style: type.secondary.mono.copyWith(
                        color: switch (gain.sign) {
                          > 0 => c.positive,
                          < 0 => c.negative,
                          _ => c.text,
                        },
                      ),
                      children: [
                        TextSpan(
                          text: ' ${l10n.instrumentOverCost}',
                          style: type.secondary.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                },
            ],
          ],
        ),
      ),
      const SizedBox(height: QuoinSpace.m),
      Text(
        l10n.instrumentNoHistory,
        style: type.secondary.copyWith(color: c.muted),
      ),
      if (held) ...[
        const SizedBox(height: QuoinSpace.section),
        FactGrid(
          facts: [
            (
              label: l10n.instrumentHeld,
              value: markedSpan(
                unitsText(l10n, format, i.type, position.quantity),
                format.quantity(position.quantity),
                type.row.mono,
              ),
            ),
            (
              label: l10n.instrumentCost,
              value: TextSpan(
                text: format.money(position.costBasis),
                style: type.row.mono,
              ),
            ),
            (
              label: l10n.instrumentAverageCost,
              value: TextSpan(
                text: format.money(position.averageCost),
                style: type.row.mono,
              ),
            ),
            if (firstBuy != null)
              (
                label: l10n.instrumentFirstBuy,
                value: TextSpan(
                  text: format.date(firstBuy, d.zone),
                  style: type.row.tabular,
                ),
              ),
          ],
        ),
      ],
      if (d.sales.isNotEmpty) ...[
        QuoinSectionLabel.heading(l10n.instrumentSales),
        for (final sale in d.sales)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderSubtle)),
            ),
            child: avcoSaleTile(
              context,
              sale,
              i.name,
              d.zone,
              icon: instrumentMark(
                type: i.type,
                name: i.name,
                kind: i.exposureKind,
              ),
            ),
          ),
      ],
      if (d.movements.isNotEmpty) ...[
        QuoinSectionLabel.heading(
          l10n.movementsTitle,
          action: TextButton(
            onPressed: () => context.push(Routes.movementsOf(i.id)),
            child: Text(l10n.seeAll),
          ),
        ),
        for (final m in d.movements.take(_recentMovements))
          movementTile(context, m, d.zone, inMonth: false),
      ],
      const SizedBox(height: QuoinSpace.section),
    ];
  }
}
