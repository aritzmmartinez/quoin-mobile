import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/sync/data/models/exchange_import.dart';
import 'package:quoin/src/features/sync/data/models/sync_rows.dart';

class SyncLocalDataSource {
  SyncLocalDataSource(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final QuoinDatabase _db;
  final DateTime Function() _now;

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

  Future<String> stamp({int? nowMs}) => _guard(
    () => _db.transaction(() async {
      final device = await _db.select(_db.syncDevice).getSingle();
      final hlc = tick(
        device.lastHlc,
        nowMs ?? _now().millisecondsSinceEpoch,
        device.deviceId,
      );
      await _db
          .update(_db.syncDevice)
          .write(SyncDeviceCompanion(lastHlc: Value(hlc)));
      return hlc;
    }),
  );

  Future<ExchangeImport> importExchange(
    Exchange incoming, {
    Resolutions resolutions = const {},
    required bool dryRun,
    required int nowMs,
    Future<void> Function()? beforeApply,
  }) => _guard(
    () => _db.transaction(() async {
      final local = await state();
      final plan = merge(local, incoming, resolutions);
      ExchangeImport outcome(ImportStatus status) => ExchangeImport(
        status: status,
        plan: plan,
        counts: planCounts(plan, local),
      );
      if (plan.conflicts.isNotEmpty) return outcome(ImportStatus.conflicts);

      final sender = SyncSender(
        deviceId: incoming.deviceId,
        name: incoming.deviceName,
      );
      if (!plan.changesData) {
        if (!dryRun && !_samePeers(local.peers, plan.apply.peers)) {
          await _savePeers(plan.apply.peers, sender, nowMs);
        }
        return outcome(ImportStatus.upToDate);
      }
      if (dryRun) return outcome(ImportStatus.dryRun);

      await beforeApply?.call();
      await apply(plan.apply, sender, nowMs);
      return outcome(ImportStatus.applied);
    }),
  );

  Future<void> apply(ApplyPlan plan, SyncSender sender, int nowMs) => _guard(
    () => _db.transaction(() async {
      final now = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);

      for (final row in plan.instrumentInsert) {
        await _db
            .into(_db.instrument)
            .insert(
              InstrumentCompanion.insert(
                id: row.id,
                name: row.name,
                type: row.type,
                assetClass: Value(row.assetClass),
                quoteSymbol: Value(row.quoteSymbol),
                quoteSymbolHlc: Value(row.quoteSymbolHlc),
                exposureKind: Value(row.exposureKind),
                exposureLeafId: Value(row.exposureLeafId),
                exposureHlc: Value(row.exposureHlc),
                ter: Value(row.ter),
                terHlc: Value(row.terHlc),
                hedgedToBase: Value(row.hedgedToBase),
                hedgedToBaseHlc: Value(row.hedgedToBaseHlc),
                thesis: Value(row.thesis),
                thesisHlc: Value(row.thesisHlc),
                createdAt: now,
              ),
            );
      }
      for (final InstrumentUpdate(:id, :patch) in plan.instrumentUpdate) {
        await (_db.update(
          _db.instrument,
        )..where((i) => i.id.equals(id))).write(_instrumentPatch(patch));
      }

      for (final row in plan.ledgerInsert) {
        await _db
            .into(_db.ledgerEntry)
            .insert(
              LedgerEntryCompanion.insert(
                id: uuidV4(),
                ts: DateTime.parse(row.ts).toUtc(),
                type: row.type,
                instrumentId: Value(row.instrumentId),
                quantity: Value(row.quantity),
                price: Value(row.price),
                grossAmount: row.grossAmount,
                fees: Value(row.fees),
                taxWithheld: Value(row.taxWithheld),
                currency: row.currency,
                fxSource: Value(row.fxSource),
                fxDate: Value(row.fxDate),
                fxRate: Value(row.fxRate),
                fxDirection: Value(row.fxDirection),
                originalAmount: Value(row.originalAmount ?? row.grossAmount),
                originalCurrency: Value(row.originalCurrency ?? row.currency),
                valuationSource: Value(row.valuationSource),
                linkId: Value(row.linkId),
                linkKind: Value(row.linkKind),
                funding: Value(row.funding),
                account: Value(row.account),
                source: Value(row.source),
                externalId: Value(row.externalId),
                note: Value(row.note),
                createdAt: now,
              ),
            );
      }
      for (final key in plan.markInKind) {
        final split = key.indexOf('::');
        final source = key.substring(0, split);
        final externalId = key.substring(split + 2);
        await (_db.update(_db.ledgerEntry)..where(
              (e) =>
                  e.source.equals(source) &
                  e.externalId.equals(externalId) &
                  e.funding.equals('CASH'),
            ))
            .write(const LedgerEntryCompanion(funding: Value('IN_KIND')));
      }

      for (final id in plan.targetDelete) {
        await (_db.delete(
          _db.portfolioTargetLine,
        )..where((l) => l.targetId.equals(id))).go();
        await (_db.delete(
          _db.portfolioTarget,
        )..where((t) => t.id.equals(id))).go();
      }
      for (final target in plan.targetInsert) {
        await _insertTarget(target);
      }
      for (final tombstone in plan.tombstones) {
        await _insertTombstone(tombstone.key, tombstone.hlc);
      }

      for (final block in plan.holdings) {
        await _replaceBlock(block, now);
      }

      for (final row in plan.identities) {
        await _db
            .into(_db.securityIdentity)
            .insertOnConflictUpdate(
              SecurityIdentityCompanion.insert(
                identity: row.identity,
                identityKind: row.identityKind,
                canonicalId: Value(row.canonicalId),
                exchCode: Value(row.exchCode),
                status: row.status,
                source: row.source,
                resolvedAt: DateTime.parse(row.resolvedAt).toUtc(),
              ),
            );
      }

      if (plan.settings case final settings?) {
        await _writeSettings(settings.residence, settings.residenceHlc);
      }

      for (final restamp in plan.restamp) {
        switch (restamp) {
          case InstrumentRestamp(:final id, :final field):
            await (_db.update(
              _db.instrument,
            )..where((i) => i.id.equals(id))).write(
              _instrumentPatch({field.mark: await stamp(nowMs: nowMs)}),
            );
          case SettingsRestamp():
            await (_db.update(
              _db.settings,
            )..where((s) => s.id.equals(1))).write(
              SettingsCompanion(residenceHlc: Value(await stamp(nowMs: nowMs))),
            );
          case HoldingsRestamp(:final instrumentId):
            await (_db.update(
              _db.etfHoldingBlock,
            )..where((b) => b.instrumentId.equals(instrumentId))).write(
              EtfHoldingBlockCompanion(hlc: Value(await stamp(nowMs: nowMs))),
            );
          case TombstoneRestamp(:final key):
            await _insertTombstone(key, await stamp(nowMs: nowMs));
          case ReissueRestamp(:final target):
            final mark = await stamp(nowMs: nowMs);
            await _insertTombstone(target.id, mark);
            await _insertTarget(
              TargetRecord(
                id: mark,
                name: target.name,
                activeFrom: target.activeFrom,
                note: target.note,
                createdAt: target.createdAt,
                lines: target.lines,
              ),
            );
        }
      }

      await _savePeers(plan.peers, sender, nowMs);
    }),
  );

