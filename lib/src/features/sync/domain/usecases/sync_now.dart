import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/exchange_import.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/pc_state.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/exchange_versions.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';

/// One sync with the paired PC (`docs/sync-api.md` in Quoin):
///
/// 1. claim this install's device id; stop if it fails;
/// 2. `GET /v1/hello`: a common exchange version;
/// 3. `GET /v1/sync`: the PC's state and its ETag;
/// 4. merge it here in one transaction (`importExchange`);
/// 5. `POST /v1/sync` with the merged state and `If-Match`; when the PC
///    changed in between (409), start again from 3, once;
/// 6. after both commits, the effects and the price histories.
///
/// The first sync with a pairing only previews both directions until
/// [call] is given `confirm`. Open conflicts write nothing on either side.
class SyncNow {
  const SyncNow(
    this._repository,
    this._runEffects,
    this._pullPrices, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SyncRepository _repository;
  final RunEffects _runEffects;
  final PullPrices _pullPrices;
  final DateTime Function() _now;

  Future<Result<SyncOutcome>> call({
    Resolutions resolutions = const {},
    bool confirm = false,
  }) async {
    final Pairing pairing;
    switch (await _repository.pairing()) {
      case Ok(:final value?):
        pairing = value;
      case Ok():
        return const Err(NotPairedFailure());
      case Err(:final failure):
        return Err(failure);
    }

    final String deviceId;
    switch (await _repository.claim()) {
      case Ok(:final value):
        deviceId = value;
      case Err(:final failure):
        return Err(failure);
    }
    switch (await _repository.hello(pairing.endpoint)) {
      case Ok(:final value) when versionGap(value) != null:
        return Err(versionGap(value)!);
      case Ok():
        break;
      case Err(:final failure):
        return Err(failure);
    }

    for (var attempt = 0; ; attempt++) {
      final PcState pc;
      switch (await _repository.fetch(pairing, deviceId)) {
        case Ok(:final value):
          pc = value;
        case Err(:final failure):
          return Err(failure);
      }

      final preview = !pairing.confirmed && !confirm;
      final ExchangeImport imported;
      switch (await _repository.importExchange(
        pc.exchange,
        resolutions: resolutions,
        dryRun: preview,
      )) {
        case Ok(:final value):
          imported = value;
        case Err(:final failure):
          return Err(failure);
      }
      if (imported.status == ImportStatus.conflicts) {
        return Ok(
          SyncConflicts(
            conflicts: imported.plan.conflicts,
            setAside: imported.plan.setAside,
          ),
        );
      }

      final Exchange local;
      switch (await _repository.export()) {
        case Ok(:final value):
          local = value;
        case Err(:final failure):
          return Err(failure);
      }
      if (preview) {
        return Ok(
          SyncPreview(
            toPhone: imported.counts,
            toPc: planCounts(merge(pc.exchange, local, const {}), pc.exchange),
          ),
        );
      }

      final PushResult pushed;
      switch (await _repository.push(pairing, deviceId, local, etag: pc.etag)) {
        case Ok(:final value):
          pushed = value;
        case Err(failure: StateChangedFailure()) when attempt == 0:
          continue;
        case Err(:final failure):
          return Err(failure);
      }
      if (pushed.status == PushStatus.conflicts) {
        return const Err(ConflictsChangedFailure());
      }

      switch (await _repository.savePairing(pairing.synced(_now().toUtc()))) {
        case Ok():
          break;
        case Err(:final failure):
          return Err(failure);
      }
      final zone = await _repository.zone();
      final effects = await _runEffects(imported.pendingEffects, zone: zone);
      final prices = await _pullPrices(pairing, deviceId, zone: zone);
      return Ok(
        SyncDone(
          counts: imported.counts,
          setAside: {
            for (final row in imported.plan.setAside) row.key,
            ...pushed.setAside,
          }.toList()..sort(),
          effects: effects,
          prices: prices,
        ),
      );
    }
  }
}
