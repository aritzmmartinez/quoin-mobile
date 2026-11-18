import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/count_list.dart';
import 'package:quoin/src/ui/molecules/fold_section.dart';
import 'package:quoin/src/ui/molecules/stat_columns.dart';

enum SyncDirection { toPhone, toPc }

class SyncDetailView extends StatelessWidget {
  const SyncDetailView({
    super.key,
    required this.detail,
    this.direction,
    this.setAside = true,
  });

  final SyncDetail detail;
  final SyncDirection? direction;
  final bool setAside;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final d = detail;
    final setAside = this.setAside
        ? d.setAside
        : const Cut<SetAsideRow>.empty();
    Widget line(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: QuoinSpace.xxs),
      child: Text(text, style: type.secondary.copyWith(color: c.body)),
    );
    List<Widget> more(int count) => [
      if (count > 0) line(l10n.syncDetailMore(count)),
    ];

    final instruments = d.newInstruments.total + d.changedInstruments.total;
    Widget tags(Cut<String> cut) => Wrap(
      spacing: QuoinSpace.s,
      runSpacing: QuoinSpace.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final name in cut.items) _Tag(name),
        if (cut.more > 0)
          Text(
            l10n.syncDetailMore(cut.more),
            style: type.secondary.copyWith(color: c.muted),
          ),
      ],
    );
    List<Widget> namesFold(String title, Cut<String> cut) => [
      if (cut.total > 0)
        FoldSection(
          title: title,
          summary: '${cut.total}',
          children: [tags(cut)],
        ),
    ];
    final rows = [
      if (d.inKind > 0) CountEntry(l10n.syncInKind, '${d.inKind}'),
      if (d.residence)
        CountEntry(l10n.syncFieldResidence, l10n.syncResidenceChanged),
    ];
    final byType = _typeCounts(l10n, d.ledger);
    final folds = [
      if (byType.isNotEmpty)
        FoldSection(
          title: l10n.syncByType,
          summary: [...byType.take(2), if (byType.length > 2) '…'].join(' · '),
          children: [for (final text in byType) line(text)],
        ),
      if (d.newInstruments.total > 0)
        FoldSection(
          title: l10n.syncDetailNewInstruments,
          initiallyOpen: true,
          children: [tags(d.newInstruments)],
        ),
      if (d.changedInstruments.total > 0)
        FoldSection(
          title: l10n.syncDetailChangedInstruments,
          children: [
            for (final change in d.changedInstruments.items)
              line(
                '${change.name}: '
                '${[for (final f in change.fields) detailFieldLabel(l10n, f)].join(', ')}',
              ),
            ...more(d.changedInstruments.more),
          ],
        ),
      ...namesFold(l10n.syncDetailCompositions, d.compositions),
      ...namesFold(l10n.syncDetailNewTargets, d.newTargets),
      ...namesFold(l10n.syncDetailDeletedTargets, d.deletedTargets),
      if (d.resolved.total > 0)
        FoldSection(
          title: l10n.syncDetailResolved,
          summary: '${d.resolved.total}',
          children: [
            for (final r in d.resolved.items) line(_resolved(context, r)),
            ...more(d.resolved.more),
          ],
        ),
      if (setAside.total > 0)
        FoldSection(
          title: l10n.syncSetAsideTitle,
          summary: '${setAside.total}',
          children: [
            line(l10n.syncSetAsideHint),
            ...setAsideRows(context, setAside),
          ],
        ),
    ];

    final direction = this.direction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (direction != null)
          Padding(
            padding: const EdgeInsets.only(
              top: QuoinSpace.section,
              bottom: QuoinSpace.m,
            ),
            child: Semantics(
              header: true,
              child: Row(
                spacing: QuoinSpace.s,
                children: [
                  QuoinIcon(
                    switch (direction) {
                      SyncDirection.toPhone => QuoinIcons.toPhone,
                      SyncDirection.toPc => QuoinIcons.toPc,
                    },
                    size: QuoinIconSize.small,
                    color: c.muted,
                  ),
                  Expanded(
                    child: Text(switch (direction) {
                      SyncDirection.toPhone => l10n.syncToPhone,
                      SyncDirection.toPc => l10n.syncToPc,
                    }, style: type.secondary.copyWith(color: c.muted)),
                  ),
                ],
              ),
            ),
          ),
        if (d.writesNothing && folds.isEmpty)
          RuledLine(l10n.syncNothing)
        else ...[
          _Ruled(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: QuoinSpace.card),
              child: StatColumns.figures(
                stats: [
                  (
                    label: l10n.syncStatMovements(d.ledgerRows),
                    value: '${d.ledgerRows}',
                    sign: 0,
                  ),
                  (
                    label: l10n.syncStatInstruments(instruments),
                    value: '$instruments',
                    sign: 0,
                  ),
                  (
                    label: l10n.syncStatCompositions(d.compositions.total),
                    value: '${d.compositions.total}',
                    sign: 0,
                  ),
                ],
              ),
            ),
          ),
          if (rows.isNotEmpty) CountList(entries: rows, closed: false),
          ...folds,
          Divider(height: 1, thickness: 1, color: c.borderSubtle),
        ],
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
        QuoinFormat.of(context).day(CalendarDate.parse(r.subject)),
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

