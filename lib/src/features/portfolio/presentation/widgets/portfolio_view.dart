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
import 'package:quoin/src/ui/atoms/instrument_icon.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
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

List<Widget> unconvertibleNote(BuildContext context, PortfolioOverview o) {
  if (o.unconvertible.isEmpty) return const [];
  return [
    const SizedBox(height: QuoinSpace.m),
    Text(
      AppLocalizations.of(context)
          .fxUnconvertible(o.unconvertible.join(', '), _end(o.unconvertible)),
      style: QuoinType.of(context).secondary
          .copyWith(color: QuoinColors.of(context).muted),
    ),
  ];
}

String? valuationNotice(AppLocalizations l10n, PortfolioOverview o) =>
    switch (o) {
      _ when o.unconvertible.isNotEmpty => l10n.noticeOutside(
        o.unconvertible.length,
      ),
      _ when o.summary.unpricedCount > 0 => l10n.noticeUnpriced(
        o.summary.unpricedCount,
      ),
      _ => null,
    };

String categoryLabel(AppLocalizations l10n, String category) =>
    switch (ExposureKind.values.where((k) => k.code == category).firstOrNull) {
      ExposureKind.company => l10n.categoryCompany,
      ExposureKind.equityFund => l10n.categoryEquityFund,
      ExposureKind.bondFund => l10n.categoryBondFund,
      ExposureKind.commodity => l10n.categoryCommodity,
      ExposureKind.crypto => l10n.categoryCrypto,
      null => l10n.categoryOther,
    };

Widget instrumentIcon(Holding h) => switch (h.type) {
  'STOCK' => InstrumentIcon.circle(
    h.name.isEmpty ? '?' : h.name.characters.first.toUpperCase(),
  ),
  'CRYPTO' => const InstrumentIcon.coin(QuoinIcons.crypto),
  _ => InstrumentIcon.tile(switch (ExposureKind.values
      .where((k) => k.code == h.category)
      .firstOrNull) {
    ExposureKind.equityFund => QuoinIcons.equityFund,
    ExposureKind.bondFund => QuoinIcons.bondFund,
    ExposureKind.commodity => QuoinIcons.commodityFund,
    ExposureKind.crypto => QuoinIcons.crypto,
    ExposureKind.company || null => QuoinIcons.fund,
  }),
};

String quantityText(AppLocalizations l10n, QuoinFormat format, Holding h) {
  final quantity = h.position.quantity;
  final text = format.quantity(quantity);
  final count = quantity.compareTo(Dec.one) == 0 ? 'one' : 'other';
  return switch (h.type) {
    'STOCK' => l10n.positionShares(text, count),
    'ETF' || 'COMMODITY' => l10n.positionFundUnits(text, count),
    _ => l10n.positionUnits(text, count),
  };
}

Widget holdingRow(
  BuildContext context,
  Holding h, {
  required String detail,
  bool compact = false,
}) {
  final l10n = AppLocalizations.of(context);
  final format = QuoinFormat.of(context);
  final c = QuoinColors.of(context);
  void open() => context.push(Routes.instrument(h.instrumentId));
  final value = h.value.marketValue;
  if (value == null) {
    return PositionRow(
      leading: instrumentIcon(h),
      name: h.name,
      detail: detail,
      value: l10n.positionUnpriced,
      valueIsFigure: false,
      changePrefix: l10n.positionCostPrefix,
      change: format.money(h.position.costBasis),
      onTap: open,
    );
  }
  final pnl = h.value.unrealizedPnL!;
  final pct = h.unrealizedPnLPct;
  final gain = compact
      ? (
          text: pct == null ? '' : format.percent(pct, signed: true),
          sign: pnl.amount.sign,
        )
      : format.gainLine(pnl, pct);
  return PositionRow(
    leading: instrumentIcon(h),
    name: h.name,
    detail: detail,
    value: format.money(value),
    change: gain.text.isEmpty ? null : gain.text,
    changeColor: switch (gain.sign) {
      > 0 => c.positive,
      < 0 => c.negative,
      _ => c.muted,
    },
    onTap: open,
  );
}
