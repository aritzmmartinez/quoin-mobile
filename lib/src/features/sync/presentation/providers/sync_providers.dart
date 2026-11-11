import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart' show Resolutions;

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
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
  (ref) => SyncNow(
    ref.watch(syncRepositoryProvider),
    ref.watch(pcIdentityProvider),
    ref.watch(runEffectsProvider),
    ref.watch(pullPricesProvider),
  ),
);

final pairingsProvider = FutureProvider<Result<Pairings>>(
  (ref) => ref.watch(getPairingsProvider)(),
);

final qrScannerProvider = Provider<QrScanner>((ref) => scanQr);

final class SyncStatus {
  const SyncStatus({
    this.running = false,
    this.failure,
    this.failures = const {},
  });

  final bool running;
  final Failure? failure;
  final Map<String, Failure> failures;
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

class SyncController extends Notifier<SyncStatus> {
  Future<Result<SyncPass>>? _running;

  @override
  SyncStatus build() => const SyncStatus();

  Future<Result<SyncPass>> sync({
    Map<String, Resolutions> resolutions = const {},
    Set<String> confirm = const {},
    bool onlyConfirmed = false,
  }) async {
    for (var running = _running; running != null; running = _running) {
      if (resolutions.isEmpty && confirm.isEmpty) return running;
      await running;
    }
    final run = _pass(resolutions, confirm, onlyConfirmed);
    _running = run;
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
  ) async {
    state = SyncStatus(
      running: true,
      failure: state.failure,
      failures: state.failures,
    );
    final result = await ref.read(syncNowProvider)(
      resolutions: resolutions,
      confirm: confirm,
      onlyConfirmed: onlyConfirmed,
    );
    if (!ref.mounted) return result;
    state = switch (result) {
      Err(:final failure) => SyncStatus(failure: failure),
      Ok(value: final pass) => SyncStatus(
        failures: {
          for (final pc in pass.pcs)
            if (pc.result case Err(:final failure)) pc.pairing.sha256: failure,
        },
      ),
    };
    if (result case Ok(value: final pass) when pass.pcs.any((pc) => pc.done)) {
      ref.invalidate(ledgerProvider);
    }
    ref.invalidate(pairingsProvider);
    return result;
  }

  void reset() {
    state = const SyncStatus();
    ref.invalidate(pairingsProvider);
  }
}
