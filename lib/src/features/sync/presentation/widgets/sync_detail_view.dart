import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';

class SyncDetailView extends StatelessWidget {
  const SyncDetailView({
    super.key,
    required this.detail,
    this.empty,
    this.setAside = true,
  });

  final SyncDetail detail;
  final String? empty;
  final bool setAside;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    Widget title(String text) =>
        Text(text, style: type.row.copyWith(fontWeight: FontWeight.w600));
    Widget line(String text) =>
        Text(text, style: type.secondary.copyWith(color: c.body));
    List<Widget> names(String heading, Cut<String> cut) => [
      if (cut.total > 0) ...[
        title(heading),
        for (final name in cut.items) line(name),
        if (cut.more > 0) line(l10n.syncDetailMore(cut.more)),
      ],
    ];

    final d = detail;
    final parts = <Widget>[
      if (d.ledgerRows > 0) ...[
        title(l10n.syncCountLedger(d.ledgerRows)),
        for (final MapEntry(:key, :value) in _byLabel(l10n, d.ledger))
          line('$key: $value'),
      ],
      if (d.inKind > 0) title(l10n.syncDetailInKind(d.inKind)),
      ...names(l10n.syncDetailNewInstruments, d.newInstruments),
      if (d.changedInstruments.total > 0) ...[
        title(l10n.syncDetailChangedInstruments),
        for (final change in d.changedInstruments.items)
          line(
            '${change.name}: '
            '${[for (final f in change.fields) detailFieldLabel(l10n, f)].join(', ')}',
          ),
        if (d.changedInstruments.more > 0)
          line(l10n.syncDetailMore(d.changedInstruments.more)),
      ],
      ...names(l10n.syncDetailNewTargets, d.newTargets),
      ...names(l10n.syncDetailDeletedTargets, d.deletedTargets),
      ...names(l10n.syncDetailCompositions, d.compositions),
      if (d.residence) title(l10n.syncFieldResidence),
      if (d.resolved.total > 0) ...[
        title(l10n.syncDetailResolved),
        for (final r in d.resolved.items) line(_resolved(context, r)),
        if (d.resolved.more > 0) line(l10n.syncDetailMore(d.resolved.more)),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuoinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: parts.isEmpty
                ? [Text(empty ?? l10n.syncNothing, style: type.row)]
                : parts,
          ),
        ),
        if (setAside) SetAsideView(rows: d.setAside),
      ],
    );
  }

  String _resolved(BuildContext context, ResolvedConflict r) {
    final l10n = AppLocalizations.of(context);
    final what = switch (r.kind) {
      ResolvedKind.instrument => [
        r.subject,
        if (r.field case final field?) detailFieldLabel(l10n, field),
      ].join(' · '),
      ResolvedKind.residence => l10n.syncFieldResidence,
      ResolvedKind.target => '${l10n.syncConflictTarget} · ${r.subject}',
      ResolvedKind.targetDay => l10n.syncConflictTargetDay(
        _day(context, r.subject),
      ),
      ResolvedKind.holdings => l10n.syncConflictHoldings(r.subject),
    };
    final side = switch (r.resolution) {
      Resolution.keep => l10n.syncKeepPhone,
      Resolution.take => l10n.syncTakePc,
    };
    return '$what → $side';
  }
}

class SetAsideView extends StatelessWidget {
  const SetAsideView({super.key, required this.rows});

  final Cut<SetAsideRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.total == 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionLabel(context, l10n.syncSetAsideTitle),
        Text(
          l10n.syncSetAsideHint,
          style: type.secondary.copyWith(color: c.muted),
        ),
        const SizedBox(height: 8),
        QuoinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              for (final row in rows.items)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        _day(context, row.ts),
                        ledgerTypeLabel(l10n, row.type),
                        ?row.instrument,
                      ].join(' · '),
                      style: type.row,
                    ),
                    Text(
                      l10n.syncSetAsideDiffers(
                        {for (final f in row.fields) _column(l10n, f)}
                            .join(', '),
                      ),
                      style: type.secondary.copyWith(color: c.muted),
                    ),
                  ],
                ),
              if (rows.more > 0)
                Text(l10n.syncDetailMore(rows.more), style: type.secondary),
            ],
          ),
        ),
      ],
    );
  }
}

