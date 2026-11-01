import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/import_repository_impl.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/usecases/commit_import.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin_core/quoin_core.dart' hide Instrument;
import 'package:quoin_core/quoin_core.dart' as core show Instrument;

import '../../helpers.dart';

const fund = 'XX00QTEST001';
final at = DateTime.utc(2026, 3, 2, 10);

core.Instrument instrument({String name = 'Fondo Prueba'}) =>
    core.Instrument(id: fund, name: name, type: 'ETF', assetClass: 'fund');

TradeEvent buy(
  String externalId, {
  Funding funding = Funding.cash,
  String instrumentId = fund,
  String? swap,
  TradeType type = TradeType.buy,
}) => TradeEvent(
  id: 'id-$externalId',
  ts: at,
  type: type,
  instrumentId: instrumentId,
  quantity: Dec.parse('2'),
  price: Money.parse('50.5'),
  grossAmount: Money.parse('101'),
  fees: Money.parse('1'),
  currency: 'EUR',
  funding: funding,
  linkId: swap,
  linkKind: swap == null ? null : 'swap',
  account: 'trade-republic',
  source: 'TR_CSV',
  externalId: externalId,
);

ImportBatch batchOf(List<LedgerEvent> events, {List<int>? operationOf}) =>
    ImportBatch(
      total: events.length,
      instruments: [instrument()],
      events: events,
      operationOf: operationOf,
    );

void main() {
  late QuoinDatabase db;
  late ImportRepositoryImpl repository;
  late CommitImport commit;

  setUp(() {
    db = memoryDatabase();
    repository = ImportRepositoryImpl(
      const ImportFileDataSource(),
      ImportLocalDataSource(db),
      now: () => at,
    );
    commit = CommitImport(repository);
  });
  tearDown(() => db.close());

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError('$failure'),
  };

  Future<List<LedgerEntryRow>> entries() => db.select(db.ledgerEntry).get();

  test('a batch is written once; importing it again adds nothing', () async {
    final batch = batchOf([buy('a'), buy('b')]);
    expect(ok(await repository.preview(batch)).imported, 2);

    final first = ok(await commit(batch));
    expect((first.imported, first.duplicates), (2, 0));
    expect(await entries(), hasLength(2));

    final again = ok(await commit(batch));
    expect((again.imported, again.duplicates), (0, 2));
    expect(await entries(), hasLength(2));
    expect(ok(await repository.preview(batch)).imported, 0);
  });

  test('rows are stored as Quoin writes them', () async {
    ok(await commit(batchOf([buy('a')])));
    final row = (await entries()).single;
    expect(row.type, 'BUY');
    expect(row.quantity, '2');
    expect(row.price, '50.5');
    expect(row.grossAmount, '101');
    expect(row.fees, '1');
    expect(row.originalAmount, '101', reason: 'defaults to the gross amount');
    expect(row.originalCurrency, 'EUR');
    expect(row.fxSource, 'IDENTITY');
    expect(row.funding, 'CASH');
    expect(row.source, 'TR_CSV');
    expect(row.externalId, 'a');
    final ts = await db
        .customSelect('SELECT "ts" FROM "LedgerEntry"')
        .getSingle();
    expect(ts.read<String>('ts'), '2026-03-02T10:00:00.000Z');
  });

  test('an instrument keeps the fields set by hand', () async {
    ok(await commit(batchOf([buy('a')])));
    await db.customStatement(
      'UPDATE "Instrument" SET "ter" = \'0.2\', "thesis" = \'CONVICTION\', '
      '"quoteSymbol" = \'QTEST.DE\', "exposureKind" = \'EQUITY_FUND\', '
      '"hedgedToBase" = 1',
    );

    ok(
      await commit(
        ImportBatch(
          total: 1,
          instruments: [instrument(name: 'Fondo Prueba Acc')],
          events: [buy('b')],
        ),
      ),
    );

    final row = await db.select(db.instrument).getSingle();
    expect(row.name, 'Fondo Prueba Acc');
    expect(row.ter, '0.2');
    expect(row.thesis, 'CONVICTION');
    expect(row.quoteSymbol, 'QTEST.DE');
    expect(row.exposureKind, 'EQUITY_FUND');
    expect(row.hedgedToBase, isTrue);
  });

  test(
    'a stored cash row the batch knows to be in kind is marked so',
    () async {
      ok(await commit(batchOf([buy('a'), buy('b')])));
      final result = ok(
        await commit(batchOf([buy('a', funding: Funding.inKind), buy('b')])),
      );
      expect(result.imported, 0);
      final funding = {
        for (final r in await entries()) r.externalId: r.funding,
      };
      expect(funding, {'a': 'IN_KIND', 'b': 'CASH'});
    },
  );

  test('an in-kind row never goes back to cash', () async {
    ok(await commit(batchOf([buy('a', funding: Funding.inKind)])));
    ok(await commit(batchOf([buy('a')])));
    expect((await entries()).single.funding, 'IN_KIND');
  });

  test('a swap counts as one operation', () async {
    final legs = [
      buy('s1', type: TradeType.sell, swap: 'x'),
      buy('s2', swap: 'x'),
    ];
    final first = ok(await commit(batchOf(legs, operationOf: [0, 0])));
    expect((first.imported, first.duplicates), (1, 0));
    final again = ok(await commit(batchOf(legs, operationOf: [0, 0])));
    expect((again.imported, again.duplicates), (0, 1));
  });

  test('a failed write leaves nothing behind', () async {
    final result = await commit(
      batchOf([buy('a'), buy('b', instrumentId: 'XX00QMISSING')]),
    );
    expect(result, isA<Err<ImportPreview>>());
    expect((result as Err).failure, isA<StorageFailure>());
    expect(await entries(), isEmpty);
    expect(await db.select(db.instrument).get(), isEmpty);
  });

  test('an event that breaks the ledger rules stops the import', () async {
    final foreign = TradeEvent(
      id: 'id-usd',
      ts: at,
      type: TradeType.buy,
      instrumentId: fund,
      quantity: Dec.parse('1'),
      price: Money.parse('10'),
      grossAmount: Money.parse('10'),
      fees: Money.zero,
      currency: 'USD',
      account: 'trade-republic',
      source: 'TR_CSV',
      externalId: 'usd',
    );
    final result = await commit(batchOf([buy('a'), foreign]));
    final failure = (result as Err).failure;
    expect(failure, isA<InvalidLedgerEventFailure>());
    expect((failure as InvalidLedgerEventFailure).currency, 'USD');
    expect(await entries(), isEmpty);
  });

  test('the sample batch is valid and writes every kind of row', () async {
    final batch = repository.sampleBatch(at);
    final result = ok(await commit(batch));
    expect(result.imported, 7);
    final types = {for (final r in await entries()) r.type};
    expect(types, {'DEPOSIT', 'BUY', 'SELL', 'DIVIDEND'});
    expect(ok(await commit(batch)).imported, 0);
  });
}
