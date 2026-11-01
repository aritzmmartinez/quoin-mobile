import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/fx_repository_impl.dart';
import 'package:quoin/src/features/import/data/repositories/import_repository_impl.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';
import 'package:quoin/src/features/import/domain/usecases/plan_import.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show QuoinDatabase;
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

const trHeader =
    'datetime,category,type,asset_class,name,symbol,shares,price,amount,fee,'
    'tax,currency,transaction_id';
const krakenHeader =
    'txid,refid,time,type,subtype,aclass,subclass,asset,wallet,amount,fee,'
    'balance,amountusd,feeusd,balanceusd,feecurrency';
final now = DateTime.utc(2026, 3, 10, 12);

void main() {
  group('decodeExport', () {
    test('UTF-8 with and without a BOM reads the same', () {
      final text = 'name,type\nAcción,BUY\n';
      expect(decodeExport(utf8.encode(text)), text);
      expect(decodeExport([0xEF, 0xBB, 0xBF, ...utf8.encode(text)]), text);
    });

    test('a byte that is not UTF-8 rejects the file', () {
      expect(
        () => decodeExport([...utf8.encode('name\nAcci'), 0xF3, 0x6E]),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  group('PlanImport', () {
    late QuoinDatabase db;
    var requests = 0;
    var online = true;

    setUp(() {
      db = memoryDatabase();
      requests = 0;
      online = true;
    });
    tearDown(() => db.close());

    PlanImport plan() {
      final client = MockClient((request) async {
        requests += 1;
        if (!online) throw http.ClientException('offline');
        return http.Response(
          'KEY,FREQ,CURRENCY,CURRENCY_DENOM,EXR_TYPE,EXR_SUFFIX,TIME_PERIOD,'
          'OBS_VALUE\n'
          'EXR.D.USD.EUR.SP00.A,D,USD,EUR,SP00,A,2026-03-02,1.0800\n',
          200,
        );
      });
      final rates = FxLocalDataSource(db);
      return PlanImport(
        ImportRepositoryImpl(
          const ImportFileDataSource(),
          ImportLocalDataSource(db),
          rates,
        ),
        EnsureRates(FxRepositoryImpl(EcbRemoteDataSource(client), rates)),
      );
    }

    Future<Result<ImportPreview>> run(String text) => plan()(
      ImportFile(name: 'x.csv', size: text.length, text: text),
      now: now,
    );

    Future<Failure> failureOf(String text) async =>
        ((await run(text)) as Err).failure;

    Future<ImportPreview> previewOf(String text) async =>
        switch (await run(text)) {
          Ok(:final value) => value,
          Err(:final failure) => throw StateError('$failure'),
        };

    test('a header with no broker, or both, is unknown', () async {
      expect(
        await failureOf('date,amount\n1,2\n'),
        isA<UnknownBrokerFailure>(),
      );
      expect(
        await failureOf('refid,transaction_id\n1,2\n'),
        isA<UnknownBrokerFailure>(),
      );
    });

    test('a file it cannot read is refused with its reason', () async {
      expect(
        await failureOf(trHeader.replaceAll(',', ';')),
        isA<UnparseableCsvFailure>(),
      );
      expect(
        await failureOf(trHeader.replaceFirst(',asset_class', '')),
        isA<MissingColumnFailure>().having(
          (f) => f.column,
          'column',
          'asset_class',
        ),
      );
      expect(
        await failureOf('txid,refid,time,type,asset,amount,fee,balance\n'),
        isA<KrakenLegacyExportFailure>(),
      );
      expect(
        await failureOf(
          '$krakenHeader\n'
          'L1,D1,2026-03-02 10:00:00,deposit,,currency,fiat,EUR,spot / main,'
          '100,0,100,,,,\n'
          'L2,D2,2026-03-03 10:00:00,deposit,,currency,fiat,EUR,spot / main,'
          '50,0,999,,,,\n',
        ),
        isA<KrakenBalanceMismatchFailure>()
            .having((f) => f.asset, 'asset', 'EUR')
            .having((f) => f.date, 'date', '2026-03-03 10:00:00 UTC'),
      );
      expect(
        await failureOf(
          '$krakenHeader\nL1,D1,2026-03-02 10:00:00,deposit,,currency\n',
        ),
        isA<RowRejectedFailure>()
            .having((f) => f.externalId, 'externalId', 'D1')
            .having((f) => f.reason, 'reason', 'wrong-field-count'),
      );
    });

    test(
      'a row in dollars fetches the rate it lacks and plans again',
      () async {
        final preview = await previewOf(
          '$trHeader\n'
          '2026-03-02T15:00:00Z,TRADING,BUY,STOCK,Acción Prueba,XX00QTEST002,'
          '2,100,-200,-1,,USD,u1\n',
        );
        expect(requests, 1);
        expect(preview.ratesUnavailable, isEmpty);
        expect(preview.imported, 1);
        final event = preview.batch.events.single;
        expect(event.fxSource, FxSource.ecb);
        expect(event.fxRate?.text, '1.0800');
        expect(event.fxDate, '2026-03-02');
      },
    );

    test('offline, the row is set aside and the currency named', () async {
      online = false;
      final preview = await previewOf(
        '$trHeader\n'
        '2026-03-02T15:00:00Z,TRADING,BUY,STOCK,Acción Prueba,XX00QTEST002,'
        '2,100,-200,-1,,USD,u1\n'
        '2026-03-02T16:00:00Z,CASH,CUSTOMER_INPAYMENT,,,,,,500,,,EUR,d1\n',
      );
      expect(preview.ratesUnavailable, ['USD']);
      expect(preview.batch.discarded, {DiscardReason.fxUnavailable: 1});
      expect(preview.batch.ratesNeeded, {'USD': '2026-03-02'});
      expect(preview.imported, 1);
    });

    test(
      'a stored rate the ECB contradicts is named, the row set aside',
      () async {
        await db.customStatement(
          "INSERT INTO \"FxRate\" (\"id\", \"base\", \"quote\", \"day\", "
          "\"rate\", \"source\", \"createdAt\") VALUES ('r1', 'EUR', 'USD', "
          "'2026-03-02', '1.0912', 'ECB', '2026-03-02T00:00:00.000Z')",
        );
        final preview = await previewOf(
          '$trHeader\n'
          '2026-03-03T15:00:00Z,TRADING,BUY,STOCK,Acción Prueba,XX00QTEST002,'
          '2,100,-200,-1,,USD,u1\n',
        );
        expect(requests, 1);
        expect(preview.rateConflicts, [(currency: 'USD', day: '2026-03-02')]);
        expect(preview.ratesUnavailable, isEmpty);
        expect(preview.batch.discarded, {DiscardReason.fxUnavailable: 1});
        expect(await db.select(db.fxRate).get(), hasLength(1));
      },
    );

    test('a file in euros never asks the ECB', () async {
      final preview = await previewOf(
        '$trHeader\n'
        '2026-03-02T16:00:00Z,CASH,CUSTOMER_INPAYMENT,,,,,,500,,,EUR,d1\n',
      );
      expect(requests, 0);
      expect(preview.zone, 'Europe/Madrid');
      expect(preview.imported, 1);
    });
  });
}
