import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/datasources/prices_local_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

void main() {
  late QuoinDatabase db;
  late PricesDatabase prices;
  late PricesLocalDataSource store;

  setUp(() {
    db = memoryDatabase();
    prices = memoryPrices();
    store = PricesLocalDataSource(db, prices);
  });
  tearDown(() async {
    await db.close();
    await prices.close();
  });

  PriceRow row(String asOf, String price) =>
      PriceRow(asOf: asOf, price: price, currency: 'EUR', source: 'YAHOO');

  Future<List<String>> indexes() async => [
    for (final r
        in await prices
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND tbl_name = 'PriceSnapshot' AND name NOT LIKE 'sqlite_%'",
            )
            .get())
      r.read<String>('name'),
  ]..sort();

  Future<List<String>> stored() async => [
    for (final p in await prices.select(prices.priceSnapshot).get())
      '${p.instrumentId} ${p.asOf.toUtc().toIso8601String()} ${p.price}',
  ]..sort();

  test('a full series is written whole and leaves every index in place, and '
      'a tail then replaces what it covers', () async {
    final before = await indexes();
    expect(before, [
      'PriceSnapshot_asOf_idx',
      'PriceSnapshot_instrumentId_asOf_key',
      'PriceSnapshot_instrumentId_idx',
    ]);

    await store.save([
      FullPrices(
        'XX00TEST0001',
        seriesVersion: 'v1',
        rows: [
          row('2026-11-02T16:30:00.000Z', '10'),
          row('2026-11-03T16:30:00.000Z', '11'),
        ],
      ),
    ]);
    expect(await indexes(), before);

    await store.save([
      TailPrices(
        'XX00TEST0001',
        seriesVersion: 'v1',
        from: '2026-11-03T16:30:00.000Z',
        rows: [
          row('2026-11-03T16:30:00.000Z', '11.5'),
          row('2026-11-04T16:30:00.000Z', '12'),
        ],
      ),
    ]);
    expect(await stored(), [
      'XX00TEST0001 2026-11-02T16:30:00.000Z 10',
      'XX00TEST0001 2026-11-03T16:30:00.000Z 11.5',
      'XX00TEST0001 2026-11-04T16:30:00.000Z 12',
    ]);

    await store.save([
      FullPrices(
        'XX00TEST0001',
        seriesVersion: 'v2',
        rows: [row('2026-11-04T16:30:00.000Z', '13')],
      ),
    ]);
    expect(await stored(), ['XX00TEST0001 2026-11-04T16:30:00.000Z 13']);
    expect(await indexes(), before);
  });
}
