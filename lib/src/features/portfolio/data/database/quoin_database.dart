import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:quoin_core/quoin_core.dart' show uuidV4;

import 'package:quoin/src/features/portfolio/data/database/quoin_database.steps.dart';

part 'quoin_database.g.dart';

/// The local store: the ledger, what values it and what sync merges.
///
/// Migrations are written by hand, one step per version, against that
/// version's frozen schema in `quoin_database.steps.dart`, never against the
/// live tables: a later version that changes a table must not change what an
/// earlier step creates. After raising [schemaVersion], run
/// `dart run drift_dev make-migrations`: it saves the new schema in
/// `drift_schemas/`, adds its step and regenerates `test/drift/`.
@DriftDatabase(include: {'schema.drift'})
class QuoinDatabase extends _$QuoinDatabase {
  QuoinDatabase(super.executor);

  QuoinDatabase.open() : super(driftDatabase(name: 'quoin'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        '''INSERT INTO "Settings" ("id", "residence") VALUES (1, 'bizkaia')''',
      );
      await _createDevice();
    },
    onUpgrade: stepByStep(from1To2: _addSync),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// Version 2, Quoin's 20261029100000_sync_ready: the mark of each hand-set
  /// field, the device and its peers, and the tables sync carries. ADD COLUMN
  /// and new tables only, so no table is rebuilt and every CHECK survives.
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

  /// The device id, created once with the database. A copy of the database
  /// keeps it; the sync layer rotates it when it finds itself on another
  /// install.
  Future<void> _createDevice() => customStatement(
    'INSERT INTO "SyncDevice" ("id", "deviceId") VALUES (1, ?)',
    [uuidV4()],
  );
}
