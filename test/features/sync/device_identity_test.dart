import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/datasources/device_identity_datasource.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:quoin_core/quoin_core.dart';

import '../../helpers.dart';

void main() {
  late QuoinDatabase db;
  late Directory install;

  setUp(() async {
    db = memoryDatabase();
    install = await Directory.systemTemp.createTemp('install');
  });
  tearDown(() async {
    await db.close();
    await install.delete(recursive: true);
  });

  Future<String> deviceId() async =>
      (await db.select(db.syncDevice).getSingle()).deviceId;

  test('the first start takes an id and keeps it after', () async {
    final identity = DeviceIdentityDataSource(db, install);

    await identity.claim();
    final taken = await deviceId();
    await identity.claim();

    expect(await deviceId(), taken);
    expect(
      File('${install.path}/${DeviceIdentityDataSource.fileName}')
          .readAsStringSync(),
      taken,
    );
    expect(await db.select(db.syncPeer).get(), isEmpty);
  });

  test('a copy on another install takes a new id and keeps its data', () async {
    await DeviceIdentityDataSource(db, install).claim();
    final old = await deviceId();
    final store = SyncLocalDataSource(db);
    final last = await store.stamp();
    final elsewhere = await Directory.systemTemp.createTemp('elsewhere');
    addTearDown(() => elsewhere.delete(recursive: true));

    await DeviceIdentityDataSource(db, elsewhere).claim();

    final device = await db.select(db.syncDevice).getSingle();
    expect(device.deviceId, isNot(old));
    expect(device.lastHlc, last);
    final peer = await db.select(db.syncPeer).getSingle();
    expect(peer.deviceId, old);
    expect(peer.seen, last);
    final next = await store.stamp();
    expect(originOf(next), device.deviceId);
    expect(parseHlc(next).ms, greaterThanOrEqualTo(parseHlc(last).ms));
  });

  test('an id file that names another device is a copy too', () async {
    final old = await deviceId();
    File('${install.path}/${DeviceIdentityDataSource.fileName}')
        .writeAsStringSync('another-device');

    await DeviceIdentityDataSource(db, install).claim();

    expect(await deviceId(), isNot(old));
    expect(await db.select(db.syncPeer).get(), isEmpty);
  });
}
