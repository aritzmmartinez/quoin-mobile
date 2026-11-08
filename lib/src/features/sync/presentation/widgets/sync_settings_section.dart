import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_failure_text.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';

class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(syncControllerProvider);
    final rows = switch (ref.watch(pairingProvider).value) {
      null => const <SettingsRow>[],
      Ok(value: null) => [
        SettingsRow(
          icon: QuoinIcons.pair,
          label: l10n.syncPair,
          onTap: () => context.push(Routes.pair),
        ),
      ],
      Ok(value: final pairing?) => [
        SettingsRow(
          icon: QuoinIcons.computer,
          label: pairing.pcName,
          value: status.running
              ? l10n.syncRunning(pairing.pcName)
              : _lastSync(context, pairing),
        ),
        if (status.failure case final failure?) _failureRow(context, failure),
        SettingsRow(
          icon: QuoinIcons.sync,
          label: l10n.syncNow,
          onTap: () => context.push(Routes.sync),
        ),
        SettingsRow(
          icon: QuoinIcons.unpair,
          label: l10n.syncUnpair,
          onTap: () => _unpair(context, ref, pairing),
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

  String _lastSync(BuildContext context, Pairing pairing) {
    final l10n = AppLocalizations.of(context);
    final at = pairing.lastSyncAt;
    if (at == null) return l10n.syncNever;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return l10n.syncLastSync(
      DateFormat.yMMMd(locale).add_Hm().format(at.toLocal()),
    );
  }

  SettingsRow _failureRow(BuildContext context, Failure failure) {
    final l10n = AppLocalizations.of(context);
    return switch (failure) {
      PcUnreachableFailure() => SettingsRow(
        icon: QuoinIcons.offline,
        label: l10n.syncUnreachable,
        value: l10n.syncRescan,
        onTap: () => context.push(Routes.pair),
      ),
      CertificateMismatchFailure() || PairingRevokedFailure() => SettingsRow(
        icon: QuoinIcons.certificate,
        label: syncFailureText(l10n, failure),
        value: l10n.syncPairAgain,
        onTap: () => context.push(Routes.pair),
      ),
      _ => SettingsRow(
        icon: QuoinIcons.alert,
        label: syncFailureText(l10n, failure),
      ),
    };
  }

  Future<void> _unpair(
    BuildContext context,
    WidgetRef ref,
    Pairing pairing,
  ) async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.syncUnpairTitle(pairing.pcName)),
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
    final result = await ref.read(unpairProvider)();
    ref.read(syncControllerProvider.notifier).reset();
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(syncFailureText(l10n, failure))));
    }
  }
}
