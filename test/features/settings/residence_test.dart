import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/settings/data/datasources/residence_local_datasource.dart';
import 'package:quoin/src/features/settings/data/repositories/residence_repository_impl.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

void main() {
  late QuoinDatabase db;
  late ResidenceRepositoryImpl repository;

  Future<SettingsRow> stored() => db.select(db.settings).getSingle();
  Future<String?> lastMark() async =>
      (await db.select(db.syncDevice).getSingle()).lastHlc;

  setUp(() {
    db = memoryDatabase();
    repository = ResidenceRepositoryImpl(
      ResidenceLocalDataSource(db, now: () => testNow),
    );
  });
  tearDown(() => db.close());

  test('a new residence is written with its mark', () async {
    expect(await repository.set(Residence.comun), isA<Ok<void>>());

    final row = await stored();
    expect(row.residence, 'comun');
    expect(row.residenceHlc, isNotNull);
    expect(row.residenceHlc, await lastMark());
    expect(await repository.get(), isA<Ok<String>>());
  });

  test(
    'choosing the residence it already holds marks it once, then never again',
    () async {
      expect((await stored()).residenceHlc, isNull);

      await repository.set(Residence.bizkaia);
      final mark = (await stored()).residenceHlc;
      expect(mark, isNotNull);

      await repository.set(Residence.bizkaia);
      expect((await stored()).residenceHlc, mark);
      expect(await lastMark(), mark);
    },
  );

  test('a residence this version does not know is read as it came', () async {
    await db
        .update(db.settings)
        .write(const SettingsCompanion(residence: Value('araba')));

    expect(switch (await repository.get()) {
      Ok(:final value) => value,
      Err() => null,
    }, 'araba');
  });

  test(
    'the chosen residence travels in the exchange and the PC takes it',
    () async {
      final pc = memoryDatabase();
      addTearDown(pc.close);

      await repository.set(Residence.canarias);
      final sent = await SyncLocalDataSource(db, now: () => testNow).export();
      expect(sent.settings.residence, 'canarias');
      expect(sent.settings.residenceHlc, (await stored()).residenceHlc);

      final atPc = await SyncLocalDataSource(pc, now: () => testNow).state();
      final plan = merge(atPc, sent);
      expect(plan.conflicts, isEmpty);
      expect(plan.apply.settings?.residence, 'canarias');
      expect(plan.apply.settings?.residenceHlc, sent.settings.residenceHlc);
    },
  );
}
