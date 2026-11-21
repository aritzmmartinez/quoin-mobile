import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/set_instrument_category.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin/src/features/sync/domain/entities/exchange_import.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

const fund = 'IE00TEST0004';
const pcMark = '001761599940000-0000-dev-pc';
final at = DateTime.utc(2026, 10, 30, 9);

void main() {
  late QuoinDatabase db;
  late PricesDatabase prices;
  late SetInstrumentCategory classify;

  setUp(() async {
    db = memoryDatabase();
    prices = memoryPrices();
    classify = SetInstrumentCategory(
      PortfolioRepositoryImpl(
        PortfolioLocalDataSource(db, prices, now: () => at),
      ),
    );
    await db
        .into(db.instrument)
        .insert(
          InstrumentCompanion.insert(
            id: fund,
            name: 'Invented World Fund',
            type: 'ETF',
            createdAt: at,
          ),
        );
  });
  tearDown(() async {
    await db.close();
    await prices.close();
  });

  Future<InstrumentRow> stored() =>
      (db.select(db.instrument)..where((i) => i.id.equals(fund))).getSingle();
  Future<String?> lastMark() async =>
      (await db.select(db.syncDevice).getSingle()).lastHlc;
  Future<void> choose(CategoryChoice choice) async =>
      expect(await classify(fund, choice), isA<Ok<void>>());

  test('writes the pair with a fresh mark', () async {
    await choose(CategoryChoice.equityFund);

    final row = await stored();
    expect(row.exposureKind, 'EQUITY_FUND');
    expect(row.exposureLeafId, isNull);
    expect(row.exposureHlc, isNotNull);
    expect(row.exposureHlc, await lastMark());
    expect(parseHlc(row.exposureHlc!).ms, at.millisecondsSinceEpoch);
  });

  test('the same choice again issues no mark', () async {
    await choose(CategoryChoice.bondFund);
    final mark = await lastMark();

    await choose(CategoryChoice.bondFund);

    expect(await lastMark(), mark);
    expect((await stored()).exposureHlc, mark);
  });

  test('Automatic clears both with a mark, and only when set', () async {
    await choose(CategoryChoice.automatic);
    expect(await lastMark(), isNull);

    await choose(CategoryChoice.equityFund);
    final chosen = await lastMark();
    await choose(CategoryChoice.automatic);

    final row = await stored();
    expect(row.exposureKind, isNull);
    expect(row.exposureLeafId, isNull);
    expect(row.exposureHlc, await lastMark());
    expect(row.exposureHlc!.compareTo(chosen!), isPositive);
  });

  test('leaving a commodity set on the PC clears its leaf', () async {
    await (db.update(db.instrument)..where((i) => i.id.equals(fund))).write(
      const InstrumentCompanion(
        exposureKind: Value('COMMODITY'),
        exposureLeafId: Value('XAU'),
        exposureHlc: Value(pcMark),
      ),
    );

    await choose(CategoryChoice.equityFund);

    final row = await stored();
    expect(row.exposureKind, 'EQUITY_FUND');
    expect(row.exposureLeafId, isNull);
    expect(row.exposureHlc, isNot(pcMark));
    expect(row.exposureHlc, await lastMark());
  });

  test('a missing instrument is a storage failure, with no mark', () async {
    expect(
      await classify('XX00NONE0000', CategoryChoice.equityFund),
      isA<Err<void>>(),
    );
    expect(await lastMark(), isNull);
  });

  group('sync', () {
    late SyncLocalDataSource store;

    setUp(() => store = SyncLocalDataSource(db, now: () => at));

    Exchange fromPc(String kind) => Exchange.of(
      SyncState(
        deviceId: 'dev-pc',
        peers: const [],
        ledger: const [],
        instruments: [
          InstrumentRecord(
            id: fund,
            name: 'Invented World Fund',
            type: 'ETF',
            exposureKind: kind,
            exposureHlc: formatHlc((
              ms: at.millisecondsSinceEpoch + 60000,
              counter: 0,
              deviceId: 'dev-pc',
            )),
          ),
        ],
        settings: const SettingsRecord(residence: 'bizkaia'),
      ),
      exportHlc: formatHlc((
        ms: at.millisecondsSinceEpoch + 120000,
        counter: 0,
        deviceId: 'dev-pc',
      )),
    );

    test('the exchange carries the chosen pair and its mark', () async {
      await choose(CategoryChoice.bondFund);
      final mark = (await stored()).exposureHlc;

      final sent = (await store.export()).instruments.single;

      expect(sent.exposureKind, 'BOND_FUND');
      expect(sent.exposureLeafId, isNull);
      expect(sent.exposureHlc, mark);
    });

    test(
      'a change on the PC meanwhile is a conflict to keep or take',
      () async {
        await choose(CategoryChoice.equityFund);
        final key = 'instrument:$fund:exposure';

        final open = await store.importExchange(
          fromPc('BOND_FUND'),
          dryRun: false,
          nowMs: at.millisecondsSinceEpoch,
        );
        expect(open.status, ImportStatus.conflicts);
        expect([for (final c in open.plan.conflicts) conflictKey(c)], [key]);
        expect((await stored()).exposureKind, 'EQUITY_FUND');

        final taken = await store.importExchange(
          fromPc('BOND_FUND'),
          resolutions: {key: Resolution.take},
          dryRun: false,
          nowMs: at.millisecondsSinceEpoch,
        );
        expect(taken.status, ImportStatus.applied);
        expect((await stored()).exposureKind, 'BOND_FUND');
      },
    );
  });
}
