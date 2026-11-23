import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/pc_row.dart';
import 'package:quoin/src/features/sync/presentation/widgets/pc_sheet.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';
import 'package:quoin/src/ui/organisms/quoin_toast.dart';

class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(syncControllerProvider);
    final rows = switch (ref.watch(pairingsProvider).value) {
      null => const <SettingsRow>[],
      Ok(value: Pairings(pcs: [])) => [
        SettingsRow(
          icon: QuoinIcons.pair,
          label: l10n.syncPair,
          onTap: () => context.push(Routes.pair),
        ),
      ],
      Ok(value: final pairings) => [
        for (final pc in pairings.pcs)
          pcRow(
            context,
            pairing: pc,
            twin: pairings.twinOf(pc)?.pcName,
            running: status.running,
            searching: status.searching.contains(pc.sha256),
            failure: status.failures[pc.sha256],
            last: ref.watch(lastSyncProvider(pc.sha256)).value,
            onTap: () => _actions(
              context,
              ref,
              pc,
              pc.shared
                  ? SharedIdentityFailure(pairings.twinOf(pc)?.pcName ?? '')
                  : status.failures[pc.sha256],
              ref.read(lastSyncProvider(pc.sha256)).value,
            ),
          ),
        if (status.finishing)
          SettingsRow(icon: QuoinIcons.sync, label: l10n.syncPricesRunning)
        else if (status.followUp?.prices case Err())
          SettingsRow(icon: QuoinIcons.alert, label: l10n.syncPricesFailed),
        if (status.failure case final failure?)
          SettingsRow(
            icon: QuoinIcons.alert,
            label: syncFailureText(l10n, failure),
          ),
        SettingsRow(
          icon: QuoinIcons.sync,
          label: l10n.syncNow,
          onTap: () => context.push(Routes.sync),
        ),
        SettingsRow(
          icon: QuoinIcons.pair,
          label: l10n.syncAddPc,
          onTap: () => context.push(Routes.pair),
        ),
      ],
      Err(:final failure) => [
        SettingsRow(
          icon: QuoinIcons.alert,
          label: syncFailureText(l10n, failure),
        ),
      ],
    };
    if (rows.isEmpty) return const SizedBox.shrink();
    return SettingsSection(title: l10n.settingsSync, rows: rows);
  }

  Future<void> _actions(
    BuildContext context,
    WidgetRef ref,
    Pairing pc,
    Failure? failure,
    LastSync? last,
  ) => showPcSheet(
    context,
    pc: pc,
    failure: failure,
    last: last,
    onCheckAgain: () => _checkAgain(context, ref, pc),
    onSearch: () => refreshFromPc(context, ref, search: PcSearch.always),
    onRescan: () => context.push(Routes.pair),
    onPairAgain: () => context.push(Routes.repair),
    onUnpair: () => _unpair(context, ref, pc),
  );

  Future<void> _checkAgain(
    BuildContext context,
    WidgetRef ref,
    Pairing pc,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(pcIdentityProvider).checkAgain(pc.sha256);
    ref.read(syncControllerProvider.notifier).reset();
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      showQuoinToast(
        context,
        tone: QuoinToastTone.negative,
        title: l10n.syncCheckFailedTitle,
        body: syncFailureText(l10n, failure),
      );
    }
  }

  Future<void> _unpair(BuildContext context, WidgetRef ref, Pairing pc) async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.syncUnpairTitle(pc.pcName)),
        content: Text(l10n.syncUnpairBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.syncCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.syncUnpair),
          ),
        ],
      ),
    );
    if (sure != true) return;
    final result = await ref.read(unpairProvider)(pc.sha256);
    ref.read(syncControllerProvider.notifier).reset();
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      showQuoinToast(
        context,
        tone: QuoinToastTone.negative,
        title: l10n.syncUnpairFailedTitle,
        body: syncFailureText(l10n, failure),
      );
    }
  }
}
