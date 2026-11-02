import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/seed/sample_import.dart';
import 'package:quoin/src/features/portfolio/data/seed/sample_portfolio.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

Matcher get marked => contains(sampleMarker);

MappedBatch sampleImport() => planIngest(
  Broker.tradeRepublic,
  sampleImportCsv(testNow),
  const IngestContext(zone: 'Europe/Madrid'),
);

void main() {
  test('everything the sample portfolio invents carries the marker', () {
    final sample = SamplePortfolio(testNow);

    expect(sample.instruments, isNotEmpty);
    for (final i in sample.instruments) {
      expect(i.id.value, marked);
    }
    for (final e in sample.entries) {
      expect(e.externalId.value, marked);
      expect(e.instrumentId.value, marked);
    }
    for (final p in sample.prices) {
      expect(p.instrumentId.value, marked);
    }
  });

  test('everything the sample import invents carries the marker', () {
    final batch = sampleImport();

    expect(batch.events, isNotEmpty);
    for (final i in batch.instruments) {
      expect(i.id, marked);
    }
    for (final e in batch.events) {
      expect(e.externalId, marked);
    }
  });

  test('a database holding the sample portfolio never syncs', () async {
    final db = await sampleDatabase();
    addTearDown(db.close);
    final store = SyncLocalDataSource(db);

    await expectLater(store.state(), throwsA(isA<SampleDataException>()));
    await expectLater(store.export(), throwsA(isA<SampleDataException>()));
  });

  test('a database holding the sample import never syncs', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await ImportLocalDataSource(db).write(sampleImport(), testNow);

    await expectLater(
      SyncLocalDataSource(db).export(),
      throwsA(isA<SampleDataException>()),
    );
  });
}
