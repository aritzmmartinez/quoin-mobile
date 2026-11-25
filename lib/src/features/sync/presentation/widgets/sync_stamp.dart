import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';

class SyncStamp extends ConsumerStatefulWidget {
  const SyncStamp({super.key});

  @override
  ConsumerState<SyncStamp> createState() => _SyncStampState();
}

class _SyncStampState extends ConsumerState<SyncStamp> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = QuoinColors.of(context);
    final pcs = switch (ref.watch(pairingsProvider).value) {
      Ok(:final value) => value.pcs,
      _ => null,
    };
    DateTime? last;
    for (final pc in pcs ?? const <Pairing>[]) {
      final at = pc.lastSyncAt;
      if (at != null && (last == null || at.isAfter(last))) last = at;
    }
    if (last == null) return const SizedBox.shrink();

    final failed = ref.watch(syncControllerProvider).failed;
    final ago = ref.watch(nowProvider)().difference(last);
    final text = switch (ago) {
      _ when ago.inMinutes < 1 => l10n.syncedJustNow,
      _ when ago.inHours < 1 => l10n.syncedMinutesAgo(ago.inMinutes),
      _ when ago.inDays < 1 => l10n.syncedHoursAgo(ago.inHours),
      _ => l10n.syncedDaysAgo(ago.inDays),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width / 2,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: QuoinSpace.m),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: QuoinSpace.tight,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                color: failed ? c.faint : c.positive,
                shape: const CircleBorder(),
              ),
              child: const SizedBox.square(dimension: QuoinSpace.tight),
            ),
            Flexible(
              child: Text(
                text,
                style: QuoinType.of(context).secondary.tabular
                    .copyWith(color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
