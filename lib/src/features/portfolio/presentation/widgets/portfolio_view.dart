import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
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

class PortfolioView extends StatelessWidget {
  const PortfolioView({
    super.key,
    required this.title,
    required this.overview,
    required this.empty,
    required this.builder,
    this.onRefresh,
  });

  final String title;
  final AsyncValue<Result<PortfolioOverview>> overview;
  final Widget empty;
  final Widget Function(PortfolioOverview overview) builder;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (overview.value) {
      null => QuoinPage(title: title, body: const SizedBox.shrink()),
      Ok(value: PortfolioOverview(hasLedger: false)) => QuoinPage(
        title: title,
        onRefresh: onRefresh,
        body: empty,
      ),
      Ok(:final value) => builder(value),
      Err(:final failure) => QuoinPage(
        title: title,
        onRefresh: onRefresh,
        body: switch (failure) {
          UnsupportedResidenceFailure() => EmptyState(
            icon: QuoinIcons.alert,
            title: l10n.residenceUnsupportedTitle,
            body: l10n.residenceUnsupported,
            negative: true,
          ),
          StorageFailure() ||
          NetworkFailure() ||
          ImportFailure() ||
          SyncFailure() => EmptyState(
            icon: QuoinIcons.alert,
            title: l10n.portfolioLoadFailed,
            body: l10n.loadFailedBody,
            negative: true,
          ),
        },
      ),
    };
  }
}

String _end(List<String> names) =>
    names.isNotEmpty && names.last.endsWith('.') ? 'dot' : 'none';

List<Widget> valuationNotices(BuildContext context, PortfolioOverview o) {
  final l10n = AppLocalizations.of(context);
  final style = QuoinType.of(context).secondary
      .copyWith(color: QuoinColors.of(context).muted);
  return [
    if (o.unrated.isNotEmpty) ...[
      const SizedBox(height: QuoinSpace.s),
      Text(l10n.fxUnrated(o.unrated.join(', '), _end(o.unrated)), style: style),
    ],
    if (o.unconvertible.isNotEmpty) ...[
      const SizedBox(height: QuoinSpace.s),
      Text(
        l10n.fxUnconvertible(o.unconvertible.join(', '), _end(o.unconvertible)),
        style: style,
      ),
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
    void open() => context.push(Routes.instrument(h.instrumentId));
    final value = h.value.marketValue;
    final pnl = h.value.unrealizedPnL;
    if (value == null) {
      return PositionRow(
        name: h.name,
        detail: detail(h),
        value: format.money(h.position.costBasis),
        valueSuffix: l10n.positionCostSuffix,
        valueMuted: true,
        onTap: open,
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
      onTap: open,
      change: switch (format.gain(pnl!, h.unrealizedPnLPct)) {
        final gain => GainBadge(text: gain.text, sign: gain.sign),
      },
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
