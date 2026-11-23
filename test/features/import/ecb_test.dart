import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

const header =
    'KEY,FREQ,CURRENCY,CURRENCY_DENOM,EXR_TYPE,EXR_SUFFIX,TIME_PERIOD,OBS_VALUE';

String ecbRow(String day, String value, {String currency = 'USD'}) =>
    'EXR.D.$currency.EUR.SP00.A,D,$currency,EUR,SP00,A,$day,$value';

String ecbBody(List<String> rows) => '$header\n${rows.join('\n')}\n';

void main() {
  group('parseEcbCsv', () {
    test('reads the rates, oldest first, skipping days with no value', () {
      final rates = parseEcbCsv(
        ecbBody([
          ecbRow('2026-03-03', '1.0912'),
          ecbRow('2026-03-02', '1.0850'),
          ecbRow('2026-03-04', ''),
        ]),
        'USD',
      );
      expect(rates.map((r) => r.day), ['2026-03-02', '2026-03-03']);
      expect(rates.first.rate, Dec.parse('1.085'));
      expect(rates.first.source, 'ECB');
      expect(rates.first.base, 'EUR');
      expect(rates.first.quote, 'USD');
    });

    test('an empty body has no rates', () {
      expect(parseEcbCsv('  \n', 'USD'), isEmpty);
    });

    test('anything but daily rates of the asked currency is refused', () {
      for (final body in [
        'FREQ,CURRENCY,TIME_PERIOD\nD,USD,2026-03-02\n',
        ecbBody([ecbRow('2026-03-02', '1.1', currency: 'GBP')]),
        ecbBody(['EXR.M.USD.EUR.SP00.A,M,USD,EUR,SP00,A,2026-03-02,1.1']),
        ecbBody(['EXR.D.USD.JPY.SP00.A,D,USD,JPY,SP00,A,2026-03-02,1.1']),
        ecbBody([ecbRow('2026-03', '1.1')]),
        ecbBody([ecbRow('2026-03-02', '0')]),
        ecbBody([ecbRow('2026-03-02', '1,1')]),
        ecbBody([ecbRow('2026-03-02', '-1.1')]),
      ]) {
        expect(
          () => parseEcbCsv(body, 'USD'),
          throwsA(isA<Exception>()),
          reason: body,
        );
      }
    });
  });

  test('the request is one currency, CSV with the data only', () {
    expect(
      ecbRatesUrl('USD', '2026-03-01', '2026-03-31').toString(),
      'https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A'
      '?startPeriod=2026-03-01&endPeriod=2026-03-31'
      '&format=csvdata&detail=dataonly',
    );
  });

  group('EcbRemoteDataSource', () {
    Future<List<FxRate>> fetch(
      MockClientHandler handler, {
      String quote = 'USD',
      Duration timeout = ecbTimeout,
    }) => EcbRemoteDataSource(
      MockClient(handler),
      timeout: timeout,
    ).rates(quote, '2026-03-01', '2026-03-31');

    test('a 200 is parsed', () async {
      final rates = await fetch(
        (_) async =>
            http.Response(ecbBody([ecbRow('2026-03-02', '1.08')]), 200),
      );
      expect(rates.single.day, '2026-03-02');
    });

    test('a 404 Not Found is a currency the ECB does not publish', () async {
      expect(
        await fetch((_) async => http.Response('{"title":"Not Found"}', 404)),
        isEmpty,
      );
    });

    test('a code that is not ISO-like is not asked for', () async {
      var asked = false;
      final rates = await fetch((_) async {
        asked = true;
        return http.Response('', 200);
      }, quote: 'USDC');
      expect(rates, isEmpty);
      expect(asked, isFalse);
    });

    test('an error, a bad body, a lost connection or a timeout', () async {
      Matcher network([int? status]) => throwsA(
        isA<NetworkException>().having((e) => e.statusCode, 'status', status),
      );
      await expectLater(
        fetch((_) async => http.Response('oops', 500)),
        network(500),
      );
      await expectLater(
        fetch((_) async => http.Response('<html>', 404)),
        network(404),
      );
      await expectLater(
        fetch((_) async => http.Response('FREQ\nD\n', 200)),
        network(200),
      );
      await expectLater(
        fetch((_) async => throw http.ClientException('offline')),
        network(),
      );
      await expectLater(
        fetch(
          (_) => Completer<http.Response>().future,
          timeout: const Duration(milliseconds: 10),
        ),
        network(),
      );
    });
  });
}
