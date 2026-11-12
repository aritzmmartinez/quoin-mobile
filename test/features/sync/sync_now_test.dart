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
import 'package:quoin/src/features/sync/domain/usecases/finish_sync.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/domain/usecases/pc_identity.dart';
import 'package:quoin/src/features/sync/domain/usecases/pull_prices.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin/src/features/sync/domain/usecases/unpair.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';
import 'fake_pc.dart';

const pcFund = 'XX00TEST0002';
const phoneFund = 'XX00TEST0001';
const pcMark = '001761600000000-0000-dev-pc';

final pcSha = 'ab' * 32;

final pc2Sha = 'cd' * 32;

String qrOf(String host, String sha256, String name) => jsonEncode({
  'v': 1,
  'host': host,
  'port': 3443,
  'sha256': sha256,
  'token': FakePc.qrToken,
  'name': name,
});

final qr2 = qrOf('pc2.test', pc2Sha, 'Second PC');

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
  late FakePc pc2;
  late SyncRepositoryImpl repository;
  late Future<Result<SyncPass>> Function({
    Map<String, Resolutions> resolutions,
    Set<String> confirm,
  })
  syncNow;
  late SyncFollowUp lastFollowUp;
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
    pc2 = FakePc(
      const SyncState(
        deviceId: 'dev-pc2',
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
      remote: SyncRemoteDataSource(
        clientFor: (e) => (e.host == 'pc2.test' ? pc2 : pc).client,
        wait: wait,
      ),
      local: SyncLocalDataSource(db),
      identity: identity,
      prices: PricesLocalDataSource(db, prices),
      now: () => DateTime.utc(2026, 11, 8, 10),
    );
    final pass = SyncNow(
      repository,
      PcIdentity(repository),
      now: () => DateTime.utc(2026, 11, 8, 10),
    );
    final finish = FinishSync(
      repository,
      RunEffects(rates, repository.dropPrices),
      PullPrices(repository, rates, wait: wait),
    );
    // As SyncController: the pass, then its follow-up.
    syncNow = ({resolutions = const {}, confirm = const {}}) async {
      final result = await pass(resolutions: resolutions, confirm: confirm);
      if (result case Ok(value: final done)) {
        lastFollowUp = await finish(done);
      }
      return result;
    };
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

  Future<Pairing> pair([String? text]) async {
    final pairing = PairWithPc(repository);
    final start = ok(await pairing.start(text ?? qr));
    return ok(
      await pairing.confirm(
        start,
        name: 'Test phone',
        now: DateTime.utc(2026, 11, 8, 9),
      ),
    );
  }

  Future<Result<SyncOutcome>> syncOne({
    Resolutions resolutions = const {},
    bool confirm = false,
  }) async {
    final result = await syncNow(
      resolutions: {pcSha: resolutions},
      confirm: {if (confirm) pcSha},
    );
    return switch (result) {
      Ok(value: final pass) => pass.pcs.single.result,
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<Pairing?>> storedPairing([String? sha]) async =>
      switch (await repository.pairings()) {
        Ok(:final value) => Ok(value.of(sha ?? pcSha)),
        Err(:final failure) => Err(failure),
      };

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
      expect(ok(await storedPairing())?.token, FakePc.deviceToken);
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
      expect(ok(await storedPairing()), isNull);
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

        final preview = ok(await syncOne()) as SyncPreview;

        expect(preview.toPhone.newInstruments, 1);
        expect(preview.toPc.newInstruments, 1);
        expect(await ids(), [phoneFund]);
        expect(pcIds(), [pcFund]);
        expect(pc.log, isNot(contains('POST /v1/sync')));
        expect(ok(await storedPairing())!.confirmed, isFalse);
      },
    );

    test('confirmed, both sides hold the merge; later syncs apply without '
        'asking', () async {
      await addPhoneFund();
      await pair();

      final done = ok(await syncOne(confirm: true)) as SyncDone;

      expect(done.counts.newInstruments, 1);
      expect(await ids(), [phoneFund, pcFund]);
      expect(pcIds(), [phoneFund, pcFund]);
      final pairing = ok(await storedPairing())!;
      expect(pairing.confirmed, isTrue);
      expect(pairing.lastSyncAt, DateTime.utc(2026, 11, 8, 10));

      pc.log.clear();
      expect(ok(await syncOne()), isA<SyncDone>());
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

      expect(ok(await syncOne(confirm: true)), isA<SyncDone>());
      expect(pc.log.where((l) => l == 'GET /v1/sync'), hasLength(2));
      expect(await ids(), [pcFund, 'XX00TEST0003']);
    });

    test('twice in a row, it stops', () async {
      await pair();
      pc.scripted['POST /v1/sync'] = [
        (409, {'error': 'state-changed'}, const {}),
        (409, {'error': 'state-changed'}, const {}),
      ];
      expect(err(await syncOne(confirm: true)), isA<StateChangedFailure>());
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

      final open = ok(await syncOne(confirm: true)) as SyncConflicts;
      final key = conflictKey(open.conflicts.single);
      expect(key, 'instrument:$phoneFund:ter');
      expect(pc.log, isNot(contains('POST /v1/sync')));
      expect(await ids(), [phoneFund]);

      expect(
        ok(await syncOne(resolutions: {key: Resolution.take}, confirm: true)),
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
      expect(err(await syncOne(confirm: true)), isA<SampleDataFailure>());
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
        expect(err(await syncOne(confirm: true)), expected);
      }
    });

    test(
      'a busy PC is waited for once when it asks for a short wait',
      () async {
        await pair();
        pc.scripted['GET /v1/sync'] = [
          (503, {'error': 'busy'}, {'retry-after': '1'}),
        ];
        expect(ok(await syncOne(confirm: true)), isA<SyncDone>());
        expect(waited.first, const Duration(seconds: 1));

        pc.scripted['GET /v1/sync'] = [
          (429, {'error': 'too-many-attempts'}, {'retry-after': '30'}),
        ];
        waited.clear();
        expect(err(await syncOne()), isA<PcBusyFailure>());
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

      expect(ok(await syncOne(confirm: true)), isA<SyncDone>());

      expect(ok(lastFollowUp.prices!).updated, 1);
      expect(ok(lastFollowUp.prices!).pending, isEmpty);
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
      ok(await syncOne());
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
      ok(await syncOne(confirm: true));
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

      expect(ok(await syncOne()), isA<SyncDone>());

      expect(lastFollowUp.effects.single, isA<EffectDone>());
      expect(await stored(), isEmpty);
      expect(ok(lastFollowUp.prices!).pending, [pcFund]);
      expect(pc.bodies['POST /v1/prices']!.last, {
        'instruments': [
          {'instrumentId': pcFund, 'seriesVersion': null, 'last': null},
        ],
      });
    });
  });

  group('several PCs', () {
    const pc2Fund = 'XX00TEST0004';

    Future<SyncPass> pass({
      Map<String, Resolutions> resolutions = const {},
      Set<String> confirm = const {},
    }) async => ok(await syncNow(resolutions: resolutions, confirm: confirm));

    Result<SyncOutcome> of(SyncPass pass, String sha) =>
        pass.pcs.firstWhere((p) => p.pairing.sha256 == sha).result;

    void named(FakePc fake, String deviceId, {List<InstrumentRecord>? add}) {
      final state = fake.device.state;
      fake.device = LocalDevice(
        state: SyncState(
          deviceId: deviceId,
          peers: state.peers,
          instruments: [...state.instruments, ...?add],
          settings: state.settings,
        ),
        lastHlc: fake.device.lastHlc,
      );
    }

    Future<Pairings> stored() async => ok(await repository.pairings());

    setUp(() {
      named(
        pc2,
        'dev-pc2',
        add: [
          const InstrumentRecord(
            id: pc2Fund,
            name: 'Second Fund',
            type: 'ETF',
            quoteSymbol: 'SEC.DE',
            quoteSymbolHlc: '001761600000000-0000-dev-pc2',
          ),
        ],
      );
    });

    test('a pairing of an earlier version moves into the list, token and '
        'all, so the phone never pairs again', () async {
      final legacy = jsonEncode({
        'host': 'pc.test',
        'port': 3443,
        'sha256': pcSha,
        'token': FakePc.deviceToken,
        'pcName': 'Test PC',
        'pairedAt': '2026-11-01T09:00:00.000Z',
        'lastSyncAt': '2026-11-07T09:00:00.000Z',
        'confirmed': true,
      });
      FlutterSecureStorage.setMockInitialValues({'pairing': legacy});

      final pairings = await stored();

      expect(pairings.pcs.single.token, FakePc.deviceToken);
      expect(pairings.pcs.single.confirmed, isTrue);
      expect(await const FlutterSecureStorage().read(key: 'pairing'), isNull);
      expect(ok(await syncOne()), isA<SyncDone>());
      expect(pc.log, isNot(contains('POST /v1/pair')));
    });

    test('a move cut short keeps the list and drops the old key', () async {
      FlutterSecureStorage.setMockInitialValues({
        'pairing': '{}',
        'pairings': jsonEncode({'pcs': <Object?>[], 'pricesFrom': null}),
      });
      expect((await stored()).pcs, isEmpty);
      expect(await const FlutterSecureStorage().read(key: 'pairing'), isNull);
    });

    test('a restored phone arrives with nothing to move', () async {
      FlutterSecureStorage.setMockInitialValues({});
      expect((await stored()).pcs, isEmpty);
      expect(err(await syncNow()), isA<NotPairedFailure>());
    });

    test('each PC previews on its own; once confirmed, one pass carries each '
        'PC changes to the other', () async {
      await pair();
      await pair(qr2);

      final first = await pass();
      expect(first.waiting, hasLength(2));
      expect(pc.log, isNot(contains('POST /v1/sync')));

      final done = await pass(confirm: {pcSha, pc2Sha});
      expect(done.pcs.every((p) => p.done), isTrue);
      expect(await ids(), [pcFund, pc2Fund]);
      expect(pcIds(), [pcFund, pc2Fund]);
      expect([for (final i in pc2.device.state.instruments) i.id]..sort(), [
        pcFund,
        pc2Fund,
      ]);
    });

    test('a PC that does not answer never stops the other', () async {
      await pair();
      await pair(qr2);
      await pass(confirm: {pcSha, pc2Sha});

      pc.offline = true;
      final some = await pass();
      expect(err(of(some, pcSha)), isA<PcUnreachableFailure>());
      expect(ok(of(some, pc2Sha)), isA<SyncDone>());
      expect(some.noneAnswered, isFalse);

      pc2.offline = true;
      expect((await pass()).noneAnswered, isTrue);
    });

    test('a PC that changes twice during its sync fails alone', () async {
      await pair();
      await pair(qr2);
      await pass(confirm: {pcSha, pc2Sha});
      pc.scripted['POST /v1/sync'] = [
        (409, {'error': 'state-changed'}, const {}),
        (409, {'error': 'state-changed'}, const {}),
      ];

      final result = await pass();

      expect(err(of(result, pcSha)), isA<StateChangedFailure>());
      expect(ok(of(result, pc2Sha)), isA<SyncDone>());
    });

    test('prices come from one PC, which stays the source while it syncs and '
        'is never one that is shared or unpaired', () async {
      await pair();
      await pair(qr2);
      await pass(confirm: {pcSha, pc2Sha});
      expect((await stored()).pricesFrom, pcSha);
      expect(pc.bodies['POST /v1/prices'], isNotNull);
      expect(pc2.bodies['POST /v1/prices'], isNull);

      pc.offline = true;
      await pass();
      expect((await stored()).pricesFrom, pc2Sha);
      expect(pc2.bodies['POST /v1/prices'], hasLength(1));

      pc.offline = false;
      await pass();
      expect((await stored()).pricesFrom, pc2Sha);
      expect(pc2.bodies['POST /v1/prices'], hasLength(2));

      ok(await Unpair(repository)(pc2Sha));
      final left = await stored();
      expect(left.pricesFrom, isNull);
      expect([for (final p in left.pcs) p.sha256], [pcSha]);
    });

    test('the same certificate with a new identity is the PC rotating its '
        'own: taken without asking', () async {
      await pair();
      ok(await syncOne(confirm: true));
      expect((await stored()).of(pcSha)!.pcDeviceId, 'dev-pc');

      named(pc, 'dev-pc-rotated');
      expect(ok(await syncOne()), isA<SyncDone>());
      final rotated = (await stored()).of(pcSha)!;
      expect(rotated.pcDeviceId, 'dev-pc-rotated');
      expect(rotated.shared, isFalse);
    });

    group('two PCs with one identity', () {
      setUp(() => named(pc2, 'dev-pc'));

      test('when the other answers with it, the new one is set aside without '
          'asking and nothing reaches either side', () async {
        await pair();
        await pass(confirm: {pcSha});
        await pair(qr2);

        final result = await pass(confirm: {pc2Sha});

        final failure = err(of(result, pc2Sha));
        expect(failure, isA<SharedIdentityFailure>());
        expect((failure as SharedIdentityFailure).otherPcName, 'Test PC');
        expect(pc2.log, isNot(contains('POST /v1/sync')));
        expect(await ids(), isNot(contains(pc2Fund)));
        final pairings = await stored();
        expect(pairings.of(pc2Sha)!.shared, isTrue);
        expect(pairings.pricesFrom, pcSha);

        pc2.log.clear();
        final later = await pass();
        expect(err(of(later, pc2Sha)), isA<SharedIdentityFailure>());
        expect(pc2.log, isEmpty);
      });

      test('when the other does not answer, the user says: the same PC '
          'replaces it', () async {
        await pair();
        await pass(confirm: {pcSha});
        await pair(qr2);
        pc.offline = true;

        final question = ok(of(await pass(), pc2Sha)) as SyncSameIdentity;
        expect(question.other.sha256, pcSha);
        expect(pc2.log, isNot(contains('POST /v1/sync')));

        ok(
          await PcIdentity(repository).resolve(pc2Sha, question, samePc: true),
        );
        final pairings = await stored();
        expect([for (final p in pairings.pcs) p.sha256], [pc2Sha]);
        expect(pairings.of(pc2Sha)!.pcDeviceId, 'dev-pc');
        expect(pairings.pricesFrom, isNull);
      });

      test('another PC is set aside, and syncs again once its identity is '
          'its own', () async {
        await pair();
        await pass(confirm: {pcSha});
        await pair(qr2);
        pc.offline = true;
        final question = ok(of(await pass(), pc2Sha)) as SyncSameIdentity;

        ok(
          await PcIdentity(repository).resolve(pc2Sha, question, samePc: false),
        );
        expect((await stored()).of(pc2Sha)!.shared, isTrue);

        pc.offline = false;
        final still = await PcIdentity(repository).checkAgain(pc2Sha);
        expect(err(still), isA<SharedIdentityFailure>());

        named(pc2, 'dev-pc2-own');
        ok(await PcIdentity(repository).checkAgain(pc2Sha));
        final pairings = await stored();
        expect(pairings.of(pc2Sha)!.shared, isFalse);
        expect(pairings.of(pc2Sha)!.pcDeviceId, 'dev-pc2-own');
      });
    });

    test('the QR of a PC already paired only takes its new address', () async {
      await pair();
      final start = ok(
        await PairWithPc(repository)
            .start(qrOf('moved.test', pcSha, 'Renamed PC')),
      );

      expect(start.known, isNotNull);
      expect(pc.bodies['POST /v1/pair'], hasLength(1));
      final moved = (await stored()).of(pcSha)!;
      expect(moved.endpoint.host, 'moved.test');
      expect(moved.pcName, 'Renamed PC');
      expect(moved.token, FakePc.deviceToken);

      final again = ok(await PairWithPc(repository).start(qr, repair: true));
      expect(again.known, isNull);
    });
  });
}
