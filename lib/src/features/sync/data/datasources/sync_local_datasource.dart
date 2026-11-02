import 'package:drift/drift.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/models/sync_rows.dart';

/// What sync reads from and marks in the local store.
class SyncLocalDataSource {
  SyncLocalDataSource(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final QuoinDatabase _db;
  final DateTime Function() _now;

  /// This database's user state, in the order Quoin exports it, read in one
  /// transaction so it is one moment's state. Every sync starts here, so a
  /// state holding the invented sample data is refused here, whole.
  Future<SyncState> state() => _guard(
    () => _db.transaction(() async {
      final device = await _db.select(_db.syncDevice).getSingle();
      final peers = await (_db.select(
        _db.syncPeer,
      )..orderBy([(p) => OrderingTerm.asc(p.deviceId)])).get();
      final ledger =
          await (_db.select(_db.ledgerEntry)..orderBy([
                (e) => OrderingTerm.asc(e.source),
                (e) => OrderingTerm.asc(e.externalId),
              ]))
              .get();
      final instruments = await (_db.select(
        _db.instrument,
      )..orderBy([(i) => OrderingTerm.asc(i.id)])).get();
      final targets = await (_db.select(
        _db.portfolioTarget,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final lines = await (_db.select(
        _db.portfolioTargetLine,
      )..orderBy([(l) => OrderingTerm.asc(l.instrumentId)])).get();
      final tombstones =
          await (_db.select(_db.syncTombstone)..orderBy([
                (t) => OrderingTerm.asc(t.entity),
                (t) => OrderingTerm.asc(t.key),
              ]))
              .get();
      final blocks = await (_db.select(
        _db.etfHoldingBlock,
      )..orderBy([(b) => OrderingTerm.asc(b.instrumentId)])).get();
      final holdings =
          await (_db.select(_db.etfHolding)..orderBy([
                (h) => OrderingTerm.asc(h.instrumentId),
                (h) => OrderingTerm.asc(h.identity),
              ]))
              .get();
      final identities = await (_db.select(
        _db.securityIdentity,
      )..orderBy([(i) => OrderingTerm.asc(i.identity)])).get();
      final settings = await _db.select(_db.settings).getSingle();

      final state = SyncState(
        deviceId: device.deviceId,
        peers: [for (final p in peers) p.toRecord()],
        ledger: [for (final e in ledger) e.toRecord()],
        instruments: [for (final i in instruments) i.toRecord()],
        targets: [
          for (final t in targets)
            t.toRecord([
              for (final l in lines)
                if (l.targetId == t.id) l,
            ]),
        ],
        tombstones: [for (final t in tombstones) t.toRecord()],
        holdings: [
          for (final b in blocks)
            b.toRecord([
              for (final h in holdings)
                if (h.instrumentId == b.instrumentId) h,
            ]),
        ],
        identities: [for (final i in identities) i.toRecord()],
        settings: settings.toRecord(),
      );
      if (containsSample(state)) throw const SampleDataException();
      return state;
    }),
  );

  /// This database's state as the file it sends, at a new mark: refused here
  /// exactly as the other side would refuse it.
  Future<Exchange> export() => _guard(
    () => _db.transaction(() async {
      final exportHlc = await stamp();
      final device = await _db.select(_db.syncDevice).getSingle();
      return Exchange.of(
        await state(),
        deviceName: device.name,
        exportHlc: exportHlc,
      );
    }),
  );

  /// Issues the next mark of this database, in the caller's transaction when
  /// there is one, so a write and its mark land together or not at all.
  Future<String> stamp() => _guard(
    () => _db.transaction(() async {
      final device = await _db.select(_db.syncDevice).getSingle();
      final hlc = tick(
        device.lastHlc,
        _now().millisecondsSinceEpoch,
        device.deviceId,
      );
      await _db
          .update(_db.syncDevice)
          .write(SyncDeviceCompanion(lastHlc: Value(hlc)));
      return hlc;
    }),
  );

  /// Writes a hand-set value with a new mark, unless [unchanged] says the
  /// stored value is already it: a mark claims that the value changed, and a
  /// screen that saves every field must not claim it for each one.
  Future<void> setStamped<T>({
    required Future<T> Function() read,
    required bool Function(T stored) unchanged,
    required Future<void> Function(String hlc) write,
  }) => _guard(
    () => _db.transaction(() async {
      if (unchanged(await read())) return;
      await write(await stamp());
    }),
  );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on StorageException {
      rethrow;
    } on SampleDataException {
      rethrow;
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
