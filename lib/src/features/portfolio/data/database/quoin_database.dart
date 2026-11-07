import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:quoin_core/quoin_core.dart' show uuidV4;

import 'package:quoin/src/features/portfolio/data/database/quoin_database.steps.dart';

part 'quoin_database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class QuoinDatabase extends _$QuoinDatabase {
  QuoinDatabase(super.executor);

  QuoinDatabase.open() : super(driftDatabase(name: 'quoin'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        '''INSERT INTO "Settings" ("id", "residence") VALUES (1, 'bizkaia')''',
      );
      await _createDevice();
    },
    onUpgrade: stepByStep(from1To2: _addSync, from2To3: _movePrices),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _addSync(Migrator m, Schema2 schema) async {
    final instrument = schema.instrument;
    for (final column in [
      instrument.quoteSymbolHlc,
      instrument.exposureHlc,
      instrument.terHlc,
      instrument.hedgedToBaseHlc,
      instrument.thesisHlc,
    ]) {
      await m.addColumn(instrument, column);
    }
    await m.addColumn(schema.settings, schema.settings.residenceHlc);
    for (final entity in <DatabaseSchemaEntity>[
      schema.etfHolding,
      schema.etfHoldingInstrumentIdIdentityKey,
      schema.etfHoldingInstrumentIdIdx,
      schema.etfHoldingBlock,
      schema.portfolioTarget,
      schema.portfolioTargetActiveFromKey,
      schema.portfolioTargetLine,
      schema.portfolioTargetLineTargetIdIdx,
      schema.portfolioTargetLineTargetIdInstrumentIdKey,
      schema.securityIdentity,
      schema.securityIdentityCanonicalIdIdx,
      schema.syncDevice,
      schema.syncPeer,
      schema.syncTombstone,
    ]) {
      await m.create(entity);
    }
    await _createDevice();
  }

  Future<void> _movePrices(Migrator m, Schema3 schema) =>
      m.deleteTable('PriceSnapshot');

  Future<void> _createDevice() => customStatement(
    'INSERT INTO "SyncDevice" ("id", "deviceId") VALUES (1, ?)',
    [uuidV4()],
  );
}
