import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';

Future<Pairing?> _pairing(WidgetRef ref) async =>
    switch (await ref.read(pairingProvider.future)) {
      Ok(:final value) => value,
      Err() => null,
    };

Future<void> refreshFromPc(BuildContext context, WidgetRef ref) async {
  if (await _pairing(ref) == null) {
    ref.invalidate(ledgerProvider);
    return;
  }
  final result = await ref.read(syncControllerProvider.notifier).sync();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  void say(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text), action: action));
  switch (result) {
    case Ok(value: SyncDone(prices: Err())):
      say(l10n.syncPricesFailed);
    case Ok(value: SyncDone(prices: Ok(value: PricesOutcome(:final pending))))
        when pending.isNotEmpty:
      say(l10n.syncPricesPending);
    case Ok(value: SyncDone()):
      break;
    case Ok(value: SyncPreview() || SyncConflicts()):
      say(
        l10n.syncReviewSnack,
        action: SnackBarAction(
          label: l10n.syncReview,
          onPressed: () => context.push(Routes.sync),
        ),
      );
    case Err(:final failure):
      say(syncFailureDetail(l10n, failure));
  }
}

Future<void> syncOnOpen(WidgetRef ref) async {
  if (await _pairing(ref) case Pairing(confirmed: true)) {
    await ref.read(syncControllerProvider.notifier).sync();
  }
}
