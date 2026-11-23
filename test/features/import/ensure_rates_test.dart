import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/fx_repository_impl.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';
import 'ecb_test.dart' show ecbBody, ecbRow;

final now = DateTime.utc(2026, 3, 20, 12);
const zone = 'Europe/Madrid';

void main() {
  late QuoinDatabase db;
  late List<Uri> asked;
  late Map<String, http.Response Function()> answers;
  late EnsureRates ensure;

  setUp(() {
    db = memoryDatabase();
    asked = [];
    answers = {};
    final client = MockClient((request) async {
      asked.add(request.url);
      final quote = request.url.pathSegments.last.split('.')[1];
      return answers[quote]!();
    });
    ensure = EnsureRates(
      FxRepositoryImpl(EcbRemoteDataSource(client), FxLocalDataSource(db)),
    );
  });
  tearDown(() => db.close());

  final later = now.add(const Duration(minutes: 16));

  Future<EnsuredRates> run(
    Map<String, String> needs, {
    DateTime? at,
    bool withBook = true,
  }) async => switch (await ensure(
    needs,
    now: at ?? now,
    zone: zone,
    withBook: withBook,
  )) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError('$failure'),
  };

  test('syncStart', () {
    const empty = (first: null, last: null);
    const stored = (first: '2026-03-02', last: '2026-03-10');
    expect(syncStart('2026-02-20', '2026-02-27', empty), '2026-02-20');
    expect(syncStart('2026-02-20', '2026-02-27', stored), '2026-02-20');
    expect(syncStart('2026-02-28', '2026-03-07', stored), '2026-03-10');
  });

  test('euros need nothing and ask for nothing', () async {
    final ensured = await run({'EUR': '2026-03-02'});
    expect(ensured.book, isEmpty);
    expect(asked, isEmpty);
  });

  test(
    'a first fetch starts a week before the first use, up to today',
    () async {
      answers['USD'] = () => http.Response(
        ecbBody([ecbRow('2026-03-02', '1.08'), ecbRow('2026-03-03', '1.09')]),
        200,
      );
      final ensured = await run({'USD': '2026-03-03'});
      expect(asked.single.queryParameters['startPeriod'], '2026-02-24');
      expect(asked.single.queryParameters['endPeriod'], '2026-03-20');
      expect(ensured.unavailable, isEmpty);
      expect(ensured.book['USD']!.map((r) => r.day), [
        '2026-03-02',
        '2026-03-03',
      ]);
      expect(await db.select(db.fxRate).get(), hasLength(2));
    },
  );

  test('a later fetch starts at the last stored day', () async {
    answers['USD'] = () =>
        http.Response(ecbBody([ecbRow('2026-03-02', '1.08')]), 200);
    await run({'USD': '2026-03-03'});
    answers['USD'] = () => http.Response(
      ecbBody([ecbRow('2026-03-02', '1.08'), ecbRow('2026-03-04', '1.1')]),
      200,
    );
    final ensured = await run({'USD': '2026-03-04'}, at: later);
    expect(asked.last.queryParameters['startPeriod'], '2026-03-02');
    expect(ensured.book['USD'], hasLength(2));
  });

  test('a currency the service cannot give is listed, not an error', () async {
    answers['USD'] = () => http.Response('down', 503);
    answers['GBP'] = () => http.Response(
      ecbBody([ecbRow('2026-03-02', '0.85', currency: 'GBP')]),
      200,
    );
    final ensured = await run({'USD': '2026-03-03', 'GBP': '2026-03-03'});
    expect(ensured.unavailable, ['USD']);
    expect(ensured.book.keys, ['GBP']);
  });

  test('a revised rate never overwrites the stored one', () async {
    answers['USD'] = () =>
        http.Response(ecbBody([ecbRow('2026-03-02', '1.08')]), 200);
    await run({'USD': '2026-03-03'});
    answers['USD'] = () => http.Response(
      ecbBody([ecbRow('2026-03-02', '1.07'), ecbRow('2026-03-03', '1.1')]),
      200,
    );
    final ensured = await run({'USD': '2026-03-03'}, at: later);
    expect(ensured.book['USD']!.single.rate, Dec.parse('1.08'));
    expect(ensured.conflicts, [(currency: 'USD', day: '2026-03-02')]);
    expect(ensured.unavailable, isEmpty);
  });

  test('a series that holds the newest published day asks nothing', () async {
    answers['USD'] = () => http.Response(
      ecbBody([ecbRow('2026-03-19', '1.08'), ecbRow('2026-03-20', '1.09')]),
      200,
    );
    await run({'USD': '2026-03-19'}, at: DateTime.utc(2026, 3, 20, 17));
    asked.clear();

    final ensured = await run({
      'USD': '2026-03-19',
    }, at: DateTime.utc(2026, 3, 21, 10));
    expect(asked, isEmpty, reason: 'a Saturday: the Friday rate is the newest');
    expect(ensured.book['USD'], hasLength(2));
  });

  test('an answer without the expected day is not asked again for 15 '
      'minutes', () async {
    answers['USD'] = () =>
        http.Response(ecbBody([ecbRow('2026-03-18', '1.08')]), 200);
    await run({'USD': '2026-03-19'});
    expect(asked, hasLength(1));

    await run({'USD': '2026-03-19'}, at: now.add(const Duration(minutes: 14)));
    expect(asked, hasLength(1));

    await run({'USD': '2026-03-19'}, at: now.add(const Duration(minutes: 15)));
    expect(asked, hasLength(2));
  });

  test('a first use before the stored series asks even while held', () async {
    answers['USD'] = () =>
        http.Response(ecbBody([ecbRow('2026-03-18', '1.08')]), 200);
    await run({'USD': '2026-03-19'});
    await run({'USD': '2026-01-15'});
    expect(asked, hasLength(2));
    expect(asked.last.queryParameters['startPeriod'], '2026-01-08');
  });

  test('without the book, the stored series is not read back', () async {
    answers['USD'] = () =>
        http.Response(ecbBody([ecbRow('2026-03-19', '1.08')]), 200);
    final ensured = await run({'USD': '2026-03-19'}, withBook: false);
    expect(ensured.book, isEmpty);
    expect(await db.select(db.fxRate).get(), hasLength(1));
  });
}