class RuledLine extends StatelessWidget {
  const RuledLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      padding: const EdgeInsets.symmetric(vertical: QuoinSpace.m),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.borderSubtle)),
      ),
      child: Text(
        text,
        style: QuoinType.of(context).row.copyWith(color: c.body),
      ),
    );
  }
}

class _Ruled extends StatelessWidget {
  const _Ruled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: QuoinColors.of(context).borderSubtle),
      ),
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: QuoinSpace.block),
      padding: const EdgeInsets.symmetric(
        horizontal: QuoinSpace.m,
        vertical: QuoinSpace.tight,
      ),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: c.border)),
      ),
      child: Text(
        text,
        style: QuoinType.of(context).secondary.copyWith(color: c.body),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.only(top: QuoinSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: QuoinSpace.xs,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.syncSetAsideTitle, style: type.rowStrong),
          ),
          Text(
            l10n.syncSetAsideHint,
            style: type.secondary.copyWith(color: c.muted),
          ),
          ...setAsideRows(context, rows),
        ],
      ),
    );
  }
}

List<Widget> setAsideRows(BuildContext context, Cut<SetAsideRow> rows) {
  final l10n = AppLocalizations.of(context);
  final type = QuoinType.of(context);
  final c = QuoinColors.of(context);
  return [
    for (final row in rows.items)
      MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: QuoinSpace.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: QuoinSpace.xxs,
            children: [
              Text(
                [ledgerTypeLabel(l10n, row.type), ?row.instrument].join(' · '),
                style: type.row,
              ),
              Text(
                [
                  _instantDay(context, row.ts),
                  l10n.syncSetAsideDiffers(
                    {for (final f in row.fields) _column(l10n, f)}.join(', '),
                  ),
                ].join(' · '),
                style: type.secondary.tabular.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
      ),
    if (rows.more > 0)
      Text(
        l10n.syncDetailMore(rows.more),
        style: type.secondary.copyWith(color: c.muted),
      ),
  ];
}

List<Widget> syncDetailSections(
  BuildContext context, {
  required SyncDetail toPhone,
  required SyncDetail toPc,
}) {
  final l10n = AppLocalizations.of(context);
  final upToDate = toPhone.writesNothing && toPc.writesNothing;
  return [
    if (upToDate && toPhone.setAside.total == 0)
      RuledLine(l10n.syncUpToDate)
    else ...[
      SyncDetailView(detail: toPhone, direction: SyncDirection.toPhone),
      SyncDetailView(
        detail: toPc,
        direction: SyncDirection.toPc,
        setAside: false,
      ),
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

List<String> _typeCounts(AppLocalizations l10n, Map<String, int> ledger) {
  final known = <String, String Function(int)>{
    'BUY': l10n.syncTypeBuys,
    'SELL': l10n.syncTypeSells,
    'DIVIDEND': l10n.syncTypeDividends,
    'DEPOSIT': l10n.syncTypeDeposits,
    'WITHDRAWAL': l10n.syncTypeWithdrawals,
    'INTEREST': l10n.syncTypeInterest,
  };
  final other = ledger.entries
      .where((e) => !known.containsKey(e.key))
      .fold(0, (n, e) => n + e.value);
  return [
    for (final MapEntry(:key, value: words) in known.entries)
      if (ledger[key] case final count? when count > 0) words(count),
    if (other > 0) l10n.syncTypeOther(other),
  ];
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

/// This view has no residence, so a row's day is read on the phone's clock.
String _instantDay(BuildContext context, String ts) {
  final at = DateTime.parse(ts).toLocal();
  return QuoinFormat.of(context).day(CalendarDate(at.year, at.month, at.day));
}
