import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/gain_badge.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

/// A portfolio screen through its states: nothing while it loads, the
/// failure, [empty] when nothing was ever imported, else [builder].
class PortfolioView extends StatelessWidget {
  const PortfolioView({
    super.key,
    required this.title,
    required this.overview,
    required this.empty,
    required this.builder,
  });

  final String title;
  final AsyncValue<Result<PortfolioOverview>> overview;
  final Widget empty;
  final Widget Function(PortfolioOverview overview) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (overview.value) {
      null => QuoinPage(title: title, body: const SizedBox.shrink()),
      Ok(value: PortfolioOverview(hasLedger: false)) => QuoinPage(
        title: title,
        body: empty,
      ),
      Ok(:final value) => builder(value),
      Err(:final failure) => QuoinPage(
        title: title,
        body: EmptyState(
          message: switch (failure) {
            StorageFailure() ||
            NetworkFailure() ||
            ImportFailure() => l10n.portfolioLoadFailed,
          },
        ),
      ),
    };
  }
}

Widget sectionLabel(BuildContext context, String text, {Widget? action}) {
  final c = QuoinColors.of(context);
  return Padding(
    padding: const EdgeInsets.only(top: QuoinSpace.section, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text.toUpperCase(),
              style: QuoinType.of(context).section.copyWith(color: c.muted),
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// What the portfolio leaves out, named: instruments with no recent rate and
/// those with a trade that has none.
List<Widget> valuationNotices(BuildContext context, PortfolioOverview o) {
  final l10n = AppLocalizations.of(context);
  final style = QuoinType.of(context).secondary
      .copyWith(color: QuoinColors.of(context).muted);
  return [
    if (o.unrated.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(l10n.fxUnrated(o.unrated.join(', ')), style: style),
    ],
    if (o.unconvertible.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(l10n.fxUnconvertible(o.unconvertible.join(', ')), style: style),
    ],
  ];
}

String categoryLabel(AppLocalizations l10n, String category) =>
    switch (ExposureKind.values.where((k) => k.code == category).firstOrNull) {
      ExposureKind.company => l10n.categoryCompany,
      ExposureKind.equityFund => l10n.categoryEquityFund,
      ExposureKind.bondFund => l10n.categoryBondFund,
      ExposureKind.commodity => l10n.categoryCommodity,
      ExposureKind.crypto => l10n.categoryCrypto,
      null => l10n.categoryOther,
    };

/// [holdings] as rows in one card. An unpriced position shows its cost,
/// muted, and says it has no price: it is named, never added to the value.
Widget holdingsCard(
  BuildContext context,
  List<Holding> holdings, {
  required String Function(Holding holding) detail,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  final c = QuoinColors.of(context);
  final type = QuoinType.of(context);

  Widget row(Holding h) {
    final value = h.value.marketValue;
    final pct = h.unrealizedPnLPct;
    final pnl = h.value.unrealizedPnL;
    if (value == null) {
      return PositionRow(
        name: h.name,
        detail: detail(h),
        value: l10n.positionCost(format.money(h.position.costBasis)),
        valueMuted: true,
        change: Text(
          l10n.positionUnpriced,
          style: type.small.copyWith(color: c.muted),
        ),
      );
    }
    return PositionRow(
      name: h.name,
      detail: detail(h),
      value: format.money(value),
      change: GainBadge(
        text: pct == null
            ? format.signedMoney(pnl!).text
            : format.percent(pct, signed: true),
        sign: pnl!.amount.sign,
      ),
    );
  }

  return QuoinCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, h) in holdings.indexed) ...[
          if (i > 0) const Divider(height: 1),
          row(h),
        ],
      ],
    ),
  );
}
