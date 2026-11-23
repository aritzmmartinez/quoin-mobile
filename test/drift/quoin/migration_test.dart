// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

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

  final at = DateTime.utc(2026, 1, 5, 9);
  const v1Instrument = v1.InstrumentData(
    id: 'XX00TEST0001',
    name: 'Test World ETF',
    type: 'ETF',
    exposureKind: 'EQUITY_FUND',
    ter: '0.0022',
    hedgedToBase: 0,
    thesis: 'CORE',
    createdAt: '2026-01-02T09:00:00.000Z',
  );
  final v1Entry = v1.LedgerEntryData(
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
  const v1Rate = v1.FxRateData(
    id: 'fx-1',
    base: 'EUR',
    quote: 'USD',
    day: '2026-01-05',
    rate: '1.0350',
    source: 'ECB',
    createdAt: '2026-01-05T16:00:00.000Z',
  );
  const v1Price = v1.PriceSnapshotData(
    id: 'price-1',
    instrumentId: 'XX00TEST0001',
    price: '101.20',
    currency: 'EUR',
    asOf: '2026-01-05T17:30:00.000Z',
    source: 'MANUAL',
    createdAt: '2026-01-05T17:30:00.000Z',
  );

  // v3 drops PriceSnapshot without copying it: prices are a cache the PC
  // sends again on the next sync, kept in PricesDatabase.
  Future<bool> hasPriceSnapshot(GeneratedDatabase db) async =>
      (await db
              .customSelect(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' "
                "AND name = 'PriceSnapshot'",
              )
              .get())
          .isNotEmpty;

  test('v1 to v2 keeps every row, its text and no mark', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: QuoinDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.instrument, v1Instrument)
          ..insert(oldDb.ledgerEntry, v1Entry)
          ..insert(
            oldDb.settings,
            const v1.SettingsData(id: 1, residence: 'bizkaia'),
          );
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.instrument).get(), [
          v2.InstrumentData.fromJson(v1Instrument.toJson()),
        ]);
        expect(await newDb.select(newDb.ledgerEntry).get(), [
          v2.LedgerEntryData.fromJson(v1Entry.toJson()),
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

  test('v1 to v3 keeps the portfolio and drops the prices', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 3,
      createOld: v1.DatabaseAtV1.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: QuoinDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.instrument, v1Instrument)
          ..insert(oldDb.ledgerEntry, v1Entry)
          ..insert(oldDb.fxRate, v1Rate)
          ..insert(oldDb.priceSnapshot, v1Price)
          ..insert(
            oldDb.settings,
            const v1.SettingsData(id: 1, residence: 'bizkaia'),
          );
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.instrument).get(), [
          v3.InstrumentData.fromJson(v1Instrument.toJson()),
        ]);
        expect(await newDb.select(newDb.ledgerEntry).get(), [
          v3.LedgerEntryData.fromJson(v1Entry.toJson()),
        ]);
        expect(await newDb.select(newDb.fxRate).get(), [
          v3.FxRateData.fromJson(v1Rate.toJson()),
        ]);
        expect(await newDb.select(newDb.settings).get(), [
          const v3.SettingsData(id: 1, residence: 'bizkaia'),
        ]);
        final device = await newDb.select(newDb.syncDevice).getSingle();
        expect(device.deviceId, matches(RegExp(r'^[0-9a-f-]{36}$')));
        expect(device.lastHlc, isNull);
        expect(await hasPriceSnapshot(newDb), isFalse);
      },
    );
  });

  test(
    'v2 to v3 keeps the portfolio and sync state, drops the prices',
    () async {
      final instrument = v2.InstrumentData.fromJson({
        ...v1Instrument.toJson(),
        'terHlc': '0000000001736067600000:0000:device-a',
      });
      final entry = v2.LedgerEntryData.fromJson(v1Entry.toJson());
      final rate = v2.FxRateData.fromJson(v1Rate.toJson());
      const settings = v2.SettingsData(
        id: 1,
        residence: 'bizkaia',
        residenceHlc: '0000000001736067600000:0001:device-a',
      );
      const device = v2.SyncDeviceData(
        id: 1,
        deviceId: '00000000-0000-4000-8000-000000000001',
        name: 'Phone',
        lastHlc: '0000000001736067600000:0001:device-a',
      );
      const peer = v2.SyncPeerData(
        deviceId: '00000000-0000-4000-8000-000000000002',
        name: 'PC',
        seen: '0000000001736067600000:0000:device-b',
        lastSyncedAt: '2026-01-05T09:00:00.000Z',
      );
      const tombstone = v2.SyncTombstoneData(
        entity: 'LedgerEntry',
        key: 'row-0',
        hlc: '0000000001736067600000:0000:device-a',
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: QuoinDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insert(oldDb.instrument, instrument)
            ..insert(oldDb.ledgerEntry, entry)
            ..insert(oldDb.fxRate, rate)
            ..insert(
              oldDb.priceSnapshot,
              v2.PriceSnapshotData.fromJson(v1Price.toJson()),
            )
            ..insert(oldDb.settings, settings)
            ..insert(oldDb.syncDevice, device)
            ..insert(oldDb.syncPeer, peer)
            ..insert(oldDb.syncTombstone, tombstone);
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.instrument).get(), [
            v3.InstrumentData.fromJson(instrument.toJson()),
          ]);
          expect(await newDb.select(newDb.ledgerEntry).get(), [
            v3.LedgerEntryData.fromJson(entry.toJson()),
          ]);
          expect(await newDb.select(newDb.fxRate).get(), [
            v3.FxRateData.fromJson(rate.toJson()),
          ]);
          expect(await newDb.select(newDb.settings).get(), [
            v3.SettingsData.fromJson(settings.toJson()),
          ]);
          expect(await newDb.select(newDb.syncDevice).get(), [
            v3.SyncDeviceData.fromJson(device.toJson()),
          ]);
          expect(await newDb.select(newDb.syncPeer).get(), [
            v3.SyncPeerData.fromJson(peer.toJson()),
          ]);
          expect(await newDb.select(newDb.syncTombstone).get(), [
            v3.SyncTombstoneData.fromJson(tombstone.toJson()),
          ]);
          expect(await hasPriceSnapshot(newDb), isFalse);
        },
      );
    },
  );
}
