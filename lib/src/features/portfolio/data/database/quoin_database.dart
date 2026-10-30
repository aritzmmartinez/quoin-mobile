import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'quoin_database.g.dart';

/// The local store: the ledger and what values it. Migrations are written by
/// hand, one `from` step per version, never generated.
@DriftDatabase(include: {'schema.drift'})
class QuoinDatabase extends _$QuoinDatabase {
  QuoinDatabase(super.executor);

  QuoinDatabase.open() : super(driftDatabase(name: 'quoin'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        '''INSERT INTO "Settings" ("id", "residence") VALUES (1, 'bizkaia')''',
      );
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