List<Widget> syncDetailSections(
  BuildContext context, {
  required SyncDetail toPhone,
  required SyncDetail toPc,
}) {
  final l10n = AppLocalizations.of(context);
  final upToDate = toPhone.writesNothing && toPc.writesNothing;
  return [
    if (upToDate)
      SyncDetailView(detail: toPhone, empty: l10n.syncUpToDate)
    else ...[
      sectionLabel(context, l10n.syncToPhone),
      SyncDetailView(detail: toPhone),
      sectionLabel(context, l10n.syncToPc),
      SyncDetailView(detail: toPc, setAside: false),
    ],
  ];
}

String syncDetailSummary(AppLocalizations l10n, LastSync last) {
  final both = [last.toPhone, last.toPc];
  int sum(int Function(SyncDetail) of) => both.fold(0, (n, d) => n + of(d));
  final rows = sum((d) => d.ledgerRows + d.inKind);
  final instruments = sum(
    (d) => d.newInstruments.total + d.changedInstruments.total,
  );
  final targets = sum((d) => d.newTargets.total + d.deletedTargets.total);
  final compositions = sum((d) => d.compositions.total);
  final resolved = sum((d) => d.resolved.total);
  final setAside = last.toPhone.setAside.total;
  final parts = [
    if (rows > 0) l10n.syncCountLedger(rows),
    if (instruments > 0) l10n.syncDetailInstruments(instruments),
    if (targets > 0) l10n.syncDetailTargets(targets),
    if (compositions > 0) l10n.syncDetailCompositionsCount(compositions),
    if (both.any((d) => d.residence)) l10n.syncDetailResidence,
    if (resolved > 0) l10n.syncDetailResolvedCount(resolved),
    if (setAside > 0) l10n.syncDetailSetAsideCount(setAside),
  ];
  return parts.isEmpty ? l10n.syncDetailNothing : parts.join(', ');
}

String detailFieldLabel(AppLocalizations l10n, DetailField field) =>
    switch (field) {
      DetailField.quoteSymbol => l10n.syncFieldQuoteSymbol,
      DetailField.exposure => l10n.syncFieldExposure,
      DetailField.ter => l10n.syncFieldTer,
      DetailField.hedgedToBase => l10n.syncFieldHedged,
      DetailField.thesis => l10n.syncFieldThesis,
      DetailField.assetClass => l10n.syncFieldAssetClass,
    };

String ledgerTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'BUY' => l10n.ledgerBuy,
  'SELL' => l10n.ledgerSell,
  'DIVIDEND' => l10n.ledgerDividend,
  'DEPOSIT' => l10n.ledgerDeposit,
  'WITHDRAWAL' => l10n.ledgerWithdrawal,
  'INTEREST' => l10n.ledgerInterest,
  _ => l10n.syncDetailOtherRows,
};

List<MapEntry<String, int>> _byLabel(
  AppLocalizations l10n,
  Map<String, int> ledger,
) {
  const order = [
    'BUY',
    'SELL',
    'DIVIDEND',
    'DEPOSIT',
    'WITHDRAWAL',
    'INTEREST',
  ];
  final out = {
    for (final type in order) ledgerTypeLabel(l10n, type): ?ledger[type],
  };
  final other = ledger.entries
      .where((e) => !order.contains(e.key))
      .fold(0, (n, e) => n + e.value);
  if (other > 0) out[l10n.syncDetailOtherRows] = other;
  return out.entries.toList();
}

String _column(AppLocalizations l10n, String column) => switch (column) {
  'ts' => l10n.syncColumnDate,
  'type' => l10n.syncColumnType,
  'instrumentId' => l10n.syncColumnInstrument,
  'quantity' => l10n.syncColumnQuantity,
  'price' => l10n.syncColumnPrice,
  'grossAmount' || 'originalAmount' => l10n.syncColumnAmount,
  'fees' => l10n.syncColumnFees,
  'taxWithheld' => l10n.syncColumnTax,
  'currency' || 'originalCurrency' => l10n.syncColumnCurrency,
  _ => l10n.syncColumnOther,
};

String _day(BuildContext context, String text) {
  final at = DateTime.tryParse(text);
  if (at == null) return text;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(at.toLocal());
}
