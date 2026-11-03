import 'package:quoin_core/quoin_core.dart';

enum ImportStatus { conflicts, upToDate, dryRun, applied }

final class ExchangeImport {
  const ExchangeImport({
    required this.status,
    required this.plan,
    required this.counts,
  });

  final ImportStatus status;
  final MergePlan plan;
  final PlanCounts counts;

  List<Effect> get pendingEffects =>
      status == ImportStatus.applied ? plan.effects : const [];
}

final class SyncSender {
  const SyncSender({required this.deviceId, required this.name});

  final String deviceId;
  final String? name;
}
