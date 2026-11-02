// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = QuoinDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 to v2 keeps every row, its text and no mark', () async {
    final at = DateTime.utc(2026, 1, 5, 9);
    const instrument = v1.InstrumentData(
      id: 'XX00TEST0001',
      name: 'Test World ETF',
      type: 'ETF',
      exposureKind: 'EQUITY_FUND',
      ter: '0.0022',
      hedgedToBase: 0,
      thesis: 'CORE',
      createdAt: '2026-01-02T09:00:00.000Z',
    );
    final entry = v1.LedgerEntryData(
      id: 'row-1',
      ts: at.toIso8601String(),
      type: 'BUY',
      instrumentId: 'XX00TEST0001',
      quantity: '1.50',
      price: '100.10',
      grossAmount: '150.150',
      fees: '0',
      taxWithheld: '0',
      currency: 'EUR',
      fxSource: 'IDENTITY',
      funding: 'CASH',
      account: 'trade-republic',
      source: 'TR_CSV',
      externalId: 't-1',
      createdAt: at.toIso8601String(),
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: QuoinDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.instrument, instrument)
          ..insert(oldDb.ledgerEntry, entry)
          ..insert(
            oldDb.settings,
            const v1.SettingsData(id: 1, residence: 'bizkaia'),
          );
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.instrument).get(), [
          v2.InstrumentData.fromJson(instrument.toJson()),
        ]);
        expect(await newDb.select(newDb.ledgerEntry).get(), [
          v2.LedgerEntryData.fromJson(entry.toJson()),
        ]);
        expect(await newDb.select(newDb.settings).get(), [
          const v2.SettingsData(id: 1, residence: 'bizkaia'),
        ]);
        final device = await newDb.select(newDb.syncDevice).getSingle();
        expect(device.id, 1);
        expect(device.deviceId, matches(RegExp(r'^[0-9a-f-]{36}$')));
        expect(device.lastHlc, isNull);
        expect(await newDb.select(newDb.syncPeer).get(), isEmpty);
      },
    );
  });
}
