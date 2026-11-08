import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';
import 'package:quoin/src/features/sync/domain/usecases/get_pairing.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin/src/features/sync/domain/usecases/unpair.dart';

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
