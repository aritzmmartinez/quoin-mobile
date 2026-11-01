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

/// Step 3: what the import adds, what it skips and what it warns about.
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
    final warnings = <String, List<ImportWarning>>{};
    for (final warning in batch.warnings) {
      warnings.putIfAbsent(warning.reason, () => []).add(warning);
    }

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
            _Count(
              '${batch.warnings.length}',
              l10n.importWarnings,
              color: c.text,
            ),
          ],
        ),
        if (preview.duplicates > 0)
          Text(
            l10n.importExistingSkipped,
            style: type.secondary.copyWith(color: c.muted),
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
        for (final MapEntry(key: reason, value: rows) in warnings.entries)
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(QuoinSpace.card),
                  child: Row(
                    spacing: 8,
                    children: [
                      QuoinIcon(QuoinIcons.alert, size: 16, color: c.muted),
                      Expanded(
                        child: Text(
                          _reasonLabel(l10n, reason),
                          style: type.row,
                        ),
                      ),
                      Text(
                        '${rows.length}',
                        style: type.secondary.mono.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                for (final row in rows)
                  _DetailRow(
                    title: row.instrument ?? row.type,
                    subtitle: [
                      format.date(row.ts, preview.zone),
                      row.type,
                      ?row.subtype,
                    ].join(' · '),
                  ),
              ],
            ),
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
/// [zone] is the preview's, when there is one: only a failure raised from
/// the review carries a date.
Future<bool> showImportFailure(
  BuildContext context,
  Failure failure, {
  String? zone,
}) async {
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
              failureText(context, failure, zone: zone),
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

String failureText(BuildContext context, Failure failure, {String? zone}) {
  final l10n = AppLocalizations.of(context);
  return switch (failure) {
    StorageFailure() => l10n.importStorageFailed,
    NetworkFailure() => l10n.importNetworkFailed,
    UnreadableFileFailure() => l10n.importUnreadable,
    InvalidEncodingFailure() => l10n.importInvalidEncoding,
    UnparseableCsvFailure() => l10n.importUnparseable,
    UnknownBrokerFailure() => l10n.importUnknownBroker,
    UnsupportedFormatFailure() => l10n.importUnsupported,
    InvalidLedgerEventFailure(:final ts, :final type, :final currency) =>
      l10n.importInvalidEvent(
        type,
        QuoinFormat.of(context).date(ts, zone ?? 'UTC'),
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

String _reasonLabel(AppLocalizations l10n, String reason) => switch (reason) {
  'swap-unpriced' => l10n.warningSwapUnpriced,
  'crypto-transfer' => l10n.warningCryptoTransfer,
  'reward-unpriced' => l10n.warningRewardUnpriced,
  'fx-unavailable' => l10n.warningFxUnavailable,
  'invalid-crypto-code' => l10n.warningInvalidCryptoCode,
  'earn-return-unverified' => l10n.warningEarnReturnUnverified,
  'internal-move' => l10n.warningInternalMove,
  'card-spending' => l10n.warningCardSpending,
  'saveback-unpaired' => l10n.warningSavebackUnpaired,
  'unsupported' => l10n.warningUnsupported,
  'account-transfer' => l10n.warningAccountTransfer,
  'internal-booked-as-reward' => l10n.warningInternalBookedAsReward,
  _ => l10n.warningOther,
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
