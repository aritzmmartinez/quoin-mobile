import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart' show Resolutions;

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/get_pairing.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
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

final getPairingProvider = Provider(
  (ref) => GetPairing(ref.watch(syncRepositoryProvider)),
);
final unpairProvider = Provider(
  (ref) => Unpair(ref.watch(syncRepositoryProvider)),
);
final pairWithPcProvider = Provider(
  (ref) => PairWithPc(ref.watch(syncRepositoryProvider)),
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
    ref.watch(runEffectsProvider),
    ref.watch(pullPricesProvider),
  ),
);

final pairingProvider = FutureProvider<Result<Pairing?>>(
  (ref) => ref.watch(getPairingProvider)(),
);

final qrScannerProvider = Provider<QrScanner>((ref) => scanQr);

final class SyncStatus {
  const SyncStatus({this.running = false, this.failure});

  final bool running;
  final Failure? failure;
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

class SyncController extends Notifier<SyncStatus> {
  Future<Result<SyncOutcome>>? _running;

  @override
  SyncStatus build() => const SyncStatus();

  Future<Result<SyncOutcome>> sync({
    Resolutions resolutions = const {},
    bool confirm = false,
  }) => _running ??= _sync(
    resolutions,
    confirm,
  ).whenComplete(() => _running = null);

  Future<Result<SyncOutcome>> _sync(
    Resolutions resolutions,
    bool confirm,
  ) async {
    state = SyncStatus(running: true, failure: state.failure);
    final result = await ref.read(syncNowProvider)(
      resolutions: resolutions,
      confirm: confirm,
    );
    if (!ref.mounted) return result;
    state = SyncStatus(
      failure: switch (result) {
        Err(:final failure) => failure,
        Ok() => null,
      },
    );
    if (result case Ok(value: SyncDone())) {
      ref
        ..invalidate(ledgerProvider)
        ..invalidate(pairingProvider);
    }
    return result;
  }

  void reset() {
    state = const SyncStatus();
    ref.invalidate(pairingProvider);
  }
}
