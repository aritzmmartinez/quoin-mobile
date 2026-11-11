import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/exchange_import.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/pc_state.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/exchange_versions.dart';
import 'package:quoin/src/features/sync/domain/usecases/pc_identity.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';

/// One pass over every paired PC (`docs/sync-api.md` in Quoin):
///
/// 1. claim this install's device id; stop if it fails;
/// 2. `GET /v1/hello` to every PC at once, with a short wait;
/// 3. one after another, each PC that answered: `GET /v1/sync`, its
///    identity against the other PCs, the merge here in one transaction,
///    `POST /v1/sync` with `If-Match` (a 409 starts that PC again, once),
///    then its effects;
/// 4. when a later PC brought changes, once more to the PCs synced before
///    it, so the phone carries each PC's changes to the others in one pass;
/// 5. the price histories, from one PC.
///
/// One PC's failure never stops the others. A PC's first sync only previews
/// both directions until [call] is given its id in `confirm`; open conflicts
/// write nothing on either side.
class SyncNow {
  const SyncNow(
    this._repository,
    this._identity,
    this._runEffects,
    this._pullPrices, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SyncRepository _repository;
  final PcIdentity _identity;
  final RunEffects _runEffects;
  final PullPrices _pullPrices;
  final DateTime Function() _now;

  /// [resolutions] and [confirm] are keyed by the PC's certificate SHA-256.
  /// With [onlyConfirmed], PCs not yet confirmed are left out (the sync on
  /// opening the app never previews).
  Future<Result<SyncPass>> call({
    Map<String, Resolutions> resolutions = const {},
    Set<String> confirm = const {},
    bool onlyConfirmed = false,
  }) async {
    final Pairings pairings;
    switch (await _repository.pairings()) {
      case Ok(:final value) when value.pcs.isEmpty:
        return const Err(NotPairedFailure());
      case Ok(:final value):
        pairings = value;
      case Err(:final failure):
        return Err(failure);
    }
    final String phoneId;
    switch (await _repository.claim()) {
      case Ok(:final value):
        phoneId = value;
      case Err(:final failure):
        return Err(failure);
    }

    final pcs = [
      for (final pc in pairings.pcs)
        if (!onlyConfirmed || pc.confirmed || pc.shared) pc,
    ];
    final results = <String, Result<SyncOutcome>>{};
    final active = <Pairing>[];
    for (final pc in pcs) {
      if (pc.shared) {
        results[pc.sha256] = Err(
          SharedIdentityFailure(pairings.twinOf(pc)?.pcName ?? ''),
        );
      } else {
        active.add(pc);
      }
    }
    final hellos = await Future.wait([
      for (final pc in active) _repository.hello(pc.endpoint),
    ]);

    final synced = <Pairing>[];
    var lastBringer = -1;
    for (final (i, pc) in active.indexed) {
      final gap = switch (hellos[i]) {
        Ok(:final value) => versionGap(value),
        Err(:final failure) => failure,
      };
      if (gap != null) {
        results[pc.sha256] = Err(gap);
        continue;
      }
      final (result, brought) = await _syncOne(
        pc,
        phoneId,
        resolutions: resolutions[pc.sha256] ?? const {},
        confirm: confirm.contains(pc.sha256),
      );
      results[pc.sha256] = result;
      if (result case Ok(value: SyncDone())) {
        synced.add(pc);
        if (brought) lastBringer = synced.length - 1;
      }
    }
    if (lastBringer > 0) {
      final now = switch (await _repository.pairings()) {
        Ok(:final value) => value,
        Err() => pairings,
      };
      for (final pc in synced.take(lastBringer)) {
        final (again, _) = await _syncOne(now.of(pc.sha256) ?? pc, phoneId);
        if (again case Err()) results[pc.sha256] = again;
      }
    }

    final fresh = switch (await _repository.pairings()) {
      Ok(:final value) => value,
      Err() => pairings,
    };
    return Ok(
      SyncPass(
        pcs: [
          for (final pc in pcs)
            PcSync(fresh.of(pc.sha256) ?? pc, results[pc.sha256]!),
        ],
        prices: await _prices(fresh, synced, phoneId),
      ),
    );
  }

  /// Prices come from the PC that served them last while it syncs; else from
  /// the first that did, which becomes the source.
  Future<Result<PricesOutcome>?> _prices(
    Pairings pairings,
    List<Pairing> synced,
    String phoneId,
  ) async {
    final source =
        synced.where((pc) => pc.sha256 == pairings.pricesFrom).firstOrNull ??
        synced.firstOrNull;
    if (source == null) return null;
    if (source.sha256 != pairings.pricesFrom) {
      final saved = await _repository.savePairings(
        pairings.pricesFromPc(source.sha256),
      );
      if (saved case Err(:final failure)) return Err(failure);
    }
    final zone = await _repository.zone();
    return _pullPrices(source, phoneId, zone: zone);
  }

  Future<(Result<SyncOutcome>, bool)> _syncOne(
    Pairing pairing,
    String phoneId, {
    Resolutions resolutions = const {},
    bool confirm = false,
  }) async {
    (Result<SyncOutcome>, bool) failed(Failure failure) =>
        (Err(failure), false);

    for (var attempt = 0; ; attempt++) {
      final PcState pc;
      switch (await _repository.fetch(pairing, phoneId)) {
        case Ok(:final value):
          pc = value;
        case Err(:final failure):
          return failed(failure);
      }
      switch (await _identity.check(
        pairing,
        pc.exchange.deviceId,
        phoneId: phoneId,
      )) {
        case Ok(value: OwnIdentity()):
          break;
        case Ok(value: SharedIdentity(:final other)):
          return failed(SharedIdentityFailure(other.pcName));
        case Ok(value: UnknownIdentity(:final other)):
          return (
            Ok(SyncSameIdentity(other: other, deviceId: pc.exchange.deviceId)),
            false,
          );
        case Err(:final failure):
          return failed(failure);
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
          return failed(failure);
      }
      if (imported.status == ImportStatus.conflicts) {
        return (
          Ok(
            SyncConflicts(
              conflicts: imported.plan.conflicts,
              setAside: imported.plan.setAside,
            ),
          ),
          false,
        );
      }

      final Exchange local;
      switch (await _repository.export()) {
        case Ok(:final value):
          local = value;
        case Err(:final failure):
          return failed(failure);
      }
      if (preview) {
        return (
          Ok(
            SyncPreview(
              toPhone: imported.counts,
              toPc: planCounts(
                merge(pc.exchange, local, const {}),
                pc.exchange,
              ),
            ),
          ),
          false,
        );
      }

      final PushResult pushed;
      switch (await _repository.push(pairing, phoneId, local, etag: pc.etag)) {
        case Ok(:final value):
          pushed = value;
        case Err(failure: StateChangedFailure()) when attempt == 0:
          continue;
        case Err(:final failure):
          return failed(failure);
      }
      if (pushed.status == PushStatus.conflicts) {
        return failed(const ConflictsChangedFailure());
      }

      final at = _now().toUtc();
      switch (await _repository.pairings()) {
        case Ok(:final value):
          final saved = await _repository.savePairings(
            value.put((value.of(pairing.sha256) ?? pairing).synced(at)),
          );
          if (saved case Err(:final failure)) return failed(failure);
        case Err(:final failure):
          return failed(failure);
      }
      final zone = await _repository.zone();
      final effects = await _runEffects(imported.pendingEffects, zone: zone);
      return (
        Ok(
          SyncDone(
            counts: imported.counts,
            setAside: {
              for (final row in imported.plan.setAside) row.key,
              ...pushed.setAside,
            }.toList()..sort(),
            effects: effects,
          ),
        ),
        imported.status == ImportStatus.applied,
      );
    }
  }
}
