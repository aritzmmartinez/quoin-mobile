import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:drift/drift.dart' show Value;
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/get_portfolio_overview.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/movements_of.dart';
import 'package:quoin_core/quoin_core.dart'
    show Residence, dayOf, otherCategory, rateDayFor, shiftDay;

import '../../helpers.dart';

void main() {
  late QuoinDatabase db;
  late PricesDatabase prices;
  late PortfolioRepositoryImpl repository;

  setUp(() {
    db = memoryDatabase();
    prices = memoryPrices();
    repository = PortfolioRepositoryImpl(PortfolioLocalDataSource(db, prices));
  });
  tearDown(() async {
    await db.close();
    await prices.close();
  });

  Future<PortfolioLedger> load() async => switch (await repository.load()) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError('$failure'),
  };

  test('a new database is empty and resident in Bizkaia', () async {
    final ledger = await load();
    expect(ledger.residence, Residence.bizkaia);
    expect(ledger.events, isEmpty);
  });

  test('the ledger refuses a type the domain cannot read, as Quoin does', () {
    expect(
      db.customStatement(
        'INSERT INTO "LedgerEntry" ("id", "ts", "type", "grossAmount", '
        '"currency", "createdAt") VALUES '
        "('x', '2026-01-01T00:00:00.000Z', 'SPLIT', '0', 'EUR', "
        "'2026-01-01T00:00:00.000Z')",
      ),
      throwsA(anything),
    );
  });

  test('instants are stored as ISO-8601 UTC text', () async {
    await repository.loadSample(testNow);
    final row = await db
        .customSelect('SELECT "ts" FROM "LedgerEntry" LIMIT 1')
        .getSingle();
    expect(
      row.read<String>('ts'),
      matches(RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$')),
    );
  });

  test('the sample portfolio runs the whole chain', () async {
    await repository.loadSample(testNow);
    final overview = overviewOf(await load(), testNow);
    final byName = {for (final h in overview.holdings) h.name: h};

    // 40 + 20 + 15 units for 3600 + 1900 + 1530 and 1 of fees each.
    final fund = byName['Fondo Global Indexado']!;
    expect('${fund.position.quantity}', '75');
    expect('${fund.position.costBasis}', '7033');
    expect('${fund.value.marketValue}', '8131.5');

    // 2170 USD and 1.09 USD of fees at 1.085 per euro: 2000 + 1.00. Its
    // price is in dollars and the sample stores no ECB rate: no value.
    final tech = byName['Ejemplo Tecnología Inc.']!;
    expect('${tech.position.costBasis}', '2001');
    expect(tech.isPriced, isFalse);

    expect(byName.containsKey('Salud Mundial'), isFalse, reason: 'closed');
    expect(byName['Fondo Emergentes']!.isPriced, isFalse);
    expect(byName['Inmobiliario Europa']!.category, otherCategory);
    expect(overview.summary.unpricedCount, 2);
    expect(overview.summary.pricedCount, 6);
    expect(overview.unrated, ['Ejemplo Tecnología Inc.']);
    expect(overview.top, hasLength(topPositions));
  });

  test('each sample reward is a pair whose cash adds up to nothing', () async {
    await repository.loadSample(testNow);
    final inKind = [
      for (final m in movementsOf(await load()))
        if (m.inKind) m,
    ];
    expect(inKind, hasLength(4));
    for (final buy in inKind.where((m) => m.type == 'BUY')) {
      final income = inKind.singleWhere((m) => m.id == '${buy.id}:income');
      expect(income.ts, buy.ts);
      expect(buy.amount!.add(income.amount!).isZero, isTrue, reason: buy.id);
    }
  });

  test('valuation reads only the ECB series, as Quoin does', () async {
    await repository.loadSample(testNow);
    final day = rateDayFor(shiftDay(dayOf(testNow, 'Europe/Madrid'), -1));
    await db
        .into(db.fxRate)
        .insert(
          FxRateCompanion.insert(
            id: 'other',
            base: 'EUR',
            quote: 'USD',
            day: day,
            rate: '1.0912',
            source: 'MANUAL',
            createdAt: testNow,
          ),
        );
    var overview = overviewOf(await load(), testNow);
    expect(overview.unrated, ['Ejemplo Tecnología Inc.'], reason: 'ignored');

    await db
        .into(db.fxRate)
        .insert(
          FxRateCompanion.insert(
            id: 'ecb',
            base: 'EUR',
            quote: 'USD',
            day: day,
            rate: '1.0950',
            source: 'ECB',
            createdAt: testNow,
          ),
        );
    overview = overviewOf(await load(), testNow);
    expect(overview.unrated, isEmpty, reason: 'the same day, two sources');
  });

  test('clearing leaves the empty state', () async {
    await repository.loadSample(testNow);
    await repository.clear();
    expect(overviewOf(await load(), testNow).hasLedger, isFalse);
    expect(await prices.select(prices.priceSnapshot).get(), isEmpty);
  });

  test('the ledger takes the newest price of each instrument', () async {
    PriceSnapshotCompanion price(String id, DateTime asOf, String value) =>
        PriceSnapshotCompanion.insert(
          id: '$id-${asOf.toIso8601String()}',
          instrumentId: id,
          price: value,
          currency: 'EUR',
          asOf: asOf,
          source: const Value('TEST'),
          createdAt: asOf,
        );
    await prices.batch(
      (batch) => batch.insertAll(prices.priceSnapshot, [
        price('XX00TEST0001', DateTime.utc(2026, 10, 2), '11'),
        price('XX00TEST0001', DateTime.utc(2026, 10, 1), '10'),
        price('XX00TEST0001', DateTime.utc(2026, 9, 30, 23), '9'),
        price('XX00TEST0002', DateTime.utc(2026, 9, 1), '5'),
      ]),
    );

    final latest = (await load()).latestPrices;
    expect(
      {
        for (final MapEntry(:key, :value) in latest.entries)
          key: value.price.toString(),
      },
      {'XX00TEST0001': '11', 'XX00TEST0002': '5'},
    );
  });
}