  static const _instrumentColumns = {
    'assetClass',
    'quoteSymbol',
    'quoteSymbolHlc',
    'exposureKind',
    'exposureLeafId',
    'exposureHlc',
    'ter',
    'terHlc',
    'hedgedToBase',
    'hedgedToBaseHlc',
    'thesis',
    'thesisHlc',
  };

  InstrumentCompanion _instrumentPatch(Map<String, Object?> patch) {
    final unknown = patch.keys.where((c) => !_instrumentColumns.contains(c));
    if (unknown.isNotEmpty) {
      throw ArgumentError('The sync does not write Instrument.$unknown');
    }
    Value<T> column<T>(String name) => patch.containsKey(name)
        ? Value(patch[name] as T)
        : const Value.absent();
    return InstrumentCompanion(
      assetClass: column<String?>('assetClass'),
      quoteSymbol: column<String?>('quoteSymbol'),
      quoteSymbolHlc: column<String?>('quoteSymbolHlc'),
      exposureKind: column<String?>('exposureKind'),
      exposureLeafId: column<String?>('exposureLeafId'),
      exposureHlc: column<String?>('exposureHlc'),
      ter: column<String?>('ter'),
      terHlc: column<String?>('terHlc'),
      hedgedToBase: column<bool>('hedgedToBase'),
      hedgedToBaseHlc: column<String?>('hedgedToBaseHlc'),
      thesis: column<String>('thesis'),
      thesisHlc: column<String?>('thesisHlc'),
    );
  }

