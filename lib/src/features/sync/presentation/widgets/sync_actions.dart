import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';

Future<Pairings> _pairings(WidgetRef ref) async =>
    switch (await ref.read(pairingsProvider.future)) {
      Ok(:final value) => value,
      Err() => const Pairings(),
    };

Future<void> refreshFromPc(BuildContext context, WidgetRef ref) async {
  if ((await _pairings(ref)).pcs.isEmpty) {
    ref.invalidate(ledgerProvider);
    return;
  }
  final result = await ref.read(syncControllerProvider.notifier).sync();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  void say(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text), action: action));
  final SyncPass pass;
  switch (result) {
    case Err(:final failure):
      return say(syncFailureDetail(l10n, failure));
    case Ok(:final value):
      pass = value;
  }
  if (pass.waiting.isNotEmpty) {
    return say(
      l10n.syncReviewSnack,
      action: SnackBarAction(
        label: l10n.syncReview,
        onPressed: () => context.push(Routes.sync),
      ),
    );
  }
  if (pass.noneAnswered) {
    return say(syncFailureDetail(l10n, const PcUnreachableFailure()));
  }
  for (final pc in pass.pcs) {
    if (pc.pairing.shared) continue;
    if (pc.result case Err(:final failure)) {
      return say(
        l10n.syncPcFailure(pc.pairing.pcName, syncFailureText(l10n, failure)),
      );
    }
  }
  final followUp = await ref.read(syncControllerProvider.notifier).finishing;
  if (followUp == null || !context.mounted) return;
  switch (followUp.prices) {
    case Err():
      say(l10n.syncPricesFailed);
    case Ok(value: PricesOutcome(pending: [_, ...])):
      say(l10n.syncPricesPending);
    case _:
      break;
  }
}

Future<void> syncOnOpen(WidgetRef ref) async {
  final pairings = await _pairings(ref);
  if (pairings.pcs.any((pc) => pc.confirmed && !pc.shared)) {
    await ref.read(syncControllerProvider.notifier).sync(onlyConfirmed: true);
  }
}
