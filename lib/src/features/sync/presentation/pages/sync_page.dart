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
  Result<SyncPass>? _result;
  final Map<String, Map<String, Resolution>> _choices = {};
  final Set<String> _confirmed = {};
  var _waitingAtMost = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    setState(() => _result = null);
    final result = await ref
        .read(syncControllerProvider.notifier)
        .sync(
          resolutions: {
            for (final MapEntry(:key, :value) in _choices.entries)
              if (value.isNotEmpty) key: Map.of(value),
          },
          confirm: Set.of(_confirmed),
        );
    if (!mounted) return;
    setState(() {
      _result = result;
      if (result case Ok(value: final pass)) {
        final waiting = pass.waiting.length;
        if (waiting > _waitingAtMost) _waitingAtMost = waiting;
        for (final pc in pass.pcs) {
          final open = switch (pc.result) {
            Ok(value: SyncConflicts(:final conflicts)) => {
              for (final c in conflicts) conflictKey(c),
            },
            _ => const <String>{},
          };
          _choices[pc.pairing.sha256]?.removeWhere(
            (key, _) => !open.contains(key),
          );
        }
      }
    });
  }

  Future<void> _answer(
    String sha256,
    SyncSameIdentity question, {
    required bool samePc,
  }) async {
    setState(() => _result = null);
    final answered = await ref
        .read(pcIdentityProvider)
        .resolve(sha256, question, samePc: samePc);
    if (!mounted) return;
    if (answered case Err(:final failure)) {
      return setState(() => _result = Err(failure));
    }
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.syncRunning(_names()),
                textAlign: TextAlign.center,
                style: QuoinType.of(context).row,
              ),
            ],
          ),
        ),
      ),
      Err(:final failure) => _failed(context, failure),
      Ok(value: final pass) when pass.noneAnswered => _failed(
        context,
        const PcUnreachableFailure(),
      ),
      Ok(value: final pass) => switch (pass.waiting) {
        [final pc, ...] => QuoinPage.list(
          title: title,
          children: [
            if (_waitingAtMost > 1)
              sectionLabel(
                context,
                l10n.syncPcStep(
                  pc.pairing.pcName,
                  '${_waitingAtMost - pass.waiting.length + 1}',
                  '$_waitingAtMost',
                ),
              )
            else
              sectionLabel(context, pc.pairing.pcName),
            ..._waiting(context, pc),
          ],
        ),
        [] => QuoinPage.list(title: title, children: _done(context, pass)),
      },
    };
  }

  String _names() => switch (ref.read(pairingsProvider).value) {
    Ok(:final value) => [
      for (final pc in value.pcs)
        if (!pc.shared) pc.pcName,
    ].join(', '),
    _ => '',
  };

  Widget _failed(BuildContext context, Failure failure) {
    final l10n = AppLocalizations.of(context);
    return QuoinPage(
      title: l10n.settingsSync,
      body: EmptyState(
        message: syncFailureDetail(l10n, failure),
        actionLabel: switch (failure) {
          PcUnreachableFailure() => l10n.syncRescan,
          NotPairedFailure() => l10n.syncPair,
          _ => l10n.syncNow,
        },
        onAction: switch (failure) {
          PcUnreachableFailure() ||
          NotPairedFailure() => () => context.pushReplacement(Routes.pair),
          _ => _run,
        },
      ),
    );
  }

  List<Widget> _waiting(BuildContext context, PcSync pc) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final sha = pc.pairing.sha256;
    return switch (pc.result) {
      Ok(value: SyncPreview(:final toPhone, :final toPc)) => [
        Text(l10n.syncPreviewIntro, style: type.row),
        sectionLabel(context, l10n.syncToPhone),
        _Counts(counts: toPhone),
        sectionLabel(context, l10n.syncToPc),
        _Counts(counts: toPc),
        const SizedBox(height: QuoinSpace.gutter),
        FilledButton(
          onPressed: () {
            _confirmed.add(sha);
            _run();
          },
          child: Text(l10n.syncConfirm),
        ),
      ],
      Ok(value: SyncConflicts(:final conflicts, :final setAside)) => [
        Text(l10n.syncConflictsIntro, style: type.row),
        for (final conflict in conflicts) ...[
          const SizedBox(height: 12),
          _ConflictCard(
            conflict: conflict,
            choice: _choices[sha]?[conflictKey(conflict)],
            onChanged: (choice) => setState(
              () => (_choices[sha] ??= {})[conflictKey(conflict)] = choice,
            ),
          ),
        ],
        ..._setAside(context, [for (final row in setAside) row.key]),
        const SizedBox(height: QuoinSpace.gutter),
        FilledButton(
          onPressed:
              conflicts.every(
                (c) => _choices[sha]?.containsKey(conflictKey(c)) ?? false,
              )
              ? _run
              : null,
          child: Text(l10n.syncApply),
        ),
      ],
      Ok(value: final SyncSameIdentity question) => [
        Text(
          l10n.syncSameIdentityTitle(pc.pairing.pcName, question.other.pcName),
          style: type.row,
        ),
        const SizedBox(height: 12),
        Text(l10n.syncSameIdentityQuestion, style: type.row),
        const SizedBox(height: QuoinSpace.gutter),
        FilledButton(
          onPressed: () => _answer(sha, question, samePc: true),
          child: Text(l10n.syncSamePc),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _answer(sha, question, samePc: false),
          child: Text(l10n.syncOtherPc),
        ),
      ],
      _ => const [],
    };
  }

  List<Widget> _done(BuildContext context, SyncPass pass) {
    final l10n = AppLocalizations.of(context);
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    final status = ref.watch(syncControllerProvider);
    final followUp = status.finishing ? null : status.followUp;
    final prices = followUp?.prices;
    final rates = {
      for (final outcome in followUp?.effects ?? const <EffectOutcome>[])
        if (outcome case EffectFailed(effect: RatesEffect(:final currency)))
          currency,
      if (prices case Ok(:final value)) ...value.unavailableRates,
    }.toList()..sort();
    return [
      if (pass.pcs.any((pc) => pc.done)) Text(l10n.syncDone, style: type.title),
      if (status.finishing) _Notice(text: l10n.syncPricesRunning),
      if (prices case Ok(value: PricesOutcome(pending: [_, ...])))
        _Notice(text: l10n.syncPricesPending),
      if (prices case Err()) _Notice(text: l10n.syncPricesFailed),
      if (rates.isNotEmpty)
        _Notice(text: l10n.syncRatesUnavailable(rates.join(', '))),
      for (final pc in pass.pcs) ...[
        sectionLabel(context, pc.pairing.pcName),
        ...switch (pc.result) {
          Ok(value: SyncDone(:final counts, :final setAside)) => [
            Text(
              l10n.syncReceived,
              style: type.secondary.copyWith(color: c.muted),
            ),
            const SizedBox(height: 8),
            _Counts(counts: counts, empty: l10n.syncUpToDate),
            ..._setAside(context, setAside),
          ],
          Err(:final failure) => [
            QuoinCard(
              child: Text(syncFailureDetail(l10n, failure), style: type.row),
            ),
          ],
          Ok() => const <Widget>[],
        },
      ],
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
