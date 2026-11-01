import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/import/data/models/ledger_companions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show LedgerEntryCompanion, QuoinDatabase;
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/models/portfolio_rows.dart';

final importLocalDataSourceProvider = Provider(
  (ref) => ImportLocalDataSource(ref.watch(quoinDatabaseProvider)),
);

/// Writes imports to the ledger. Rows are deduplicated by their source's id,
/// the unique (source, externalId) key.
class ImportLocalDataSource {
  const ImportLocalDataSource(this._db);

  final QuoinDatabase _db;

  /// The stored residence, by its name.
  Future<String> residence() => _guard(
    () async => (await _db.select(_db.settings).getSingle()).residence,
  );

  Future<Map<String, String>> names() => _guard(() async {
    final rows = await _db.select(_db.instrument).get();
    return {for (final row in rows) row.id: row.name};
  });

  Future<Set<String>> rewardRefids() => _guard(() async {
    final e = _db.ledgerEntry;
    final rows =
        await (_db.selectOnly(e)
              ..addColumns([e.externalId])
              ..where(
                e.source.equals('KRAKEN_CSV') &
                    e.type.equals(TradeType.buy.code) &
                    e.note.equals(krakenRewardNote) &
                    e.externalId.isNotNull(),
              ))
            .get();
    return {for (final row in rows) row.read(e.externalId)!};
  });

  Future<List<PriceSnapshot>> cryptoPrices() => _guard(() async {
    final p = _db.priceSnapshot;
    final i = _db.instrument;
    final rows = await (_db.select(p).join([
      innerJoin(i, i.id.equalsExp(p.instrumentId)),
    ])..where(i.type.equals('CRYPTO'))).get();
    return [for (final row in rows) row.readTable(p).toEntity()];
  });

  /// The (source, externalId) keys of [events] already stored.
  Future<Set<(String, String)>> existing(List<LedgerEvent> events) =>
      _guard(() => _existing(events));

  /// Writes [batch] in one transaction and returns the keys that were stored
  /// before it: instruments upserted without their manual fields, events not
  /// yet stored inserted, and stored cash-funded rows the batch says are in
  /// kind marked so (never the other way).
  Future<Set<(String, String)>> write(MappedBatch batch, DateTime now) =>
      _guard(
        () => _db.transaction(() async {
          final at = now.toUtc();
          for (final instrument in batch.instruments) {
            await _db
                .into(_db.instrument)
                .insert(
                  instrument.toInsert(at),
                  onConflict: DoUpdate((_) => instrument.toUpdate()),
                );
          }

          final existing = await _existing(batch.events);
          final fresh = [
            for (final event in batch.events)
              if (!_isStored(event, existing)) event.toInsert(at),
          ];
          await _db.batch((b) => b.insertAll(_db.ledgerEntry, fresh));

          for (final event in batch.events) {
            final id = event.externalId;
            if (!isInKind(event) || id == null || id.isEmpty) continue;
            await (_db.update(_db.ledgerEntry)..where(
                  (e) =>
                      e.funding.equals(Funding.cash.code) &
                      e.source.equals(event.source) &
                      e.externalId.equals(id),
                ))
                .write(
                  LedgerEntryCompanion(funding: Value(Funding.inKind.code)),
                );
          }
          return existing;
        }),
      );

  Future<Set<(String, String)>> _existing(List<LedgerEvent> events) async {
    final sources = {
      for (final event in events)
        if ((event.externalId ?? '').isNotEmpty) event.source,
    };
    if (sources.isEmpty) return {};
    final source = _db.ledgerEntry.source;
    final externalId = _db.ledgerEntry.externalId;
    final rows =
        await (_db.selectOnly(_db.ledgerEntry)
              ..addColumns([source, externalId])
              ..where(externalId.isNotNull() & source.isIn(sources)))
            .get();
    return {for (final row in rows) (row.read(source)!, row.read(externalId)!)};
  }

  bool _isStored(LedgerEvent event, Set<(String, String)> existing) {
    final id = event.externalId;
    return id != null && id.isNotEmpty && existing.contains((event.source, id));
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
