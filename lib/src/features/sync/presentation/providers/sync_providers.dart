import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart' show Resolutions;

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/finish_sync.dart';
import 'package:quoin/src/features/sync/domain/usecases/get_last_sync.dart';
import 'package:quoin/src/features/sync/domain/usecases/get_pairings.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/domain/usecases/pc_identity.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin/src/features/sync/domain/usecases/unpair.dart';
import 'package:quoin/src/features/sync/presentation/widgets/qr_scanner_view.dart';

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => throw UnimplementedError('syncRepositoryProvider not bound'),
);

final ensureRatesFromProvider = Provider<EnsureRatesFrom>(
  (ref) => throw UnimplementedError('ensureRatesFromProvider not bound'),
);

final getPairingsProvider = Provider(
  (ref) => GetPairings(ref.watch(syncRepositoryProvider)),
);
final unpairProvider = Provider(
  (ref) => Unpair(ref.watch(syncRepositoryProvider)),
);
final pairWithPcProvider = Provider(
  (ref) => PairWithPc(ref.watch(syncRepositoryProvider)),
);
final pcIdentityProvider = Provider(
  (ref) => PcIdentity(ref.watch(syncRepositoryProvider)),
);
final runEffectsProvider = Provider(
  (ref) => RunEffects(
    ref.watch(ensureRatesFromProvider),
    ref.watch(syncRepositoryProvider).dropPrices,
  ),
);
final pullPricesProvider = Provider(
  (ref) => PullPrices(
    ref.watch(syncRepositoryProvider),
    ref.watch(ensureRatesFromProvider),
  ),
);
final syncNowProvider = Provider(
  (ref) =>
      SyncNow(ref.watch(syncRepositoryProvider), ref.watch(pcIdentityProvider)),
);
final finishSyncProvider = Provider(
  (ref) => FinishSync(
    ref.watch(syncRepositoryProvider),
    ref.watch(runEffectsProvider),
    ref.watch(pullPricesProvider),
  ),
);

final pairingsProvider = FutureProvider<Result<Pairings>>(
  (ref) => ref.watch(getPairingsProvider)(),
);

final getLastSyncProvider = Provider(
  (ref) => GetLastSync(ref.watch(syncRepositoryProvider)),
);

final lastSyncProvider = FutureProvider.family<LastSync?, String>(
  (ref, sha256) async => switch (await ref.watch(getLastSyncProvider)(sha256)) {
    Ok(:final value) => value,
    Err() => null,
  },
);

final qrScannerProvider = Provider<QrScanner>((ref) => scanQr);

final class SyncStatus {
  const SyncStatus({
    this.running = false,
    this.failure,
    this.failures = const {},
    this.finishing = false,
    this.followUp,
    this.searching = const {},
  });

  final bool running;
  final Failure? failure;
  final Map<String, Failure> failures;
  final bool finishing;
  final SyncFollowUp? followUp;

  final Set<String> searching;

  SyncStatus copy({
    bool? running,
    bool? finishing,
    SyncFollowUp? followUp,
    Set<String>? searching,
  }) => SyncStatus(
    running: running ?? this.running,
    failure: failure,
    failures: failures,
    finishing: finishing ?? this.finishing,
    followUp: followUp ?? this.followUp,
    searching: searching ?? this.searching,
  );
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

class SyncController extends Notifier<SyncStatus> {
  Future<Result<SyncPass>>? _running;
  var _runningSearch = PcSearch.off;
  Future<SyncFollowUp>? _finishing;
  Future<SyncFollowUp>? get finishing => _finishing;

  @override
  SyncStatus build() => const SyncStatus();

  Future<Result<SyncPass>> sync({
    Map<String, Resolutions> resolutions = const {},
    Set<String> confirm = const {},
    bool onlyConfirmed = false,
    PcSearch search = PcSearch.off,
  }) async {
    while (true) {
      if (_running case final running?) {
        if (resolutions.isEmpty &&
            confirm.isEmpty &&
            _runningSearch.index >= search.index) {
          return running;
        }
        await running;
      } else if (_finishing case final finishing?) {
        await finishing;
      } else {
        break;
      }
    }
    final run = _pass(resolutions, confirm, onlyConfirmed, search);
    _running = run;
    _runningSearch = search;
    try {
      return await run;
    } finally {
      if (identical(_running, run)) _running = null;
    }
  }

  Future<Result<SyncPass>> _pass(
    Map<String, Resolutions> resolutions,
    Set<String> confirm,
    bool onlyConfirmed,
    PcSearch search,
  ) async {
    state = state.copy(running: true);
    if (kDebugMode) debugPrint('QuoinSync: pass, search ${search.name}');
    final result = await ref.read(syncNowProvider)(
      resolutions: resolutions,
      confirm: confirm,
      onlyConfirmed: onlyConfirmed,
      search: search,
      onSearch: (sha256s) {
        if (kDebugMode) {
          debugPrint('QuoinSync: searching for ${sha256s.length} PC(s)');
        }
        if (ref.mounted) state = state.copy(searching: sha256s);
      },
    );
    if (!ref.mounted) return result;
    state = switch (result) {
      Err(:final failure) => SyncStatus(failure: failure),
      Ok(value: final pass) => SyncStatus(
        failures: {
          for (final pc in pass.pcs)
            if (pc.result case Err(:final failure)) pc.pairing.sha256: failure,
        },
        followUp: state.followUp,
      ),
    };
    if (result case Ok(value: final pass) when pass.pcs.any((pc) => pc.done)) {
      ref.invalidate(ledgerProvider);
      _finishing = _finish(pass).whenComplete(() => _finishing = null);
    }
    ref
      ..invalidate(pairingsProvider)
      ..invalidate(lastSyncProvider);
    return result;
  }

  Future<SyncFollowUp> _finish(SyncPass pass) async {
    state = state.copy(finishing: true);
    final followUp = await ref.read(finishSyncProvider)(pass);
    if (ref.mounted) {
      state = state.copy(finishing: false, followUp: followUp);
      ref.invalidate(ledgerProvider);
    }
    return followUp;
  }

  void reset() {
    state = const SyncStatus();
    ref
      ..invalidate(pairingsProvider)
      ..invalidate(lastSyncProvider);
  }
}
