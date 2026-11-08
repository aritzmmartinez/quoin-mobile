import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart' show uuidV4;

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';

final supportDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('supportDirectoryProvider not overridden'),
);

final deviceIdentityDataSourceProvider = Provider(
  (ref) => DeviceIdentityDataSource(
    ref.watch(quoinDatabaseProvider),
    ref.watch(supportDirectoryProvider),
  ),
);

class DeviceIdentityDataSource {
  const DeviceIdentityDataSource(this._db, this._directory);

  static const fileName = 'install_id';

  final QuoinDatabase _db;
  final Directory _directory;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}$fileName');

  Future<String> claim() async {
    try {
      final taken = await _read();
      final device = await _db.select(_db.syncDevice).getSingle();
      if (taken == device.deviceId) return device.deviceId;
      final id = await _db.transaction(() async {
        final id = uuidV4();
        await _db
            .update(_db.syncDevice)
            .write(SyncDeviceCompanion(deviceId: Value(id)));
        if (device.lastHlc case final seen?) {
          await _db
              .into(_db.syncPeer)
              .insertOnConflictUpdate(
                SyncPeerCompanion.insert(deviceId: device.deviceId, seen: seen),
              );
        }
        return id;
      });
      await _file.writeAsString(id, flush: true);
      return id;
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }

  Future<String?> _read() async =>
      await _file.exists() ? (await _file.readAsString()).trim() : null;
}