  Future<void> _insertTarget(TargetRecord target) async {
    await _db
        .into(_db.portfolioTarget)
        .insert(
          PortfolioTargetCompanion.insert(
            id: target.id,
            name: target.name,
            activeFrom: Value(target.activeFrom),
            note: Value(target.note),
            createdAt: DateTime.parse(target.createdAt).toUtc(),
          ),
        );
    for (final line in target.lines) {
      await _db
          .into(_db.portfolioTargetLine)
          .insert(
            PortfolioTargetLineCompanion.insert(
              id: uuidV4(),
              targetId: target.id,
              instrumentId: line.instrumentId,
              monthlyAmount: line.monthlyAmount,
            ),
          );
    }
  }

  Future<void> _insertTombstone(String key, String hlc) => _db
      .into(_db.syncTombstone)
      .insert(
        SyncTombstoneCompanion.insert(entity: targetEntity, key: key, hlc: hlc),
      );

  Future<void> _replaceBlock(HoldingsBlock block, DateTime now) async {
    await (_db.delete(
      _db.etfHolding,
    )..where((h) => h.instrumentId.equals(block.instrumentId))).go();
    await _db
        .into(_db.etfHoldingBlock)
        .insertOnConflictUpdate(
          EtfHoldingBlockCompanion.insert(
            instrumentId: block.instrumentId,
            asOf: block.asOf,
            asOfInferred: Value(block.asOfInferred),
            hlc: Value(block.hlc),
          ),
        );
    for (final row in block.rows) {
      await _db
          .into(_db.etfHolding)
          .insert(
            EtfHoldingCompanion.insert(
              id: uuidV4(),
              instrumentId: block.instrumentId,
              identity: row.identity,
              identityKind: row.identityKind,
              name: row.name,
              weight: row.weight,
              createdAt: now,
            ),
          );
    }
  }

  Future<void> _writeSettings(String residence, String? residenceHlc) =>
      (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(
          residence: Value(residence),
          residenceHlc: Value(residenceHlc),
        ),
      );

  Future<void> _savePeers(
    List<Peer> peers,
    SyncSender sender,
    int nowMs,
  ) async {
    final at = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
    for (final Peer(:deviceId, :seen) in peers) {
      final fromSender = deviceId == sender.deviceId;
      await _db
          .into(_db.syncPeer)
          .insert(
            SyncPeerCompanion.insert(
              deviceId: deviceId,
              seen: seen,
              name: fromSender ? Value(sender.name) : const Value.absent(),
              lastSyncedAt: fromSender ? Value(at) : const Value.absent(),
            ),
            onConflict: DoUpdate(
              (old) => SyncPeerCompanion(
                seen: Value(seen),
                name: fromSender ? Value(sender.name) : const Value.absent(),
                lastSyncedAt: fromSender ? Value(at) : const Value.absent(),
              ),
              target: [_db.syncPeer.deviceId],
            ),
          );
    }
  }

  bool _samePeers(List<Peer> a, List<Peer> b) =>
      jsonEncode([for (final p in a) p.toJson()]) ==
      jsonEncode([for (final p in b) p.toJson()]);

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
    } on SameDevice {
      rethrow;
    } on UnknownResolution {
      rethrow;
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
