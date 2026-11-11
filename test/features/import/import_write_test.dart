import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/domain/usecases/plan_import.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';
import 'package:quoin/src/features/import/domain/repositories/fx_repository.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/import_repository_impl.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/usecases/commit_import.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show LedgerEntryRow, QuoinDatabase;
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

MappedBatch batchOf(
  List<LedgerEvent> events, {
  List<int>? operationOf,
  List<core.Instrument>? instruments,
}) => MappedBatch(
  total: events.length,
  failed: 0,
  instruments: instruments ?? [instrument()],
  events: events,
  operationOf: operationOf ?? [for (var i = 0; i < events.length; i += 1) i],
  discarded: const {},
  discardedDetails: const {},
  noticed: const {},
  errors: const [],
  ratesNeeded: const {},
);

ImportPreview previewOf(MappedBatch batch) => ImportPreview(
  batch: batch,
  broker: Broker.tradeRepublic,
  counts: (imported: 0, completed: 0, duplicates: 0),
  zone: 'Europe/Madrid',
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
      FxLocalDataSource(db),
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

  Future<Set<(String, String)>> stored(MappedBatch batch) async =>
      ok(await repository.existing(batch.events));

  test('a batch is written once; importing it again adds nothing', () async {
    final batch = batchOf([buy('a'), buy('b')]);
    expect(countOperations(batch, await stored(batch)).imported, 2);

    final first = ok(await commit(previewOf(batch)));
    expect((first.counts.imported, first.counts.duplicates), (2, 0));
    expect(await entries(), hasLength(2));

    final again = ok(await commit(previewOf(batch)));
    expect((again.counts.imported, again.counts.duplicates), (0, 2));
    expect(await entries(), hasLength(2));
    expect(countOperations(batch, await stored(batch)).imported, 0);
  });

  test('an operation that only gains its missing row is completed', () async {
    ok(await commit(previewOf(batchOf([buy('a')]))));
    final batch = batchOf([buy('a'), buy('b')], operationOf: [0, 0]);
    final preview = previewOf(batch)
        .counted(countOperations(batch, await stored(batch)));
    expect(preview.counts, (imported: 0, completed: 1, duplicates: 0));
    expect(preview.toWrite, 1);

    ok(await commit(preview));
    expect(await entries(), hasLength(2));
  });

  test('rows are stored as Quoin writes them', () async {
    ok(await commit(previewOf(batchOf([buy('a')]))));
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

  test('amounts keep the text they were read from', () async {
    final usd = TradeEvent(
      id: 'id-usd',
      ts: at,
      type: TradeType.buy,
      instrumentId: fund,
      quantity: Dec.parse('2'),
      price: Money.parse('50.50'),
      grossAmount: Money.parse('101'),
      fees: Money.zero,
      currency: 'USD',
      fxSource: FxSource.ecb,
      fxRate: Dec.parse('1.0500'),
      fxDirection: FxDirection.quotePerBase,
      fxDate: '2026-03-02',
      account: 'trade-republic',
      source: 'TR_CSV',
      externalId: 'usd',
    );
    ok(await commit(previewOf(batchOf([usd]))));
    final row = (await entries()).single;
    expect(row.price, '50.50');
    expect(row.fxRate, '1.0500');
  });

  test('an instrument keeps the fields set by hand', () async {
    ok(await commit(previewOf(batchOf([buy('a')]))));
    await db.customStatement(
      'UPDATE "Instrument" SET "ter" = \'0.2\', "thesis" = \'CONVICTION\', '
      '"quoteSymbol" = \'QTEST.DE\', "exposureKind" = \'EQUITY_FUND\', '
      '"hedgedToBase" = 1',
    );

    ok(
      await commit(
        previewOf(
          batchOf(
            [buy('b')],
            instruments: [instrument(name: 'Fondo Prueba Acc')],
          ),
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
      ok(await commit(previewOf(batchOf([buy('a'), buy('b')]))));
      final result = ok(
        await commit(
          previewOf(batchOf([buy('a', funding: Funding.inKind), buy('b')])),
        ),
      );
      expect(result.counts.imported, 0);
      final funding = {
        for (final r in await entries()) r.externalId: r.funding,
      };
      expect(funding, {'a': 'IN_KIND', 'b': 'CASH'});
    },
  );

  test('an in-kind row never goes back to cash', () async {
    ok(await commit(previewOf(batchOf([buy('a', funding: Funding.inKind)]))));
    ok(await commit(previewOf(batchOf([buy('a')]))));
    expect((await entries()).single.funding, 'IN_KIND');
  });

  test('a swap counts as one operation', () async {
    final legs = [
      buy('s1', type: TradeType.sell, swap: 'x'),
      buy('s2', swap: 'x'),
    ];
    final first = ok(
      await commit(previewOf(batchOf(legs, operationOf: [0, 0]))),
    );
    expect((first.counts.imported, first.counts.duplicates), (1, 0));
    final again = ok(
      await commit(previewOf(batchOf(legs, operationOf: [0, 0]))),
    );
    expect((again.counts.imported, again.counts.duplicates), (0, 1));
  });

  test('a failed write leaves nothing behind', () async {
    final result = await commit(
      previewOf(batchOf([buy('a'), buy('b', instrumentId: 'XX00QMISSING')])),
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
    final result = await commit(previewOf(batchOf([buy('a'), foreign])));
    final failure = (result as Err).failure;
    expect(failure, isA<InvalidLedgerEventFailure>());
    expect((failure as InvalidLedgerEventFailure).currency, 'USD');
    expect(failure.day, '2026-03-02');
    expect(await entries(), isEmpty);
  });

  test('the sample export goes through the adapter and imports once', () async {
    final plan = PlanImport(repository, const EnsureRates(_Offline()));
    final preview = ok(await plan(repository.sampleFile(at), now: at));
    expect(preview.ratesUnavailable, ['USD']);
    expect(
      preview.batch.discarded.keys,
      containsAll([
        DiscardReason.fxUnavailable,
        DiscardReason.cardSpending,
        DiscardReason.unsupportedAssetClass,
        DiscardReason.savebackUnpaired,
      ]),
    );
    expect(preview.batch.errors.single.reason, RowErrorReason.wrongFieldCount);
    final result = ok(await commit(preview));
    expect(
      result.counts.imported,
      6,
      reason: 'a saveback and its purchase are one',
    );
    final types = {for (final r in await entries()) r.type};
    expect(types, {'DEPOSIT', 'BUY', 'SELL', 'DIVIDEND', 'INTEREST'});

    final again = ok(await plan(repository.sampleFile(at), now: at));
    expect((again.counts.imported, again.counts.duplicates), (0, 6));
  });

  test('the context reads the residence zone and the stored rates', () async {
    await db.customStatement(
      'INSERT INTO "FxRate" ("id", "base", "quote", "day", "rate", "source", '
      '"createdAt") VALUES (\'r1\', \'EUR\', \'USD\', \'2026-03-02\', '
      '\'1.0500\', \'ECB\', \'2026-03-02T00:00:00.000Z\')',
    );
    final context = ok(await repository.context());
    expect(context.zone, 'Europe/Madrid');
    expect(context.rates['USD']!.single.rate.text, '1.0500');
  });
}

class _Offline implements FxRepository {
  const _Offline();

  @override
  Future<Result<({String? first, String? last})>> span(String quote) async =>
      const Ok((first: null, last: null));

  @override
  Future<Result<List<FxRate>>> fetch(String q, String f, String t) async =>
      const Err(NetworkFailure());

  @override
  Future<Result<FxWritePlan>> save(String quote, List<FxRate> rates) =>
      throw UnimplementedError();

  @override
  Future<Result<RateBook>> book(List<String> quotes) async => const Ok({});
}
