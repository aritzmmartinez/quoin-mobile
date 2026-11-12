import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/usecases/finish_sync.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin_core/quoin_core.dart';

class _Held implements SyncNow {
  final asked = <Set<String>>[];
  final ends = <Completer<Result<SyncPass>>>[];

  @override
  Future<Result<SyncPass>> call({
    Map<String, Resolutions> resolutions = const {},
    Set<String> confirm = const {},
    bool onlyConfirmed = false,
  }) {
    asked.add(confirm);
    final end = Completer<Result<SyncPass>>();
    ends.add(end);
    return end.future;
  }
}

class _HeldFinish implements FinishSync {
  final ends = <Completer<SyncFollowUp>>[];

  @override
  Future<SyncFollowUp> call(SyncPass pass) {
    final end = Completer<SyncFollowUp>();
    ends.add(end);
    return end.future;
  }
}

const _none = PlanCounts(
  ledger: 0,
  inKind: 0,
  setAside: 0,
  newInstruments: 0,
  changedInstruments: 0,
  newTargets: 0,
  deletedTargets: 0,
  newHoldings: 0,
  replacedHoldings: 0,
  newIdentities: 0,
  updatedIdentities: 0,
  settings: false,
  restamped: 0,
);

final _synced = SyncPass(
  pcs: [
    PcSync(
      Pairing(
        endpoint: const SyncEndpoint(host: 'pc.test', port: 1, sha256: 'ab'),
        token: 't',
        pcName: 'PC',
        pairedAt: DateTime.utc(2026),
        confirmed: true,
      ),
      const Ok(SyncDone(counts: _none, setAside: [])),
    ),
  ],
);

void main() {
  late _Held held;
  late _HeldFinish finish;
  late ProviderContainer container;
  late int loads;

  setUp(() {
    held = _Held();
    finish = _HeldFinish();
    loads = 0;
    container = ProviderContainer(
      overrides: [
        syncNowProvider.overrideWithValue(held),
        finishSyncProvider.overrideWithValue(finish),
        ledgerProvider.overrideWith((ref) {
          loads += 1;
          return const Err(StorageFailure());
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  SyncController controller() =>
      container.read(syncControllerProvider.notifier);

  test(
    'a plain sync asked while one runs joins it: one pass, one result',
    () async {
      final opening = controller().sync(onlyConfirmed: true);
      final pulling = controller().sync();
      await pumpEventQueue();
      expect(held.asked, hasLength(1));

      held.ends.single.complete(const Ok(SyncPass(pcs: [])));
      expect(await opening, same(await pulling));
      expect(held.asked, hasLength(1));
    },
  );

  test(
    'a sync carrying a decision waits for the running one, then runs',
    () async {
      final opening = controller().sync(onlyConfirmed: true);
      final confirming = controller().sync(confirm: {'ab'});
      await pumpEventQueue();
      expect(held.asked, hasLength(1));

      held.ends.first.complete(const Ok(SyncPass(pcs: [])));
      await opening;
      await pumpEventQueue();
      expect(held.asked, [
        <String>{},
        {'ab'},
      ]);

      held.ends.last.complete(const Ok(SyncPass(pcs: [])));
      expect(await confirming, isA<Ok<SyncPass>>());
    },
  );

  test('a pass ends with its exchanges; prices follow apart, and their '
      'failure reaches the status', () async {
    container.listen(ledgerProvider, (_, _) {});
    await container.read(ledgerProvider.future);
    final pulling = controller().sync();
    await pumpEventQueue();
    held.ends.single.complete(Ok(_synced));

    expect(await pulling, isA<Ok<SyncPass>>());
    await container.read(ledgerProvider.future);
    final afterPass = loads;
    expect(container.read(syncControllerProvider).finishing, isTrue);
    expect(finish.ends, hasLength(1));

    finish.ends.single.complete(
      const SyncFollowUp(prices: Err(PcUnreachableFailure())),
    );
    await pumpEventQueue();
    final status = container.read(syncControllerProvider);
    expect(status.finishing, isFalse);
    expect(status.followUp?.prices, isA<Err<PricesOutcome>>());
    await container.read(ledgerProvider.future);
    expect(
      loads,
      afterPass + 1,
      reason: 'every valuation reloads once prices and rates are in',
    );
  });

  test('a new pass waits for the last one to finish its follow-up', () async {
    final first = controller().sync();
    await pumpEventQueue();
    held.ends.single.complete(Ok(_synced));
    await first;

    final second = controller().sync();
    await pumpEventQueue();
    expect(held.asked, hasLength(1), reason: 'prices still being written');

    finish.ends.single.complete(const SyncFollowUp());
    await pumpEventQueue();
    expect(held.asked, hasLength(2));
    held.ends.last.complete(const Ok(SyncPass(pcs: [])));
    await second;
  });
}
