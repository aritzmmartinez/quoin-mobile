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

/// One pass over every paired PC (`docs/sync-api.md` in Quoin):
///
/// 1. claim this install's device id; stop if it fails;
/// 2. `GET /v1/hello` to every PC at once, with a short wait; with [PcSearch],
///    one sweep of the phone's /24 for those that did not answer, which
///    takes the address where each one's certificate answers;
/// 3. one after another, each PC that answered: `GET /v1/sync`, its
///    identity against the other PCs, the merge here in one transaction,
///    `POST /v1/sync` with `If-Match` (a 409 starts that PC again, once);
/// 4. when a later PC brought changes, once more to the PCs synced before
///    it, so the phone carries each PC's changes to the others in one pass;
/// 5. the PC the price histories will come from.
///
/// The effects and the price histories are left to `FinishSync`.
///
/// One PC's failure never stops the others. A PC's first sync only previews
/// both directions until [call] is given its id in `confirm`; open conflicts
/// write nothing on either side.
/// Whether a pass looks for the PCs that do not answer at their address.
enum PcSearch { off, held, always }

class SyncNow {
  const SyncNow(this._repository, this._identity, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SyncRepository _repository;
  final PcIdentity _identity;
  final DateTime Function() _now;

  /// [resolutions] and [confirm] are keyed by the PC's certificate SHA-256.
  /// With [onlyConfirmed], PCs not yet confirmed are left out (the sync on
  /// opening the app never previews). [onSearch] hears which PCs a search
  /// looks for, and an empty set when it ends.
  Future<Result<SyncPass>> call({
    Map<String, Resolutions> resolutions = const {},
    Set<String> confirm = const {},
    bool onlyConfirmed = false,
    PcSearch search = PcSearch.off,
    void Function(Set<String> sha256s)? onSearch,
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
    final hellos = [
      for (final (i, hello) in (await Future.wait([
        for (final pc in active) _repository.hello(pc.endpoint),
      ])).indexed)
        switch (hello) {
          Err(failure: CertificateMismatchFailure(:final presented?))
              when presented != active[i].sha256 &&
                  pairings.of(presented) != null =>
            const Err<List<int>>(PcUnreachableFailure()),
          _ => hello,
        },
    ];
    if (search != PcSearch.off) {
      await _search(active, hellos, search, onSearch);
    }

    final synced = <Pairing>[];
    final effects = <Effect>[];
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
      final (result, brought, left) = await _syncOne(
        pc,
        phoneId,
        resolutions: resolutions[pc.sha256] ?? const {},
        confirm: confirm.contains(pc.sha256),
      );
      results[pc.sha256] = result;
      effects.addAll(left);
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
        final (again, _, left) = await _syncOne(
          now.of(pc.sha256) ?? pc,
          phoneId,
        );
        effects.addAll(left);
        switch ((again, results[pc.sha256])) {
          case (Err(), _):
            results[pc.sha256] = again;
          case (
            Ok(value: final SyncDone later),
            Ok(value: final SyncDone first),
          ):
            results[pc.sha256] = Ok(first.plus(later));
          case _:
            break;
        }
      }
    }

    final at = _now().toUtc();
    for (final pc in synced) {
      if (results[pc.sha256] case Ok(
        value: SyncDone(:final toPhone, :final toPc),
      )) {
        await _repository.saveLastSync(
          pc.sha256,
          LastSync(at: at, toPhone: toPhone, toPc: toPc),
        );
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
        effects: effects,
        pricesFrom: await _pricesFrom(fresh, synced),
        phoneId: phoneId,
      ),
    );
  }

  Future<void> _search(
    List<Pairing> active,
    List<Result<List<int>>> hellos,
    PcSearch search,
    void Function(Set<String>)? onSearch,
  ) async {
    final lost = [
      for (final (i, hello) in hellos.indexed)
        if (hello case Err(failure: PcUnreachableFailure())) i,
    ];
    if (lost.isEmpty) return;
    onSearch?.call({for (final i in lost) active[i].sha256});
    final found = await _repository.find([
      for (final i in lost) active[i].endpoint,
    ], held: search == PcSearch.held);
    onSearch?.call(const {});
    switch (found) {
      case Err(:final failure):
        for (final i in lost) {
          hellos[i] = Err(failure);
        }
      case Ok(value: final found):
        final moved = <int>[];
        for (final i in lost) {
          final pc = active[i];
          if (found[pc.sha256] case (:final host, :final versions)) {
            active[i] = pc.copy(
              endpoint: SyncEndpoint(
                host: host,
                port: pc.endpoint.port,
                sha256: pc.sha256,
              ),
            );
            hellos[i] = Ok(versions);
            moved.add(i);
          } else {
            hellos[i] = const Err(PcNotFoundOnNetworkFailure());
          }
        }
        if (moved.isEmpty) return;
        final saved = switch (await _repository.pairings()) {
          Ok(value: final now) => await _repository.savePairings(
            moved.fold(
              now,
              (all, i) => all.put(
                (all.of(active[i].sha256) ?? active[i]).copy(
                  endpoint: active[i].endpoint,
                ),
              ),
            ),
          ),
          Err(:final failure) => Err<void>(failure),
        };
        if (saved case Err(:final failure)) {
          for (final i in moved) {
            hellos[i] = Err(failure);
          }
        }
    }
  }

  /// Prices come from the PC that served them last while it syncs; else from
  /// the first that did, which becomes the source.
  Future<Pairing?> _pricesFrom(Pairings pairings, List<Pairing> synced) async {
    final source =
        synced.where((pc) => pc.sha256 == pairings.pricesFrom).firstOrNull ??
        synced.firstOrNull;
    if (source != null && source.sha256 != pairings.pricesFrom) {
      await _repository.savePairings(pairings.pricesFromPc(source.sha256));
    }
    return source;
  }

  /// One PC: how it ended, whether it brought changes, and the effects its
  /// merge left.
  Future<(Result<SyncOutcome>, bool, List<Effect>)> _syncOne(
    Pairing pairing,
    String phoneId, {
    Resolutions resolutions = const {},
    bool confirm = false,
  }) async {
    (Result<SyncOutcome>, bool, List<Effect>) failed(Failure failure) =>
        (Err(failure), false, const []);

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
            const <Effect>[],
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
              setAside: imported.detail.setAside,
              instrumentNames: imported.instrumentNames,
            ),
          ),
          false,
          const <Effect>[],
        );
      }

      final Exchange local;
      switch (await _repository.export()) {
        case Ok(:final value):
          local = value;
        case Err(:final failure):
          return failed(failure);
      }
      final toPc = syncDetail(
        merge(pc.exchange, local, const {}),
        pc.exchange,
        local,
      );
      if (preview) {
        return (
          Ok(SyncPreview(toPhone: imported.detail, toPc: toPc)),
          false,
          const <Effect>[],
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
      return (
        Ok(SyncDone(toPhone: imported.detail, toPc: toPc)),
        imported.status == ImportStatus.applied,
        imported.pendingEffects,
      );
    }
  }
}
