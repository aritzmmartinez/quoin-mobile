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
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

/// The wizard's progress: one segment per step, the done ones in accent.
class ImportProgress extends StatelessWidget {
  const ImportProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return Semantics(
      label: AppLocalizations.of(context).quoinStepOf(step, total),
      child: Row(
        spacing: 6,
        children: [
          for (var i = 1; i <= total; i += 1)
            Expanded(
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                height: 4,
                decoration: ShapeDecoration(
                  color: i <= step ? c.accent : c.border,
                  shape: const StadiumBorder(),
                ),
              ),
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
        for (final (letter, name, how) in [
          ('T', l10n.brokerTradeRepublic, l10n.importHelpTradeRepublic),
          ('K', l10n.brokerKraken, l10n.importHelpKraken),
        ])
          QuoinCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                _LetterTile(letter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              spacing: 8,
              children: [
                QuoinIcon(QuoinIcons.upload, size: 24, color: c.accent),
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
              spacing: 12,
              children: [
                QuoinIcon(QuoinIcons.csvFile, size: 22, color: c.accent),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
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
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        spacing: 16,
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

/// Step 3: what the import adds, what it skips and why, what it noticed and
/// which rows it could not read.
class ImportReviewStep extends StatefulWidget {
  const ImportReviewStep({super.key, required this.preview});

  final ImportPreview preview;

  @override
  State<ImportReviewStep> createState() => _ImportReviewStepState();
}

class _ImportReviewStepState extends State<ImportReviewStep> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final format = QuoinFormat.of(context);
    final preview = widget.preview;
    final batch = preview.batch;
    final names = {for (final i in batch.instruments) i.id: i.name};
    String date(String text) => switch (DateTime.tryParse(text)) {
      final ts? => format.date(ts, preview.zone),
      null => text,
    };
    final warnings =
        batch.discarded.values.fold(0, (sum, n) => sum + n) +
        batch.noticed.values.fold(0, (sum, rows) => sum + rows.length) +
        batch.errors.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: QuoinSpace.row,
      children: [
        _StepTitle(l10n.importReviewTitle),
        Row(
          spacing: QuoinSpace.row,
          children: [
            _Count('${preview.imported}', l10n.importNew, color: c.text),
            _Count(
              '${preview.duplicates}',
              l10n.importExisting,
              color: c.muted,
            ),
            _Count('$warnings', l10n.importWarnings, color: c.text),
          ],
        ),
        if (preview.duplicates > 0)
          Text(
            l10n.importExistingSkipped,
            style: type.secondary.copyWith(color: c.muted),
          ),
        if (preview.ratesUnavailable.isNotEmpty)
          Text(
            l10n.importRatesUnavailable(preview.ratesUnavailable.join(', ')),
            style: type.secondary.copyWith(color: c.body),
          ),
        for (final (:currency, :day) in preview.rateConflicts)
          Text(
            l10n.importRateConflict(
              currency,
              format.day(CalendarDate.parse(day)),
            ),
            style: type.secondary.copyWith(color: c.body),
          ),
        if (batch.events.isNotEmpty)
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.all(QuoinSpace.card),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(l10n.importSeeDetail, style: type.row),
                        ),
                        Text(
                          l10n.importDetailCount(batch.events.length),
                          style: type.secondary.mono.copyWith(color: c.muted),
                        ),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                          child: QuoinIcon(
                            QuoinIcons.chevronDown,
                            size: 16,
                            color: c.faint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_open)
                  for (final event in batch.events)
                    _DetailRow(
                      title:
                          names[event.instrumentId] ?? _typeLabel(l10n, event),
                      subtitle:
                          '${format.date(event.ts, preview.zone)} · ${_typeLabel(l10n, event)}',
                      amount: _amount(format, event),
                    ),
              ],
            ),
          ),
        if (batch.errors.isNotEmpty)
          _Group(
            title: l10n.importRowErrors,
            count: batch.errors.length,
            help: l10n.importRowErrorsHelp,
            rows: [
              for (final RowError(:row, :reason) in batch.errors)
                _DetailRow(
                  title:
                      row.externalId ?? l10n.importRowNumber(row.position ?? 0),
                  subtitle: [
                    if (row.date case final text?) date(text),
                    ?row.type,
                    rowErrorLabel(l10n, reason.code),
                  ].join(' · '),
                ),
            ],
          ),
        for (final MapEntry(key: reason, value: count)
            in batch.discarded.entries)
          _Group(
            title: _discardLabel(l10n, reason),
            count: count,
            help: _discardHelp(l10n, reason),
            warning: _affectsPosition(reason, batch.discardedDetails[reason])
                ? l10n.importPositionWarning
                : null,
            rows: [
              for (final detail
                  in batch.discardedDetails[reason] ?? const <DiscardDetail>[])
                _DetailRow(
                  title: detail.instrument ?? detail.type,
                  subtitle: [
                    date(detail.date),
                    detail.type,
                    ?detail.subtype,
                    if (detail.unpriced case final ids? when ids.isNotEmpty)
                      l10n.importUnpriced(ids.join(', ')),
                  ].join(' · '),
                ),
            ],
          ),
        for (final MapEntry(key: reason, value: details)
            in batch.noticed.entries)
          _Group(
            title: _noticeLabel(l10n, reason),
            count: details.length,
            help: _noticeHelp(l10n, reason),
            rows: [
              for (final detail in details)
                _DetailRow(
                  title: detail.instrument ?? detail.type,
                  subtitle: [
                    date(detail.date),
                    detail.type,
                    ?detail.subtype,
                  ].join(' · '),
                ),
            ],
          ),
      ],
    );
  }

