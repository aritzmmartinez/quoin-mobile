import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/pairing_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/prices_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:quoin/src/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';
import 'fake_pc.dart';

const pcFund = 'XX00TEST0002';
const phoneFund = 'XX00TEST0001';
const pcMark = '001761600000000-0000-dev-pc';

final qr = jsonEncode({
  'v': 1,
  'host': 'pc.test',
  'port': 3443,
  'sha256': 'ab' * 32,
  'token': FakePc.qrToken,
  'name': 'Test PC',
});

T ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw StateError('$failure'),
};

Failure err<T>(Result<T> result) => switch (result) {
  Ok(:final value) => throw StateError('expected a failure, got $value'),
  Err(:final failure) => failure,
};

void main() {
  late QuoinDatabase db;
  late PricesDatabase prices;
  late FakePc pc;
  late SyncRepositoryImpl repository;
  late SyncNow syncNow;
  late String phoneId;
  late List<Map<String, String>> ratesAsked;
  late List<Duration> waited;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = memoryDatabase();
    prices = memoryPrices();
    final identity = DeviceIdentityDataSource(
      db,
      Directory.systemTemp.createTempSync('quoin-sync-'),
    );
    phoneId = await identity.claim();
    pc = FakePc(
      const SyncState(
        deviceId: 'dev-pc',
        instruments: [
          InstrumentRecord(
            id: pcFund,
            name: 'PC Fund',
            type: 'ETF',
            quoteSymbol: 'PCF.DE',
            quoteSymbolHlc: pcMark,
          ),
        ],
        settings: SettingsRecord(residence: 'bizkaia'),
      ),
    );
    ratesAsked = [];
    waited = [];
    Future<void> wait(Duration d) async => waited.add(d);
    Future<Result<List<String>>> rates(
      Map<String, String> needs, {
      required String zone,
    }) async {
      ratesAsked.add(needs);
      return const Ok([]);
    }

    repository = SyncRepositoryImpl(
      pairings: const PairingLocalDataSource(FlutterSecureStorage()),
      remote: SyncRemoteDataSource(clientFor: (_) => pc.client, wait: wait),
      local: SyncLocalDataSource(db),
      identity: identity,
      prices: PricesLocalDataSource(db, prices),
      now: () => DateTime.utc(2026, 11, 8, 10),
    );
    syncNow = SyncNow(
      repository,
      RunEffects(rates, repository.dropPrices),
      PullPrices(repository, rates, wait: wait),
      now: () => DateTime.utc(2026, 11, 8, 10),
    );
  });
  tearDown(() async {
    await db.close();
    await prices.close();
  });

  Future<void> addPhoneFund({String? ter, String? terHlc}) => db
      .into(db.instrument)
      .insert(
        InstrumentCompanion.insert(
          id: phoneFund,
          name: 'Phone Fund',
          type: 'ETF',
          ter: Value(ter),
          terHlc: Value(terHlc),
          createdAt: DateTime.utc(2026, 1, 5),
        ),
      );

  Future<Pairing> pair() async {
    final pairing = PairWithPc(repository);
    final start = ok(await pairing.start(qr));
    return ok(
      await pairing.confirm(
        start,
        name: 'Test phone',
        now: DateTime.utc(2026, 11, 8, 9),
      ),
    );
  }

  Future<List<String>> ids() async =>
      [for (final i in await db.select(db.instrument).get()) i.id]..sort();

  List<String> pcIds() =>
      [for (final i in pc.device.state.instruments) i.id]..sort();

  group('pairing', () {
    test('shows the code of the token and this device, and keeps the device '
        'token', () async {
      final pairing = PairWithPc(repository);
      final start = ok(await pairing.start(qr));
      expect(start.deviceId, phoneId);
      expect(start.code, pairingCode(FakePc.qrToken, phoneId));

      final paired = ok(
        await pairing.confirm(
          start,
          name: 'Test phone',
          now: DateTime.utc(2026),
        ),
      );

      expect(paired.token, FakePc.deviceToken);
      expect(paired.pcName, 'Test PC');
      expect(paired.confirmed, isFalse);
      expect(pc.bodies['POST /v1/pair'], [
        {'token': FakePc.qrToken, 'deviceId': phoneId, 'name': 'Test phone'},
      ]);
      expect(ok(await repository.pairing())?.token, FakePc.deviceToken);
    });

    test(
      'a code that is not a Quoin QR is refused before any request',
      () async {
        final result = await PairWithPc(repository).start('{"v":2}');
        expect(err(result), isA<InvalidQrFailure>());
        expect(pc.log, isEmpty);
      },
    );

    test(
      'a PC that reads only newer exchanges asks to update the app',
      () async {
        pc.versions = const [2];
        final failure = err(await PairWithPc(repository).start(qr));
        expect(failure, isA<UpdateRequiredFailure>());
        expect((failure as UpdateRequiredFailure).side, UpdateSide.app);
      },
    );

    test('a used token, a rejection and a timeout each say so', () async {
      final pairing = PairWithPc(repository);
      final start = ok(await pairing.start(qr));
      for (final (status, code, expected) in [
        (401, 'invalid-token', isA<PairingTokenUsedFailure>()),
        (403, 'rejected', isA<PairingRejectedFailure>()),
        (410, 'expired', isA<PairingExpiredFailure>()),
      ]) {
        pc.scripted['POST /v1/pair'] = [
          (status, {'error': code}, const {}),
        ];
        expect(
          err(await pairing.confirm(start, name: 'P', now: DateTime.utc(2026))),
          expected,
        );
      }
      expect(ok(await repository.pairing()), isNull);
    });
  });

  group('sync', () {
    test('needs a pairing', () async {
      expect(err(await syncNow()), isA<NotPairedFailure>());
      expect(pc.log, isEmpty);
    });

    test(
      'the first sync previews both directions and writes nothing',
      () async {
        await addPhoneFund();
        await pair();

        final preview = ok(await syncNow()) as SyncPreview;

        expect(preview.toPhone.newInstruments, 1);
        expect(preview.toPc.newInstruments, 1);
        expect(await ids(), [phoneFund]);
        expect(pcIds(), [pcFund]);
        expect(pc.log, isNot(contains('POST /v1/sync')));
        expect(ok(await repository.pairing())!.confirmed, isFalse);
      },
    );

    test('confirmed, both sides hold the merge; later syncs apply without '
        'asking', () async {
      await addPhoneFund();
      await pair();

      final done = ok(await syncNow(confirm: true)) as SyncDone;

      expect(done.counts.newInstruments, 1);
      expect(await ids(), [phoneFund, pcFund]);
      expect(pcIds(), [phoneFund, pcFund]);
      final pairing = ok(await repository.pairing())!;
      expect(pairing.confirmed, isTrue);
      expect(pairing.lastSyncAt, DateTime.utc(2026, 11, 8, 10));

      pc.log.clear();
      expect(ok(await syncNow()), isA<SyncDone>());
      expect(pc.log, contains('POST /v1/sync'));
    });

    test('when the PC changes in between, starts again once', () async {
      await pair();
      pc.beforePush = () => pc.device = LocalDevice(
        state: SyncState(
          deviceId: 'dev-pc',
          instruments: [
            ...pc.device.state.instruments,
            const InstrumentRecord(
              id: 'XX00TEST0003',
              name: 'New',
              type: 'ETF',
            ),
          ],
          settings: pc.device.state.settings,
        ),
        lastHlc: pc.device.lastHlc,
      );

      expect(ok(await syncNow(confirm: true)), isA<SyncDone>());
      expect(pc.log.where((l) => l == 'GET /v1/sync'), hasLength(2));
      expect(await ids(), [pcFund, 'XX00TEST0003']);
    });

    test('twice in a row, it stops', () async {
      await pair();
      pc.scripted['POST /v1/sync'] = [
        (409, {'error': 'state-changed'}, const {}),
        (409, {'error': 'state-changed'}, const {}),
      ];
      expect(err(await syncNow(confirm: true)), isA<StateChangedFailure>());
    });

    test('a field changed on both sides is a conflict: nothing is written '
        'until it is settled', () async {
      await addPhoneFund(
        ter: '0.0020',
        terHlc: '001761600060000-0000-$phoneId',
      );
      pc.device = LocalDevice(
        state: SyncState(
          deviceId: 'dev-pc',
          instruments: [
            ...pc.device.state.instruments,
            const InstrumentRecord(
              id: phoneFund,
              name: 'Phone Fund',
              type: 'ETF',
              ter: '0.0030',
              terHlc: '001761600030000-0000-dev-pc',
            ),
          ],
          settings: pc.device.state.settings,
        ),
        lastHlc: null,
      );
      await pair();

      final open = ok(await syncNow(confirm: true)) as SyncConflicts;
      final key = conflictKey(open.conflicts.single);
      expect(key, 'instrument:$phoneFund:ter');
      expect(pc.log, isNot(contains('POST /v1/sync')));
      expect(await ids(), [phoneFund]);

      expect(
        ok(await syncNow(resolutions: {key: Resolution.take}, confirm: true)),
        isA<SyncDone>(),
      );
      final fund = await (db.select(
        db.instrument,
      )..where((i) => i.id.equals(phoneFund))).getSingle();
      expect(fund.ter, '0.0030');
      expect(pcIds(), [phoneFund, pcFund]);
    });

    test('the invented sample never syncs', () async {
      await PortfolioLocalDataSource(db, prices).replaceWithSample(testNow);
      await pair();
      expect(err(await syncNow(confirm: true)), isA<SampleDataFailure>());
      expect(pc.log, isNot(contains('POST /v1/sync')));
    });

    test('the PC\'s refusals say what to do', () async {
      await pair();
      for (final (status, body, expected) in [
        (401, {'error': 'unauthorized'}, isA<PairingRevokedFailure>()),
        (403, {'error': 'revoked'}, isA<PairingRevokedFailure>()),
        (
          400,
          {
            'error': 'unsupported-schema-version',
            'found': 2,
            'supported': [1],
            'update': 'client',
          },
          isA<UpdateRequiredFailure>().having(
            (f) => f.side,
            'side',
            UpdateSide.app,
          ),
        ),
        (
          400,
          {'error': 'unsupported-schema-version', 'update': 'server'},
          isA<UpdateRequiredFailure>().having(
            (f) => f.side,
            'side',
            UpdateSide.quoin,
          ),
        ),
        (500, {'error': 'internal'}, isA<PcRefusedFailure>()),
      ]) {
        pc.scripted['GET /v1/sync'] = [(status, body, const {})];
        expect(err(await syncNow(confirm: true)), expected);
      }
    });

    test(
      'a busy PC is waited for once when it asks for a short wait',
      () async {
        await pair();
        pc.scripted['GET /v1/sync'] = [
          (503, {'error': 'busy'}, {'retry-after': '1'}),
        ];
        expect(ok(await syncNow(confirm: true)), isA<SyncDone>());
        expect(waited.first, const Duration(seconds: 1));

        pc.scripted['GET /v1/sync'] = [
          (429, {'error': 'too-many-attempts'}, {'retry-after': '30'}),
        ];
        waited.clear();
        expect(err(await syncNow()), isA<PcBusyFailure>());
        expect(waited, isEmpty);
      },
    );
  });

  group('prices', () {
    Map<String, Object?> row(String asOf, String price) => {
      'asOf': asOf,
      'price': price,
      'currency': 'USD',
      'source': 'YAHOO',
    };

    Future<List<String>> stored() async => [
      for (final p in await prices.select(prices.priceSnapshot).get())
        '${p.asOf.toUtc().toIso8601String()} ${p.price}',
    ]..sort();

    test('asks again while the PC downloads, writes the series, then fetches '
        'its rates', () async {
      await pair();
      pc.prices[pcFund] = [
        {'instrumentId': pcFund, 'kind': 'pending'},
        {
          'instrumentId': pcFund,
          'kind': 'full',
          'seriesVersion': 'v1',
          'rows': [
            row('2026-11-02T16:30:00.000Z', '10.5'),
            row('2026-11-03T16:30:00.000Z', '11'),
          ],
        },
      ];

      final done = ok(await syncNow(confirm: true)) as SyncDone;

      expect(ok(done.prices).updated, 1);
      expect(ok(done.prices).pending, isEmpty);
      expect(await stored(), [
        '2026-11-02T16:30:00.000Z 10.5',
        '2026-11-03T16:30:00.000Z 11',
      ]);
      expect(ratesAsked, [
        {'USD': '2026-11-02'},
      ]);
      expect(pc.bodies['POST /v1/prices']!.first, {
        'instruments': [
          {'instrumentId': pcFund, 'seriesVersion': null, 'last': null},
        ],
      });

      pc.prices[pcFund] = [
        {
          'instrumentId': pcFund,
          'kind': 'tail',
          'seriesVersion': 'v1',
          'from': '2026-10-27T16:30:00.000Z',
          'rows': [
            row('2026-11-03T16:30:00.000Z', '11.2'),
            row('2026-11-04T16:30:00.000Z', '12'),
          ],
        },
      ];
      ok(await syncNow());
      expect(pc.bodies['POST /v1/prices']!.last, {
        'instruments': [
          {
            'instrumentId': pcFund,
            'seriesVersion': 'v1',
            'last': '2026-11-03T16:30:00.000Z',
          },
        ],
      });
      expect(await stored(), [
        '2026-11-03T16:30:00.000Z 11.2',
        '2026-11-04T16:30:00.000Z 12',
      ]);
    });

    test('a new quote symbol drops the old series after the commit', () async {
      await pair();
      pc.prices[pcFund] = [
        {
          'instrumentId': pcFund,
          'kind': 'full',
          'seriesVersion': 'v1',
          'rows': [row('2026-11-02T16:30:00.000Z', '10')],
        },
      ];
      ok(await syncNow(confirm: true));
      // Changed on the PC after it last exported, so the phone takes it.
      const later = '001761600200000-0000-dev-pc';
      final state = pc.device.state;
      pc.device = LocalDevice(
        state: SyncState(
          deviceId: state.deviceId,
          peers: state.peers,
          instruments: [
            for (final i in state.instruments)
              i.id == pcFund
                  ? InstrumentRecord.fromJson({
                      ...i.toJson(),
                      'quoteSymbol': 'NEW.DE',
                      'quoteSymbolHlc': later,
                    })
                  : i,
          ],
          settings: state.settings,
        ),
        lastHlc: later,
      );
      pc.prices[pcFund] = [
        {'instrumentId': pcFund, 'kind': 'pending'},
        {'instrumentId': pcFund, 'kind': 'pending'},
        {'instrumentId': pcFund, 'kind': 'pending'},
        {'instrumentId': pcFund, 'kind': 'pending'},
      ];

      final done = ok(await syncNow()) as SyncDone;

      expect(done.effects.single, isA<EffectDone>());
      expect(await stored(), isEmpty);
      expect(ok(done.prices).pending, [pcFund]);
      expect(pc.bodies['POST /v1/prices']!.last, {
        'instruments': [
          {'instrumentId': pcFund, 'seriesVersion': null, 'last': null},
        ],
      });
    });
  });
}
