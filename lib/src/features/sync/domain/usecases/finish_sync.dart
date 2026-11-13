import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';

class FinishSync {
  const FinishSync(this._repository, this._runEffects, this._pullPrices);

  final SyncRepository _repository;
  final RunEffects _runEffects;
  final PullPrices _pullPrices;

  Future<SyncFollowUp> call(SyncPass pass) async {
    final source = pass.pricesFrom;
    if (pass.effects.isEmpty && source == null) return const SyncFollowUp();
    final zone = await _repository.zone();
    final effects = await _runEffects(pass.effects, zone: zone);
    return SyncFollowUp(
      effects: effects,
      prices: source == null
          ? null
          : await _pullPrices(source, pass.phoneId, zone: zone),
    );
  }
}
