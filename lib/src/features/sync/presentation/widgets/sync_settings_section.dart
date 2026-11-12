import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/pc_row.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';

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
            failure: status.failures[pc.sha256],
            onTap: () => _actions(
              context,
              ref,
              pc,
              pc.shared
                  ? SharedIdentityFailure(pairings.twinOf(pc)?.pcName ?? '')
                  : status.failures[pc.sha256],
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
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<VoidCallback>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheet) {
        void pick(VoidCallback action) => Navigator.of(sheet).pop(action);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(pc.pcName, style: QuoinType.of(sheet).title),
                if (failure != null)
                  Text(
                    syncFailureDetail(l10n, failure),
                    style: QuoinType.of(sheet).secondary,
                  ),
                if (pc.shared)
                  SettingsRow(
                    icon: QuoinIcons.sync,
                    label: l10n.syncCheckAgain,
                    onTap: () => pick(() => _checkAgain(context, ref, pc)),
                  ),
                if (failure case PcUnreachableFailure())
                  SettingsRow(
                    icon: QuoinIcons.offline,
                    label: l10n.syncRescan,
                    onTap: () => pick(() => context.push(Routes.pair)),
                  ),
                if (failure
                    case CertificateMismatchFailure() ||
                        PairingRevokedFailure())
                  SettingsRow(
                    icon: QuoinIcons.certificate,
                    label: l10n.syncPairAgain,
                    onTap: () => pick(() => context.push(Routes.repair)),
                  ),
                SettingsRow(
                  icon: QuoinIcons.unpair,
                  label: l10n.syncUnpair,
                  onTap: () => pick(() => _unpair(context, ref, pc)),
                ),
              ],
            ),
          ),
        );
      },
    );
    chosen?.call();
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(syncFailureText(l10n, failure))));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(syncFailureText(l10n, failure))));
    }
  }
}
