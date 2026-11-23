import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/pairing_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/pc_finder_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/prices_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:quoin/src/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/usecases/pair_with_pc.dart';
import 'package:quoin/src/features/sync/domain/usecases/pc_identity.dart';
import 'package:quoin/src/features/sync/domain/usecases/sync_now.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';
import 'fake_pc.dart';

final pcSha = 'ab' * 32;
final pc2Sha = 'cd' * 32;

const home = '192.168.1.20';
const home2 = '192.168.1.21';
const moved = '192.168.1.30';

String qrOf(String host, String sha256, String name) => jsonEncode({
  'v': 1,
  'host': host,
  'port': 3443,
  'sha256': sha256,
  'token': FakePc.qrToken,
  'name': name,
});

T ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw StateError('$failure'),
};

Failure err<T>(Result<T> result) => switch (result) {
  Ok(:final value) => throw StateError('expected a failure, got $value'),
  Err(:final failure) => failure,
};

http.Client showing(String sha256) =>
    MockClient((_) async => throw PinMismatchException(sha256));

void main() {
  late QuoinDatabase db;
  late PricesDatabase prices;
  late FakePc pc;
  late FakePc pc2;
  late SyncRepositoryImpl repository;
  late SyncNow syncNow;
  late Map<String, http.Client> at;
  late Map<String, String> answering;
  late List<String> probed;
  late List<String> phoneIps;
  Object? refuse;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = memoryDatabase();
    prices = memoryPrices();
    pc = FakePc(
      const SyncState(
        deviceId: 'dev-pc',
        settings: SettingsRecord(residence: 'bizkaia'),
      ),
    );
    pc2 = FakePc(
      const SyncState(
        deviceId: 'dev-pc2',
        settings: SettingsRecord(residence: 'bizkaia'),
      ),
    );
    at = {home: pc.client, home2: pc2.client};
    answering = {};
    probed = [];
    phoneIps = ['192.168.1.50'];
    refuse = null;
    final offline = MockClient(
      (_) async => throw const SocketException('No route to host'),
    );
    repository = SyncRepositoryImpl(
      pairings: const PairingLocalDataSource(FlutterSecureStorage()),
      remote: SyncRemoteDataSource(
        clientFor: (e) => at[e.host] ?? offline,
        wait: (_) async {},
      ),
      local: SyncLocalDataSource(db),
      identity: DeviceIdentityDataSource(
        db,
        Directory.systemTemp.createTempSync('quoin-search-'),
      ),
      prices: PricesLocalDataSource(db, prices),
      finder: PcFinderDataSource(
        localIps: () async => phoneIps,
        probe: (host, port, pins, stop) async {
          probed.add(host);
          if (refuse case final e?) throw e;
          final sha = answering[host];
          if (sha == null || !pins.contains(sha)) return null;
          at[host] = sha == pcSha ? pc.client : pc2.client;
          return (sha256: sha, versions: const [1]);
        },
      ),
      now: () => DateTime.utc(2026, 11, 8, 10),
    );
    syncNow = SyncNow(
      repository,
      PcIdentity(repository),
      now: () => DateTime.utc(2026, 11, 8, 10),
    );
  });
  tearDown(() async {
    await db.close();
    await prices.close();
  });

  Future<void> pair(String host, String sha256, String name) async {
    final pairing = PairWithPc(repository);
    final start = ok(await pairing.start(qrOf(host, sha256, name)));
    ok(
      await pairing.confirm(
        start,
        name: 'Test phone',
        now: DateTime.utc(2026, 11, 8, 9),
      ),
    );
  }

  Future<SyncPass> pass({
    PcSearch search = PcSearch.off,
    Set<String> confirm = const {},
    void Function(Set<String>)? onSearch,
  }) async =>
      ok(await syncNow(search: search, confirm: confirm, onSearch: onSearch));

  Result<SyncOutcome> of(SyncPass pass, String sha) =>
      pass.pcs.firstWhere((p) => p.pairing.sha256 == sha).result;

  Future<Pairing> stored(String sha) async =>
      ok(await repository.pairings()).of(sha)!;

  Future<void> pairOne() async {
    await pair(home, pcSha, 'Test PC');
    await pass(confirm: {pcSha});
    at.remove(home);
  }

  test('a PC that moved is found by its certificate, keeps its pairing and '
      'syncs at its new address in the same pass', () async {
    await pairOne();
    answering[moved] = pcSha;
    final heard = <Set<String>>[];

    final result = await pass(search: PcSearch.held, onSearch: heard.add);

    expect(of(result, pcSha), isA<Ok<SyncOutcome>>());
    expect(ok(of(result, pcSha)), isA<SyncDone>());
    expect(heard, [
      {pcSha},
      <String>{},
    ]);
    expect(probed.first, home, reason: 'from the saved address outwards');
    final pairing = await stored(pcSha);
    expect(pairing.endpoint.host, moved);
    expect(pairing.endpoint.port, 3443);
    expect(pairing.token, FakePc.deviceToken);
    expect(result.pcs.single.pairing.endpoint.host, moved);
    expect(pc.log.where((l) => l == 'POST /v1/pair'), hasLength(1));
  });

  test('the sync on opening never searches', () async {
    await pairOne();
    answering[moved] = pcSha;

    final result = await pass();

    expect(err(of(result, pcSha)), isA<PcUnreachableFailure>());
    expect(probed, isEmpty);
    expect((await stored(pcSha)).endpoint.host, home);
  });

  test('a PC the search misses says so; a pull does not search for it again '
      'on the same network, Sync now does', () async {
    await pairOne();

    final missed = await pass(search: PcSearch.held);
    expect(err(of(missed, pcSha)), isA<PcNotFoundOnNetworkFailure>());
    expect(missed.noneAnswered, isTrue);
    expect(missed.unanswered, isA<PcNotFoundOnNetworkFailure>());
    expect(probed, hasLength(253));

    probed.clear();
    final pulled = await pass(search: PcSearch.held);
    expect(err(of(pulled, pcSha)), isA<PcNotFoundOnNetworkFailure>());
    expect(probed, isEmpty);

    answering[moved] = pcSha;
    final asked = await pass(search: PcSearch.always);
    expect(ok(of(asked, pcSha)), isA<SyncDone>());
  });

  test('a saved address on no /24 of the phone is not searched', () async {
    await pairOne();
    phoneIps = ['10.0.7.4'];

    final result = await pass(search: PcSearch.always);

    expect(err(of(result, pcSha)), isA<PcNotFoundOnNetworkFailure>());
    expect(probed, isEmpty);
  });

  test('without a local network, or with it denied, each lost PC says '
      'why', () async {
    await pairOne();

    phoneIps = ['100.71.3.9'];
    expect(
      err(of(await pass(search: PcSearch.always), pcSha)),
      isA<NoLocalNetworkFailure>(),
    );

    phoneIps = ['192.168.1.50'];
    refuse = const LocalNetworkDeniedException();
    final denied = await pass(search: PcSearch.always);
    expect(err(of(denied, pcSha)), isA<LocalNetworkDeniedFailure>());
    expect(denied.unanswered, isA<LocalNetworkDeniedFailure>());
    expect(probed.length, lessThanOrEqualTo(32));
  });

  test('two lost PCs are found in one sweep', () async {
    await pair(home, pcSha, 'Test PC');
    await pair(home2, pc2Sha, 'Second PC');
    await pass(confirm: {pcSha, pc2Sha});
    at
      ..remove(home)
      ..remove(home2);
    answering
      ..[moved] = pcSha
      ..['192.168.1.31'] = pc2Sha;

    final result = await pass(search: PcSearch.held);

    expect(result.pcs.every((p) => p.done), isTrue);
    expect(probed.toSet(), hasLength(probed.length));
    expect((await stored(pcSha)).endpoint.host, moved);
    expect((await stored(pc2Sha)).endpoint.host, '192.168.1.31');
  });

  test('the PC found still answers for its identity before any merge: a '
      'copy of another paired PC is set aside', () async {
    await pair(home, pcSha, 'Test PC');
    await pair(home2, pc2Sha, 'Second PC');
    await pass(confirm: {pcSha, pc2Sha});
    at.remove(home2);
    answering[moved] = pc2Sha;
    pc2.device = LocalDevice(
      state: const SyncState(
        deviceId: 'dev-pc',
        settings: SettingsRecord(residence: 'bizkaia'),
      ),
      lastHlc: null,
    );
    pc2.log.clear();

    final result = await pass(search: PcSearch.held);

    expect(err(of(result, pc2Sha)), isA<SharedIdentityFailure>());
    expect(pc2.log, isNot(contains('POST /v1/sync')));
    expect((await stored(pc2Sha)).shared, isTrue);
  });

  group('another certificate at the saved address', () {
    setUp(() async {
      await pair(home, pcSha, 'Test PC');
      await pair(home2, pc2Sha, 'Second PC');
      await pass(confirm: {pcSha, pc2Sha});
    });

    test('another paired PC there means this one is not: it is searched '
        'for, never «pair again»', () async {
      at[home2] = showing(pcSha);

      final silent = await pass();
      expect(err(of(silent, pc2Sha)), isA<PcUnreachableFailure>());
      expect(ok(of(silent, pcSha)), isA<SyncDone>());

      answering[moved] = pc2Sha;
      final pulled = await pass(search: PcSearch.held);
      expect(ok(of(pulled, pc2Sha)), isA<SyncDone>());
      expect((await stored(pc2Sha)).endpoint.host, moved);
    });

    test('an unknown certificate is still a mismatch, and no search', () async {
      at[home2] = showing('ef' * 32);

      final result = await pass(search: PcSearch.always);

      expect(err(of(result, pc2Sha)), isA<CertificateMismatchFailure>());
      expect(probed, isEmpty);
    });
  });
}
