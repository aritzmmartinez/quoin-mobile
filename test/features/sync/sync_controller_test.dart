import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
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

void main() {
  late _Held held;
  late ProviderContainer container;

  setUp(() {
    held = _Held();
    container = ProviderContainer(
      overrides: [syncNowProvider.overrideWithValue(held)],
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
}
