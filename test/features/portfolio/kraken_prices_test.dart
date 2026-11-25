import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/kraken_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/datasources/kraken_remote_datasource.dart';
import 'package:quoin/src/features/portfolio/data/repositories/kraken_repository_impl.dart';
import 'package:quoin/src/features/portfolio/domain/usecases/pull_kraken_prices.dart';
import 'package:quoin/src/features/sync/data/datasources/prices_local_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

typedef Json = Map<String, Object?>;

Object? contractAnswer(String name) {
  final contract = jsonDecode(
    File('packages/quoin_core/test/contract/kraken.json').readAsStringSync(),
  ) as Json;
  return (contract['cases']! as List<Object?>).cast<Json>().firstWhere(
    (c) => c['name'] == name,
  )['answer'];
}

final ohlc = contractAnswer("The answer may name the pair by Kraken's own key");
final trade = contractAnswer(
  'The last trade is the live quote, dated to the second',
);
final unknown = contractAnswer('An unknown pair is an empty answer');
final now = DateTime.utc(2026, 11, 21, 10);

void main() {
  late QuoinDatabase db;
  late PricesDatabase prices;
  late List<Uri> asked;
  late Object? Function(Uri) answer;

  PullKrakenPrices pass({DateTime? at}) {
    final client = MockClient((request) async {
      asked.add(request.url);
      return http.Response(jsonEncode(answer(request.url)), 200);
    });
    final repository = KrakenRepositoryImpl(
      KrakenRemoteDataSource(client, KrakenQueue(spacing: Duration.zero)),
      KrakenLocalDataSource(db, prices, now: () => at ?? now),
    );
    return PullKrakenPrices(
      repository,
      (needs, {required zone}) async => const Ok([]),
      KrakenHold(),
      now: () => at ?? now,
    );
  }

  PricesLocalDataSource pc({DateTime? at}) =>
      PricesLocalDataSource(db, prices, now: () => at ?? now);

  Future<void> instrument(String id, String type, {String? symbol}) => db
      .into(db.instrument)
      .insert(
        InstrumentCompanion.insert(
          id: id,
          name: id,
          type: type,
          quoteSymbol: Value(symbol),
          createdAt: now,
        ),
      );

  Future<List<String>> rows(String id) async => [
    for (final p in await (prices.select(
      prices.priceSnapshot,
    )..where((p) => p.instrumentId.equals(id))).get())
      '${p.asOf.toUtc().toIso8601String()} ${p.price} ${p.source}',
  ]..sort();

  Future<void> expectOneOwner() async {
    final pcIds = {
      for (final s in await prices.select(prices.priceSeries).get())
        s.instrumentId,
    };
    final krakenIds = {
      for (final k in await prices.select(prices.krakenSeries).get())
        k.instrumentId,
    };
    expect(pcIds.intersection(krakenIds), isEmpty);
  }

  PriceRow pcRow(String asOf, String price) =>
      PriceRow(asOf: asOf, price: price, currency: 'EUR', source: 'YAHOO');

  setUp(() {
    db = memoryDatabase();
    prices = memoryPrices();
    asked = [];
    answer = (url) => url.path.endsWith('OHLC') ? ohlc : trade;
  });
  tearDown(() async {
    await db.close();
    await prices.close();
  });

  test('a crypto with no pair gets candles and the live quote, and its '
      'derived pair is never written to the instrument', () async {
    await instrument('BTC', 'CRYPTO');
    await instrument('XX00TEST0001', 'ETF');

    final result = await pass()();

    expect(result, isA<Ok<KrakenOutcome>>());
    expect(asked.map((u) => u.queryParameters['pair']).toSet(), {'BTC/EUR'});
    expect(await rows('BTC'), [
      '2026-11-20T00:00:00.000Z 53687.6 KRAKEN',
      '2026-11-21T01:40:11.000Z 53736 KRAKEN_LIVE',
    ]);
    expect(await rows('XX00TEST0001'), isEmpty);
    final btc = await (db.select(
      db.instrument,
    )..where((i) => i.id.equals('BTC'))).getSingle();
    expect(btc.quoteSymbol, isNull);
    expect(btc.quoteSymbolHlc, isNull);
    final series = await prices.select(prices.krakenSeries).getSingle();
    expect((series.instrumentId, series.symbol), ('BTC', 'BTC/EUR'));
  });

  test('a PC series with recent candles is left alone', () async {
    await instrument('BTC', 'CRYPTO', symbol: 'BTC-EUR');
    await pc().save([
      FullPrices(
        'BTC',
        seriesVersion: 'v1',
        rows: [pcRow('2026-11-19T00:00:00.000Z', '50000')],
      ),
    ]);

    await pass()();

    expect(asked, isEmpty);
    expect(await rows('BTC'), ['2026-11-19T00:00:00.000Z 50000 YAHOO']);
  });

  test('a PC series with no candle in over 7 days goes to Kraken, and the PC '
      'takes it back when it answers with recent rows', () async {
    await instrument('BTC', 'CRYPTO', symbol: 'BTC-EUR');
    await pc().save([
      FullPrices(
        'BTC',
        seriesVersion: 'v1',
        rows: [pcRow('2026-11-01T00:00:00.000Z', '50000')],
      ),
    ]);

    await pass()();
    expect(await rows('BTC'), [
      '2026-11-20T00:00:00.000Z 53687.6 KRAKEN',
      '2026-11-21T01:40:11.000Z 53736 KRAKEN_LIVE',
    ]);
    expect(await prices.select(prices.priceSeries).get(), isEmpty);
    await expectOneOwner();

    final holding = (await pc().holdings()).single;
    expect(holding.seriesVersion, isNull);
    await pc().save([
      FullPrices(
        'BTC',
        seriesVersion: 'v2',
        rows: [pcRow('2026-11-20T00:00:00.000Z', '53000')],
      ),
    ]);
    expect(await rows('BTC'), ['2026-11-20T00:00:00.000Z 53000 YAHOO']);
    expect(await prices.select(prices.krakenSeries).get(), isEmpty);
    await expectOneOwner();
  });

  test(
    'an empty or stale PC answer never replaces the Kraken series',
    () async {
      await instrument('BTC', 'CRYPTO', symbol: 'BTC-EUR');
      await pass()();
      final kraken = await rows('BTC');

      await pc().save([const FullPrices('BTC', seriesVersion: 'v1', rows: [])]);
      await pc().save([
        FullPrices(
          'BTC',
          seriesVersion: 'v1',
          rows: [pcRow('2026-11-01T00:00:00.000Z', '50000')],
        ),
      ]);

      expect(await rows('BTC'), kraken);
      expect(await prices.select(prices.priceSeries).get(), isEmpty);
      expect(await prices.select(prices.krakenSeries).get(), hasLength(1));
    },
  );

  test('the next day\'s candle removes that day\'s live row', () async {
    await instrument('BTC', 'CRYPTO');
    await pass()();

    final later = DateTime.utc(2026, 11, 22, 10);
    answer = (url) => url.path.endsWith('OHLC')
        ? {
            'error': <Object?>[],
            'result': {
              'XXBTZEUR': [
                [1795219200, '1', '1', '1', '53900.1', '1', '1', 1],
              ],
              'last': 1795219200,
            },
          }
        : {
            'error': <Object?>[],
            'result': {
              'BTC/EUR': [
                ['54000.0', '0.1', 1795341600.5, 's', 'l', '', 1],
              ],
              'last': '1',
            },
          };
    await pass(at: later)();

    expect(asked.last.path, endsWith('Trades'));
    expect(
      asked
          .firstWhere((u) => u.path.endsWith('OHLC') && u != asked.first)
          .queryParameters['since'],
      '${DateTime.utc(2026, 11, 13).millisecondsSinceEpoch ~/ 1000 - 1}',
    );
    expect(await rows('BTC'), [
      '2026-11-20T00:00:00.000Z 53687.6 KRAKEN',
      '2026-11-21T00:00:00.000Z 53900.1 KRAKEN',
      '2026-11-22T10:00:00.000Z 54000 KRAKEN_LIVE',
    ]);
  });

  test('a pair Kraken does not list writes nothing and is not asked again '
      'on the next pass', () async {
    await instrument('NOSUCH', 'CRYPTO');
    answer = (_) => unknown;
    final run = pass();

    await run();
    await run();

    expect(asked, hasLength(2));
    expect(await rows('NOSUCH'), isEmpty);
    expect(await prices.select(prices.krakenSeries).get(), isEmpty);
  });

  test('a rate limit stops the pass with a failure', () async {
    await instrument('BTC', 'CRYPTO');
    await instrument('ETH', 'CRYPTO');
    answer = (_) => {
      'error': ['EGeneral:Too many requests'],
    };

    final result = await pass()();

    expect(result, isA<Err<KrakenOutcome>>());
    expect((result as Err).failure, isA<NetworkFailure>());
    expect(asked, hasLength(1));
  });

  test('dropAll takes every Kraken series and leaves the PC\'s', () async {
    await instrument('BTC', 'CRYPTO');
    await instrument('ETH', 'CRYPTO', symbol: 'ETH-EUR');
    await pc().save([
      FullPrices(
        'ETH',
        seriesVersion: 'v1',
        rows: [pcRow('2026-11-20T00:00:00.000Z', '3000')],
      ),
    ]);
    await pass()();
    expect(await rows('BTC'), isNotEmpty);

    await KrakenLocalDataSource(db, prices).dropAll();

    expect(await rows('BTC'), isEmpty);
    expect(await rows('ETH'), ['2026-11-20T00:00:00.000Z 3000 YAHOO']);
    expect(await prices.select(prices.krakenSeries).get(), isEmpty);
  });

  group('KrakenRemoteDataSource', () {
    test('an answer other than 200 is a NetworkException', () async {
      final remote = KrakenRemoteDataSource(
        MockClient((_) async => http.Response('busy', 503)),
        KrakenQueue(spacing: Duration.zero),
      );
      await expectLater(
        remote.lastTrade('BTC/EUR'),
        throwsA(
          isA<NetworkException>().having((e) => e.statusCode, 'status', 503),
        ),
      );
    });
  });

  group('KrakenQueue', () {
    test('asks one at a time, at least the spacing apart', () async {
      var clock = DateTime.utc(2026, 11, 21);
      final waits = <Duration>[];
      final queue = KrakenQueue(
        now: () => clock,
        wait: (d) async {
          waits.add(d);
          clock = clock.add(d);
        },
      );
      final turns = <DateTime>[];
      await Future.wait([
        for (var i = 0; i < 3; i++) queue.turn().then((_) => turns.add(clock)),
      ]);
      clock = clock.add(const Duration(seconds: 5));
      await queue.turn();

      expect(waits, [krakenSpacing, krakenSpacing]);
      expect(turns, [
        DateTime.utc(2026, 11, 21),
        DateTime.utc(2026, 11, 21, 0, 0, 1),
        DateTime.utc(2026, 11, 21, 0, 0, 2),
      ]);
    });
  });
}
