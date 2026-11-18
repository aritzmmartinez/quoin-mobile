import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/l10n/quoin_format.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/ui/atoms/quoin_avatar.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';
import 'package:quoin/src/ui/molecules/count_list.dart';
import 'package:quoin/src/ui/molecules/fold_section.dart';

class ImportProgress extends StatelessWidget {
  const ImportProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final label = AppLocalizations.of(context).quoinStepOf(step, total);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        spacing: QuoinSpace.m,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(QuoinSpace.xxs),
              child: SizedBox(
                height: QuoinSpace.xs,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: c.border)),
                    AnimatedFractionallySizedBox(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      widthFactor: step / total,
                      heightFactor: 1,
                      alignment: AlignmentDirectional.centerStart,
                      child: ColoredBox(color: c.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            label,
            style: QuoinType.of(context).secondary.tabular
                .copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}

/// Step 1: how to export from each broker. There is no picker: the header
/// says which broker a file comes from.
class ImportHelpStep extends StatelessWidget {
  const ImportHelpStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: QuoinSpace.row,
      children: [
        _StepTitle(l10n.importHelpTitle),
        Text(
          l10n.importHelpBody,
          style: type.secondary.copyWith(color: c.muted),
        ),
        const SizedBox(height: QuoinSpace.row),
        for (final (name, how) in [
          (l10n.brokerTradeRepublic, l10n.importHelpTradeRepublic),
          (l10n.brokerKraken, l10n.importHelpKraken),
        ])
          QuoinCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: QuoinSpace.m,
              children: [
                QuoinAvatar(name),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: QuoinSpace.xxs,
                    children: [
                      Text(name, style: type.row),
                      Text(how, style: type.secondary.copyWith(color: c.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Step 2: the file, or the area to pick one.
class ImportSelectStep extends StatelessWidget {
  const ImportSelectStep({
    super.key,
    required this.file,
    required this.onPick,
    required this.onClear,
  });

  final ImportFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final picked = file;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: QuoinSpace.gutter,
      children: [
        _StepTitle(l10n.importSelectTitle),
        if (picked == null)
          QuoinCard(
            onTap: onPick,
            padding: const EdgeInsets.symmetric(
              horizontal: QuoinSpace.card,
              vertical: QuoinSpace.block,
            ),
            child: Column(
              spacing: QuoinSpace.s,
              children: [
                QuoinIcon(
                  QuoinIcons.upload,
                  size: QuoinIconSize.large,
                  color: c.accent,
                ),
                Text(
                  l10n.importSelectAction,
                  textAlign: TextAlign.center,
                  style: type.row,
                ),
                Text(
                  l10n.importSelectHint,
                  textAlign: TextAlign.center,
                  style: type.secondary.copyWith(color: c.muted),
                ),
              ],
            ),
          )
        else
          QuoinCard(
            child: Row(
              spacing: QuoinSpace.m,
              children: [
                QuoinIcon(
                  QuoinIcons.csvFile,
                  size: QuoinIconSize.large,
                  color: c.accent,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: QuoinSpace.xxs,
                    children: [
                      Text(picked.name, style: type.row),
                      Text(
                        l10n.importFileSize(_kilobytes(picked.size, context)),
                        style: type.secondary.mono.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onClear, child: Text(l10n.importChange)),
              ],
            ),
          ),
      ],
    );
  }

  static String _kilobytes(int bytes, BuildContext context) => QuoinFormat.of(
    context,
  ).quantity(Dec.parse('$bytes').dividedBy(Dec.parse('1024')), maxDecimals: 1);
}

/// Step 3 while the file is read or the batch written.
class ImportBusyStep extends StatelessWidget {
  const ImportBusyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QuoinSpace.hero),
      child: Column(
        spacing: QuoinSpace.card,
        children: [
          CircularProgressIndicator(color: c.accent, strokeWidth: 2.5),
          Text(
            AppLocalizations.of(context).importProcessing,
            textAlign: TextAlign.center,
            style: QuoinType.of(context).secondary.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}

//// Step 3: what the import adds, what it leaves out and why, what it noticed
/// and which rows it could not read.
class ImportReviewStep extends StatelessWidget {
  const ImportReviewStep({super.key, required this.preview, this.fileName});

  final ImportPreview preview;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final format = QuoinFormat.of(context);
    final batch = preview.batch;
    final names = {for (final i in batch.instruments) i.id: i.name};
    String date(String text) => switch (DateTime.tryParse(text)) {
      final ts? => format.date(ts, preview.zone),
      null => text,
    };
    final counts = preview.counts;
    // Card payments are a count of their own, never a warning.
    final cards = batch.discarded[DiscardReason.cardSpending] ?? 0;
    final unsupported = batch.discarded[DiscardReason.unsupported] ?? 0;
    String typeOf(String type) => rowTypeLabel(l10n, preview.broker, type);
    List<String> sameOperation(List<(String?, String?)> rows) => [
      for (final (day, kind) in rows)
        [
          l10n.importSameOperation(kind == null ? '' : typeOf(kind)),
          if (day != null) date(day),
        ].join(' · '),
    ];
    List<Widget> detailRows(
      List<DiscardDetail> details, {
      bool alert = false,
    }) => [
      for (final detail in details)
        _IssueRow(
          alert: alert,
          title: detail.instrument ?? typeOf(detail.type),
          lines: [
            [
              if (detail.instrument != null) typeOf(detail.type),
              ?detail.subtype,
              date(detail.date),
            ].join(' · '),
            if (detail.unpriced case final ids? when ids.isNotEmpty)
              l10n.importUnpriced(ids.join(', ')),
          ],
          others: sameOperation([
            for (final other in detail.rows) (other.date, other.type),
          ]),
        ),
    ];

    final discards = [
      for (final MapEntry(key: reason, value: count) in batch.discarded.entries)
        if (reason != DiscardReason.cardSpending &&
            reason != DiscardReason.unsupported)
          (
            reason: reason,
            count: count,
            details: batch.discardedDetails[reason] ?? const <DiscardDetail>[],
          ),
    ];
    bool affects(DiscardReason reason, List<DiscardDetail> details) =>
        details.isEmpty
        ? reason.affectsPosition
        : details.any((d) => d.affectsPosition ?? reason.affectsPosition);
    final folded = <Widget>[
      for (final (:reason, :count, :details) in discards)
        if (!affects(reason, details))
          _IssueGroup(
            title: _discardLabel(l10n, reason),
            count: count,
            help: _discardHelp(l10n, reason),
            rows: detailRows(details),
          ),
      for (final MapEntry(key: reason, value: details) in batch.noticed.entries)
        _IssueGroup(
          title: _noticeLabel(l10n, reason),
          count: details.length,
          help: _noticeHelp(l10n, reason),
          rows: detailRows(details),
        ),
      for (final (:currency, :day) in preview.rateConflicts)
        _IssueGroup(
          help: l10n.importRateConflict(
            currency,
            format.day(CalendarDate.parse(day)),
          ),
          rows: const [],
        ),
    ];
    final file = [
      switch (preview.broker) {
        Broker.tradeRepublic => l10n.brokerTradeRepublic,
        Broker.kraken => l10n.brokerKraken,
      },
      ?fileName,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(file, style: type.secondary.copyWith(color: c.muted)),
        const SizedBox(height: QuoinSpace.tight),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${counts.imported}', style: type.display),
                const TextSpan(text: ' '),
                TextSpan(text: l10n.importNewHeadline(counts.imported)),
              ],
            ),
            style: type.title,
          ),
        ),
        if (preview.toWrite == 0)
          _Lead(switch (nothingToImport(
            total: batch.total,
            duplicates: counts.duplicates,
          )) {
            NothingToImport.alreadyStored => l10n.importNothingNew,
            NothingToImport.nothingToSave => l10n.importNothingToSave,
          })
        else if (counts.duplicates > 0 || cards > 0)
          _Lead(l10n.importRestKnown),
        const SizedBox(height: QuoinSpace.section),
        CountList(
          entries: [
            CountEntry(l10n.importNew, '${counts.imported}'),
            if (counts.completed > 0)
              CountEntry(
                l10n.importCompleted,
                '${counts.completed}',
                note: l10n.importCompletedHelp,
              ),
            CountEntry(
              l10n.importExisting,
              '${counts.duplicates}',
              muted: true,
            ),
            if (cards > 0)
              CountEntry(
                l10n.warningCardSpending,
                '$cards',
                note: l10n.importCardSpendingNote,
                muted: true,
              ),
            if (unsupported > 0)
              CountEntry(
                l10n.importUnsupportedTitle,
                '$unsupported',
                icon: QuoinIcons.alert,
              ),
          ],
        ),
        if (preview.ratesUnavailable.isNotEmpty)
          _IssueGroup(
            alert: true,
            help: l10n.importRatesUnavailable(
              preview.ratesUnavailable.join(', '),
            ),
            rows: const [],
          ),
        if (batch.errors.isNotEmpty)
          _IssueGroup(
            title: l10n.importRowErrors,
            count: batch.failed,
            help: l10n.importRowErrorsHelp,
            rows: [
              for (final RowError(:row, :reason, :rows) in batch.errors)
                _IssueRow(
                  alert: true,
                  title:
                      row.externalId ?? l10n.importRowNumber(row.position ?? 0),
                  lines: [
                    [
                      if (row.type case final code?) typeOf(code),
                      rowErrorLabel(l10n, reason.code),
                      if (row.date case final text?) date(text),
                    ].join(' · '),
                  ],
                  others: sameOperation([
                    for (final other in rows) (other.row.date, other.row.type),
                  ]),
                ),
            ],
          ),
        for (final (:reason, :count, :details) in discards)
          if (affects(reason, details))
            _IssueGroup(
              title: _discardLabel(l10n, reason),
              count: count,
              help: [
                ?_discardHelp(l10n, reason),
                l10n.importPositionWarning,
              ].join(' '),
              rows: detailRows(details, alert: true),
            ),
        if (unsupported > 0)
          _IssueGroup(
            title: l10n.importUnsupportedTitle,
            help: l10n.importUnsupportedNote,
            rows: [
              for (final detail
                  in batch.discardedDetails[DiscardReason.unsupported] ??
                      const <DiscardDetail>[])
                _IssueRow(
                  title:
                      detail.instrument ??
                      unsupportedTypeLabel(l10n, preview.broker, detail.type),
                  lines: [
                    [
                      if (detail.instrument != null)
                        unsupportedTypeLabel(l10n, preview.broker, detail.type),
                      date(detail.date),
                    ].join(' · '),
                  ],
                ),
            ],
          ),
        const SizedBox(height: QuoinSpace.section),
        if (folded.isNotEmpty)
          FoldSection(title: l10n.importOtherDiscards, children: folded),
        if (batch.events.isNotEmpty)
          FoldSection(
            title: l10n.importSeeDetail,
            summary: l10n.importDetailCount(batch.events.length),
            children: [
              for (final event in batch.events)
                _IssueRow(
                  title: names[event.instrumentId] ?? _typeLabel(l10n, event),
                  lines: [
                    [
                      if (names.containsKey(event.instrumentId))
                        _typeLabel(l10n, event),
                      format.date(event.ts, preview.zone),
                    ].join(' · '),
                  ],
                  amount: _amount(format, event),
                ),
            ],
          ),
      ],
    );
  }

  static String _amount(QuoinFormat format, LedgerEvent event) {
    final gross = switch (event) {
      TradeEvent(:final grossAmount) => grossAmount,
      DividendEvent(:final grossAmount) => grossAmount,
      CashEvent(:final grossAmount) => grossAmount,
    };
    return event.currency == baseCurrency
        ? format.money(gross)
        : '${format.quantity(gross.amount, minDecimals: 2, maxDecimals: 2)} '
              '${event.currency}';
  }
}

class _Lead extends StatelessWidget {
  const _Lead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: QuoinSpace.tight),
    child: Text(
      text,
      style: QuoinType.of(context).secondary
          .copyWith(color: QuoinColors.of(context).body),
    ),
  );
}

/// A kind of row the import leaves out or flags: its rows, then why.
class _IssueGroup extends StatelessWidget {
  const _IssueGroup({
    required this.rows,
    this.title,
    this.count,
    this.help,
    this.alert = false,
  });

  final String? title;
  final int? count;
  final List<Widget> rows;
  final String? help;

  /// Marks a group with no rows to carry the warning.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final title = this.title;
    final help = this.help;
    return Padding(
      padding: const EdgeInsets.only(top: QuoinSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: QuoinSpace.xs),
              child: Semantics(
                header: true,
                child: Text(
                  [title, if (count case final n? when n > 1) '$n'].join(' · '),
                  style: type.secondary.tabular.copyWith(color: c.muted),
                ),
              ),
            ),
          ...rows,
          if (help != null)
            Padding(
              padding: const EdgeInsets.only(top: QuoinSpace.tight),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: QuoinSpace.m,
                children: [
                  if (alert)
                    QuoinIcon(
                      QuoinIcons.alert,
                      size: QuoinIconSize.small,
                      color: c.muted,
                    ),
                  Expanded(
                    child: Text(
                      help,
                      style: type.secondary.copyWith(color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Step 4: done.
class ImportDoneStep extends StatelessWidget {
  const ImportDoneStep({super.key, required this.written});

  final int written;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QuoinSpace.hero),
      child: Column(
        spacing: QuoinSpace.m,
        children: [
          IconTile(icon: QuoinIcons.check, signal: c.positive),
          Text(
            l10n.importDoneTitle,
            textAlign: TextAlign.center,
            style: type.title,
          ),
          Text(
            l10n.importDoneBody(written),
            textAlign: TextAlign.center,
            style: type.secondary.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}

/// The modal for an import that stopped: what went wrong, and that nothing
/// was written. Resolves to true when the user wants to try again.
Future<bool> showImportFailure(BuildContext context, Failure failure) async {
  final l10n = AppLocalizations.of(context);
  final c = QuoinColors.of(context);
  final type = QuoinType.of(context);
  final retry = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      icon: QuoinIcon(
        QuoinIcons.alert,
        size: QuoinIconSize.feature,
        color: c.negative,
      ),
      title: Text(l10n.importErrorTitle, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: QuoinSpace.s,
          children: [
            Text(
              failureText(context, failure),
              textAlign: TextAlign.center,
              style: type.secondary.copyWith(color: c.body),
            ),
            Text(
              l10n.importErrorUntouched,
              textAlign: TextAlign.center,
              style: type.secondary.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.importCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(l10n.importRetry),
        ),
      ],
    ),
  );
  return retry ?? true;
}

String failureText(BuildContext context, Failure failure) {
  final l10n = AppLocalizations.of(context);
  return switch (failure) {
    StorageFailure() => l10n.importStorageFailed,
    UnsupportedResidenceFailure() => l10n.residenceUnsupported,
    NetworkFailure() => l10n.importNetworkFailed,
    UnreadableFileFailure() => l10n.importUnreadable,
    InvalidEncodingFailure() => l10n.importInvalidEncoding,
    UnparseableCsvFailure() => l10n.importUnparseable,
    UnknownBrokerFailure() => l10n.importUnknownBroker,
    MissingColumnFailure(:final column) => l10n.importMissingColumn(column),
    RowRejectedFailure(:final externalId, :final position, :final reason) =>
      l10n.importRowRejected(
        externalId ?? l10n.importRowNumber(position ?? 0),
        rowErrorLabel(l10n, reason),
      ),
    KrakenLegacyExportFailure() => l10n.importKrakenLegacy,
    KrakenBalanceMismatchFailure(:final asset, :final wallet, :final date) =>
      l10n.importKrakenBalanceMismatch(asset, wallet, date),
    InvalidLedgerEventFailure(:final day, :final type, :final currency) =>
      l10n.importInvalidEvent(
        type,
        QuoinFormat.of(context).day(CalendarDate.parse(day)),
        currency,
      ),
    SyncFailure() => l10n.importStorageFailed,
  };
}

String _typeLabel(AppLocalizations l10n, LedgerEvent event) => switch (event) {
  TradeEvent(type: TradeType.buy) => l10n.ledgerBuy,
  TradeEvent(type: TradeType.sell) => l10n.ledgerSell,
  DividendEvent() => l10n.ledgerDividend,
  CashEvent(type: CashType.deposit) => l10n.ledgerDeposit,
  CashEvent(type: CashType.withdrawal) => l10n.ledgerWithdrawal,
  CashEvent(type: CashType.interest) => l10n.ledgerInterest,
};

String rowTypeLabel(AppLocalizations l10n, Broker broker, String type) =>
    switch (brokerRowTypes[broker]?[type]) {
      RowType.interest => l10n.rowTypeInterest,
      RowType.deposit => l10n.rowTypeDeposit,
      RowType.withdrawal => l10n.rowTypeWithdrawal,
      RowType.transferIn => l10n.rowTypeTransferIn,
      RowType.transferOut => l10n.rowTypeTransferOut,
      RowType.transfer => l10n.rowTypeTransfer,
      RowType.directDebit => l10n.rowTypeDirectDebit,
      RowType.saveback => l10n.rowTypeSaveback,
      RowType.cardPayment => l10n.rowTypeCardPayment,
      RowType.cardPaymentAbroad => l10n.rowTypeCardPaymentAbroad,
      RowType.reward => l10n.rowTypeReward,
      RowType.earn => l10n.rowTypeEarn,
      RowType.earnWithdrawal => l10n.rowTypeEarnWithdrawal,
      RowType.spend => l10n.rowTypeSpend,
      RowType.receive => l10n.rowTypeReceive,
      RowType.trade => l10n.rowTypeTrade,
      null => switch (type) {
        'BUY' => l10n.ledgerBuy,
        'SELL' => l10n.ledgerSell,
        'DIVIDEND' => l10n.ledgerDividend,
        'DEPOSIT' => l10n.ledgerDeposit,
        'WITHDRAWAL' => l10n.ledgerWithdrawal,
        'INTEREST' => l10n.ledgerInterest,
        _ => type,
      },
    };

/// An unsupported row's type in words, never the broker's code.
String unsupportedTypeLabel(
  AppLocalizations l10n,
  Broker broker,
  String type,
) => switch ((broker, type)) {
  (Broker.tradeRepublic, 'INTERMEDIATE_SECURITIES_DISTRIBUTION') =>
    l10n.unsupportedRightsDistribution,
  (Broker.tradeRepublic, 'LIQUIDATION_DIVIDEND') =>
    l10n.unsupportedRightsDividend,
  (Broker.tradeRepublic, 'LIQUIDATION_PROCEEDS') =>
    l10n.unsupportedRightsProceeds,
  (Broker.tradeRepublic, 'PRIVATE_MARKET_BUY') =>
    l10n.unsupportedPrivateMarketBuy,
  _ => l10n.unsupportedOther,
};

/// A row error's label by its code; file errors on a row share them.
String rowErrorLabel(AppLocalizations l10n, String code) => switch (code) {
  'invalid-date' => l10n.rowErrorInvalidDate,
  'invalid-number' => l10n.rowErrorInvalidNumber,
  'missing-instrument' => l10n.rowErrorMissingInstrument,
  'wrong-field-count' => l10n.rowErrorWrongFieldCount,
  _ => l10n.rowErrorUnexpected,
};

String _discardLabel(AppLocalizations l10n, DiscardReason reason) =>
    switch (reason) {
      DiscardReason.swapUnpriced => l10n.warningSwapUnpriced,
      DiscardReason.cryptoTransfer => l10n.warningCryptoTransfer,
      DiscardReason.rewardUnpriced => l10n.warningRewardUnpriced,
      DiscardReason.fxUnavailable => l10n.warningFxUnavailable,
      DiscardReason.invalidCryptoCode => l10n.warningInvalidCryptoCode,
      DiscardReason.earnReturnUnverified => l10n.warningEarnReturnUnverified,
      DiscardReason.internalMove => l10n.warningInternalMove,
      DiscardReason.cardSpending => l10n.warningCardSpending,
      DiscardReason.savebackUnpaired => l10n.warningSavebackUnpaired,
      DiscardReason.unsupportedAssetClass => l10n.warningUnsupportedAssetClass,
      DiscardReason.unsupported => l10n.importUnsupportedTitle,
    };

String? _discardHelp(AppLocalizations l10n, DiscardReason reason) =>
    switch (reason) {
      DiscardReason.swapUnpriced => l10n.helpSwapUnpriced,
      DiscardReason.rewardUnpriced => l10n.helpRewardUnpriced,
      DiscardReason.fxUnavailable => l10n.helpFxUnavailable,
      DiscardReason.invalidCryptoCode => l10n.helpInvalidCryptoCode,
      DiscardReason.earnReturnUnverified => l10n.helpEarnReturnUnverified,
      DiscardReason.internalMove => l10n.helpInternalMove,
      DiscardReason.savebackUnpaired => l10n.helpSavebackUnpaired,
      DiscardReason.unsupportedAssetClass => l10n.helpUnsupportedAssetClass,
      DiscardReason.cryptoTransfer ||
      DiscardReason.cardSpending ||
      DiscardReason.unsupported => null,
    };

String _noticeLabel(AppLocalizations l10n, NoticeReason reason) =>
    switch (reason) {
      NoticeReason.accountTransfer => l10n.warningAccountTransfer,
      NoticeReason.internalBookedAsReward => l10n.warningInternalBookedAsReward,
    };

String _noticeHelp(AppLocalizations l10n, NoticeReason reason) =>
    switch (reason) {
      NoticeReason.accountTransfer => l10n.helpAccountTransfer,
      NoticeReason.internalBookedAsReward => l10n.helpInternalBookedAsReward,
    };

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: QuoinType.of(context).title),
  );
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    required this.title,
    required this.lines,
    this.alert = false,
    this.amount,
    this.others = const [],
  });

  final String title;
  final List<String> lines;
  final bool alert;
  final String? amount;

  /// The other rows of the same operation, nested under its main row.
  final List<String> others;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final amount = this.amount;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: QuoinSpace.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: QuoinSpace.m,
            children: [
              if (alert)
                Padding(
                  padding: const EdgeInsets.only(top: QuoinSpace.xxs),
                  child: QuoinIcon(
                    QuoinIcons.alert,
                    size: QuoinIconSize.small,
                    color: c.muted,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: QuoinSpace.xxs,
                  children: [
                    Text(title, style: type.row),
                    for (final line in lines)
                      Text(
                        line,
                        style: type.secondary.tabular.copyWith(color: c.muted),
                      ),
                    for (final other in others)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: QuoinSpace.m,
                        ),
                        child: Text(
                          other,
                          style: type.secondary.tabular.copyWith(
                            color: c.faint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (amount != null)
                // Scaling exception: a row figure shrinks to one line.
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        amount,
                        maxLines: 1,
                        style: type.row.mono.copyWith(color: c.text),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
