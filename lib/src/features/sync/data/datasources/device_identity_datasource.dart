import 'dart:io';

import 'package:drift/drift.dart';
import 'package:quoin_core/quoin_core.dart' show uuidV4;

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';

/// Keeps the database's device id this install's own.
///
/// Android copies the database to a new phone (cloud backup, device-to-device
/// transfer), and a copy keeps the device id: two phones would then sign
/// their changes as one. The file [fileName] names the device id this install
/// took, and is left out of every copy (`res/xml/data_extraction_rules.xml`,
/// `res/xml/backup_rules.xml`), so on a restored copy it is missing.
class DeviceIdentityDataSource {
  const DeviceIdentityDataSource(this._db, this._directory);

  static const fileName = 'install_id';

  final QuoinDatabase _db;
  final Directory _directory;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}$fileName');

  /// Gives the database a new device id when it is not the one this install
  /// took (a copy, or the first start), keeping the data. The old id becomes
  /// a peer seen up to the last mark it issued: this database holds all of
  /// it, so a merge never takes that device's marks for news.
  ///
  /// Start-up ignores a failure here and tries again on the next start. A
  /// sync must not: it calls this first and, if it throws, returns a failure
  /// and stops, because a database that could not claim its id may be a copy
  /// signing its changes as the original.
  Future<void> claim() async {
    try {
      final taken = await _read();
      final device = await _db.select(_db.syncDevice).getSingle();
      if (taken == device.deviceId) return;
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
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }

  Future<String?> _read() async =>
      await _file.exists() ? (await _file.readAsString()).trim() : null;
}
