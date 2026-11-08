import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/widgets/portfolio_view.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  Result<SyncOutcome>? _result;
  final Map<String, Resolution> _choices = {};
  var _confirmed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    setState(() => _result = null);
    final result = await ref
        .read(syncControllerProvider.notifier)
        .sync(resolutions: Map.of(_choices), confirm: _confirmed);
    if (!mounted) return;
    setState(() {
      _result = result;
      if (result case Ok(value: SyncConflicts(:final conflicts))) {
        final open = {for (final c in conflicts) conflictKey(c)};
        _choices.removeWhere((key, _) => !open.contains(key));
      }
    });
  }

  void _confirm() {
    _confirmed = true;
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pc = switch (ref.watch(pairingProvider).value) {
      Ok(:final value?) => value.pcName,
      _ => '',
    };
    final title = l10n.settingsSync;
    return switch (_result) {
      null => QuoinPage(
        title: title,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              const CircularProgressIndicator(),
              Text(l10n.syncRunning(pc), style: QuoinType.of(context).row),
            ],
          ),
        ),
      ),
      Err(:final failure) => QuoinPage(
        title: title,
        body: EmptyState(
          message: syncFailureDetail(l10n, failure),
          actionLabel: switch (failure) {
            PcUnreachableFailure() => l10n.syncRescan,
            CertificateMismatchFailure() ||
            PairingRevokedFailure() ||
            NotPairedFailure() => l10n.syncPairAgain,
            _ => l10n.syncNow,
          },
          onAction: needsPairing(failure)
              ? () => context.pushReplacement(Routes.pair)
              : _run,
        ),
      ),
      Ok(value: SyncPreview(:final toPhone, :final toPc)) => QuoinPage.list(
        title: title,
        children: [
          Text(l10n.syncPreviewIntro, style: QuoinType.of(context).row),
          sectionLabel(context, l10n.syncToPhone),
          _Counts(counts: toPhone),
          sectionLabel(context, l10n.syncToPc),
          _Counts(counts: toPc),
          const SizedBox(height: QuoinSpace.gutter),
          FilledButton(onPressed: _confirm, child: Text(l10n.syncConfirm)),
        ],
      ),
      Ok(value: SyncConflicts(:final conflicts, :final setAside)) =>
        QuoinPage.list(
          title: title,
          children: [
            Text(l10n.syncConflictsIntro, style: QuoinType.of(context).row),
            for (final conflict in conflicts) ...[
              const SizedBox(height: 12),
              _ConflictCard(
                conflict: conflict,
                choice: _choices[conflictKey(conflict)],
                onChanged: (choice) =>
                    setState(() => _choices[conflictKey(conflict)] = choice),
              ),
            ],
            ..._setAside(context, [for (final row in setAside) row.key]),
            const SizedBox(height: QuoinSpace.gutter),
            FilledButton(
              onPressed:
                  conflicts.every((c) => _choices.containsKey(conflictKey(c)))
                  ? _run
                  : null,
              child: Text(l10n.syncApply),
            ),
          ],
        ),
      Ok(value: final SyncDone done) => QuoinPage.list(
        title: title,
        children: _done(context, done),
      ),
    };
  }

  List<Widget> _done(BuildContext context, SyncDone done) {
    final l10n = AppLocalizations.of(context);
    final rates = {
      for (final outcome in done.effects)
        if (outcome case EffectFailed(effect: RatesEffect(:final currency)))
          currency,
      if (done.prices case Ok(:final value)) ...value.unavailableRates,
    }.toList()..sort();
    return [
      Text(l10n.syncDone, style: QuoinType.of(context).title),
      if (done.prices case Ok(value: PricesOutcome(pending: [_, ...])))
        _Notice(text: l10n.syncPricesPending),
      if (done.prices case Err()) _Notice(text: l10n.syncPricesFailed),
      if (rates.isNotEmpty)
        _Notice(text: l10n.syncRatesUnavailable(rates.join(', '))),
      sectionLabel(context, l10n.syncReceived),
      _Counts(counts: done.counts, empty: l10n.syncUpToDate),
      ..._setAside(context, done.setAside),
    ];
  }

  List<Widget> _setAside(BuildContext context, List<String> keys) {
    if (keys.isEmpty) return const [];
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    return [
      sectionLabel(context, l10n.syncSetAsideTitle),
      Text(
        l10n.syncSetAsideHint,
        style: type.secondary.copyWith(color: c.muted),
      ),
      const SizedBox(height: 8),
      QuoinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            for (final key in keys) Text(key, style: type.secondary.mono),
          ],
        ),
      ),
    ];
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.counts, this.empty});

  final PlanCounts counts;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final lines = [
      if (counts.ledger > 0) l10n.syncCountLedger(counts.ledger),
      if (counts.newInstruments + counts.changedInstruments case final n
          when n > 0)
        l10n.syncCountInstruments(n),
      if (counts.newTargets + counts.deletedTargets case final n when n > 0)
        l10n.syncCountTargets(n),
      if (counts.newHoldings + counts.replacedHoldings case final n when n > 0)
        l10n.syncCountHoldings(n),
      if (counts.newIdentities + counts.updatedIdentities case final n
          when n > 0)
        l10n.syncCountIdentities(n),
      if (counts.settings) l10n.syncCountSettings,
    ];
    return QuoinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (lines.isEmpty) Text(empty ?? l10n.syncNothing, style: type.row),
          for (final line in lines) Text(line, style: type.row),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.choice,
    required this.onChanged,
  });

  final Conflict conflict;
  final Resolution? choice;
  final ValueChanged<Resolution> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    String shown(Object? value) => value == null || value == ''
        ? l10n.syncEmptyValue
        : value is bool
        ? (value ? l10n.syncYes : l10n.syncNo)
        : '$value';
    final (title, subject, phone, pc) = switch (conflict) {
      FieldConflict(entity: 'settings', :final local, :final incoming) => (
        l10n.syncFieldResidence,
        null,
        shown(local),
        shown(incoming),
      ),
      FieldConflict(:final key, :final field, :final local, :final incoming) =>
        (_field(l10n, field), key, shown(local), shown(incoming)),
      TargetConflict() => (l10n.syncConflictTarget, null, null, null),
      TargetDayConflict(:final day) => (
        l10n.syncConflictTargetDay(day),
        null,
        null,
        null,
      ),
      HoldingsConflict(:final instrumentId) => (
        l10n.syncConflictHoldings(instrumentId),
        null,
        null,
        null,
      ),
    };
    return QuoinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(title, style: type.row.copyWith(fontWeight: FontWeight.w600)),
          if (subject != null)
            Text(subject, style: type.secondary.mono.copyWith(color: c.muted)),
          if (phone != null && pc != null) ...[
            Text(
              '${l10n.syncKeepPhone}: $phone',
              style: type.secondary.copyWith(color: c.body),
            ),
            Text(
              '${l10n.syncTakePc}: $pc',
              style: type.secondary.copyWith(color: c.body),
            ),
          ],
          QuoinSegmented<Resolution?>(
            segments: [
              (Resolution.keep, l10n.syncKeepPhone),
              (Resolution.take, l10n.syncTakePc),
            ],
            selected: choice,
            onChanged: (value) => onChanged(value!),
          ),
        ],
      ),
    );
  }

  static String _field(AppLocalizations l10n, String field) => switch (field) {
    'quoteSymbol' => l10n.syncFieldQuoteSymbol,
    'exposure' => l10n.syncFieldExposure,
    'ter' => l10n.syncFieldTer,
    'hedgedToBase' => l10n.syncFieldHedged,
    'thesis' => l10n.syncFieldThesis,
    _ => field,
  };
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: QuoinCard(child: Text(text, style: QuoinType.of(context).row)),
  );
}
