import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';

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

final class SyncDone extends SyncOutcome {
  const SyncDone({
    required this.counts,
    required this.setAside,
    required this.effects,
    required this.prices,
  });

  final PlanCounts counts;
  final List<String> setAside;
  final List<EffectOutcome> effects;
  final Result<PricesOutcome> prices;
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
