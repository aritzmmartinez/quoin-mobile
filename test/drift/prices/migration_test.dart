// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
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
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = PricesDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test(
    'v1 to v2 keeps every price and series, and adds no Kraken series',
    () async {
      const price = v1.PriceSnapshotData(
        id: 'XX00TEST0001|2026-01-05T00:00:00.000Z',
        instrumentId: 'XX00TEST0001',
        price: '101.20',
        currency: 'EUR',
        asOf: '2026-01-05T00:00:00.000Z',
        source: 'YAHOO',
        createdAt: '2026-01-05T17:30:00.000Z',
      );
      const series = v1.PriceSeriesData(
        instrumentId: 'XX00TEST0001',
        seriesVersion: '00000000-0000-4000-8000-000000000001',
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: PricesDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insert(oldDb.priceSnapshot, price)
            ..insert(oldDb.priceSeries, series);
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.priceSnapshot).get(), [
            v2.PriceSnapshotData.fromJson(price.toJson()),
          ]);
          expect(await newDb.select(newDb.priceSeries).get(), [
            v2.PriceSeriesData.fromJson(series.toJson()),
          ]);
          expect(await newDb.select(newDb.krakenSeries).get(), isEmpty);
        },
      );
    },
  );
}
