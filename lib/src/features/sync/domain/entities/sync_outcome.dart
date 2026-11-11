import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';

sealed class SyncOutcome {
  const SyncOutcome();
}

final class SyncPreview extends SyncOutcome {
  const SyncPreview({required this.toPhone, required this.toPc});

  final PlanCounts toPhone;
  final PlanCounts toPc;
}

final class SyncConflicts extends SyncOutcome {
  const SyncConflicts({required this.conflicts, required this.setAside});

  final List<Conflict> conflicts;
  final List<LedgerConflict> setAside;
}

final class SyncSameIdentity extends SyncOutcome {
  const SyncSameIdentity({required this.other, required this.deviceId});

  final Pairing other;
  final String deviceId;
}

final class SyncDone extends SyncOutcome {
  const SyncDone({
    required this.counts,
    required this.setAside,
    required this.effects,
  });

  final PlanCounts counts;
  final List<String> setAside;
  final List<EffectOutcome> effects;
}

final class PcSync {
  const PcSync(this.pairing, this.result);

  final Pairing pairing;
  final Result<SyncOutcome> result;

  bool get done => switch (result) {
    Ok(value: SyncDone()) => true,
    _ => false,
  };

  bool get waits => switch (result) {
    Ok(value: SyncPreview() || SyncConflicts() || SyncSameIdentity()) => true,
    _ => false,
  };
}

final class SyncPass {
  const SyncPass({required this.pcs, this.prices});

  final List<PcSync> pcs;
  final Result<PricesOutcome>? prices;

  List<PcSync> get waiting => [
    for (final pc in pcs)
      if (pc.waits) pc,
  ];

  bool get noneAnswered {
    final tried = [
      for (final pc in pcs)
        if (!pc.pairing.shared) pc,
    ];
    return tried.isNotEmpty &&
        tried.every(
          (pc) => switch (pc.result) {
            Err(failure: PcUnreachableFailure()) => true,
            _ => false,
          },
        );
  }
}

final class PricesOutcome {
  const PricesOutcome({
    required this.updated,
    required this.pending,
    this.unavailableRates = const [],
  });

  final int updated;
  final List<String> pending;
  final List<String> unavailableRates;
}
