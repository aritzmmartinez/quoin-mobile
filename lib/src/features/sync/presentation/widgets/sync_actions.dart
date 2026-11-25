import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/organisms/quoin_toast.dart';

Future<Pairings> _pairings(WidgetRef ref) async =>
    switch (await ref.read(pairingsProvider.future)) {
      Ok(:final value) => value,
      Err() => const Pairings(),
    };

Future<void> refreshFromPc(
  BuildContext context,
  WidgetRef ref, {
  PcSearch search = PcSearch.held,
}) async {
  if ((await _pairings(ref)).pcs.isEmpty) {
    ref.invalidate(ledgerProvider);
    return;
  }
  final result = await ref
      .read(syncControllerProvider.notifier)
      .sync(search: search);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  void failed(String detail) => showQuoinToast(
    context,
    tone: QuoinToastTone.negative,
    title: l10n.syncFailedTitle,
    body: detail,
  );
  final SyncPass pass;
  switch (result) {
    case Err(:final failure):
      return failed(syncFailureDetail(l10n, failure));
    case Ok(:final value):
      pass = value;
  }
  if (pass.waiting.isNotEmpty) {
    return showQuoinToast(
      context,
      tone: QuoinToastTone.neutral,
      title: l10n.syncReviewSnack,
      action: (
        label: l10n.syncReview,
        onPressed: () => context.push(Routes.sync),
      ),
    );
  }
  switch (passNotice(pass)) {
    case PassFailed(:final failure):
      return failed(syncFailureDetail(l10n, failure));
    case PcFailed(:final pc, :final failure, :final alone):
      final detail = l10n.syncPcFailure(
        pc.pcName,
        syncFailureText(l10n, failure),
      );
      if (alone) return failed(detail);
      showQuoinToast(
        context,
        tone: QuoinToastTone.neutral,
        title: l10n.syncSomePcFailedTitle,
        body: detail,
      );
    case null:
      break;
  }
  final followUp = await ref.read(syncControllerProvider.notifier).finishing;
  if (followUp == null || !context.mounted) return;
  switch (followUp.prices) {
    case Err():
      showQuoinToast(
        context,
        tone: QuoinToastTone.negative,
        title: l10n.syncPricesFailedTitle,
        body: l10n.syncPricesFailedBody,
      );
    case Ok(value: PricesOutcome(pending: [_, ...])):
      showQuoinToast(
        context,
        tone: QuoinToastTone.neutral,
        title: l10n.syncPricesPendingTitle,
        body: l10n.syncPricesPendingBody,
      );
    case _:
      break;
  }
}

sealed class PassNotice {
  const PassNotice();
}

/// No PC answered: a red toast.
final class PassFailed extends PassNotice {
  const PassFailed(this.failure);

  final Failure failure;
}

/// One PC failed; [alone] when no other synced, which makes it red.
final class PcFailed extends PassNotice {
  const PcFailed(this.pc, this.failure, {required this.alone});

  final Pairing pc;
  final Failure failure;
  final bool alone;
}

/// What a pull says about a pass. Red only when no PC synced; once one has,
/// a PC that is not on this network says nothing (Settings shows it) and one
/// that refused is told in neutral.
PassNotice? passNotice(SyncPass pass) {
  if (pass.noneAnswered) return PassFailed(pass.unanswered);
  final alone = !pass.anySynced;
  final failing = [
    ...pass.refused,
    if (alone)
      for (final pc in pass.pcs)
        if (!pc.pairing.shared && pc.result is Err) pc,
  ];
  return switch (failing.firstOrNull) {
    PcSync(:final pairing, result: Err(:final failure)) => PcFailed(
      pairing,
      failure,
      alone: alone,
    ),
    _ => null,
  };
}

Future<void> syncOnOpen(WidgetRef ref) async {
  final pairings = await _pairings(ref);
  if (pairings.pcs.any((pc) => pc.confirmed && !pc.shared)) {
    await ref.read(syncControllerProvider.notifier).sync(onlyConfirmed: true);
  }
  await _krakenAfterPc(ref);
}

/// Pull to refresh: the PCs first, then Kraken, so a PC that answers takes
/// its instruments back before Kraken plans them.
Future<void> refreshPrices(BuildContext context, WidgetRef ref) async {
  await refreshFromPc(context, ref);
  if (!context.mounted) return;
  final result = await _krakenAfterPc(ref);
  if (result is Err && context.mounted) {
    final l10n = AppLocalizations.of(context);
    showQuoinToast(
      context,
      tone: QuoinToastTone.negative,
      title: l10n.krakenFailedTitle,
      body: l10n.krakenFailedBody,
    );
  }
}

Future<Result<Object?>?> _krakenAfterPc(WidgetRef ref) async {
  await ref.read(syncControllerProvider.notifier).finishing;
  return ref.read(krakenPricesProvider.notifier).pull();
}