  static bool _affectsPosition(
    DiscardReason reason,
    List<DiscardDetail>? details,
  ) {
    if (details == null || details.isEmpty) return reason.affectsPosition;
    return details.any((d) => d.affectsPosition ?? reason.affectsPosition);
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

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.count,
    required this.rows,
    this.help,
    this.warning,
  });

  final String title;
  final int count;
  final List<Widget> rows;
  final String? help;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return QuoinCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(QuoinSpace.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    QuoinIcon(QuoinIcons.alert, size: 16, color: c.muted),
                    Expanded(child: Text(title, style: type.row)),
                    Text(
                      '$count',
                      style: type.secondary.mono.copyWith(color: c.muted),
                    ),
                  ],
                ),
                if (help case final text?)
                  Text(text, style: type.small.copyWith(color: c.muted)),
                if (warning case final text?)
                  Text(text, style: type.small.copyWith(color: c.body)),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

/// Step 4: done.
class ImportDoneStep extends StatelessWidget {
  const ImportDoneStep({super.key, required this.imported});

  final int imported;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        spacing: 12,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: c.positive.withValues(alpha: 0.12),
              shape: const CircleBorder(),
            ),
            child: QuoinIcon(QuoinIcons.check, size: 32, color: c.positive),
          ),
          Text(
            l10n.importDoneTitle,
            textAlign: TextAlign.center,
            style: type.title,
          ),
          Text(
            l10n.importDoneBody(imported),
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
      icon: QuoinIcon(QuoinIcons.alert, size: 36, color: c.negative),
      title: Text(l10n.importErrorTitle, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
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
      DiscardReason.unsupported => l10n.warningUnsupported,
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

class _LetterTile extends StatelessWidget {
  const _LetterTile(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: c.accent.withValues(alpha: 0.15),
          shape: const CircleBorder(),
        ),
        child: Text(
          letter,
          style: QuoinType.of(context).row.copyWith(color: c.accent),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.figure, this.label, {required this.color});

  final String figure;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Expanded(
      child: QuoinCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          spacing: 4,
          children: [
            // Scaling exception: a row figure shrinks to one line.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                figure,
                maxLines: 1,
                style: type.title.mono.copyWith(color: color),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: type.small.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.subtitle, this.amount});

  final String title;
  final String subtitle;
  final String? amount;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QuoinSpace.card,
          vertical: QuoinSpace.row,
        ),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: type.control),
                  Text(subtitle, style: type.small.copyWith(color: c.muted)),
                ],
              ),
            ),
            if (amount != null)
              // Scaling exception: a row figure shrinks to one line.
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount!,
                      maxLines: 1,
                      style: type.control.mono.copyWith(color: c.text),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
