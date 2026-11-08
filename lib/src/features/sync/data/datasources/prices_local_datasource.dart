import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';

final pricesLocalDataSourceProvider = Provider(
  (ref) => PricesLocalDataSource(
    ref.watch(quoinDatabaseProvider),
    ref.watch(pricesDatabaseProvider),
  ),
);

class PricesLocalDataSource {
  PricesLocalDataSource(this._db, this._prices, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final QuoinDatabase _db;
  final PricesDatabase _prices;
  final DateTime Function() _now;

  Future<List<PriceHolding>> holdings() => _guard(() async {
    final ids =
        await (_db.selectOnly(_db.instrument)
              ..addColumns([_db.instrument.id])
              ..where(_db.instrument.quoteSymbol.isNotNull())
              ..orderBy([OrderingTerm.asc(_db.instrument.id)]))
            .map((row) => row.read(_db.instrument.id)!)
            .get();
    final versions = {
      for (final s in await _prices.select(_prices.priceSeries).get())
        s.instrumentId: s.seriesVersion,
    };
    final newest = _prices.priceSnapshot.asOf.max();
    final last = {
      for (final row
          in await (_prices.selectOnly(_prices.priceSnapshot)
                ..addColumns([_prices.priceSnapshot.instrumentId, newest])
                ..groupBy([_prices.priceSnapshot.instrumentId]))
              .get())
        row.read(_prices.priceSnapshot.instrumentId)!: row.read(newest)!,
    };
    return [
      for (final id in ids)
        switch (last[id]) {
          final at? => PriceHolding(
            instrumentId: id,
            seriesVersion: versions[id],
            last: at.toUtc().toIso8601String(),
          ),
          null => PriceHolding(
            instrumentId: id,
            seriesVersion: null,
            last: null,
          ),
        },
    ];
  });

  Future<Map<String, String>> save(List<PriceAnswer> answers) => _guard(
    () => _prices.transaction(() async {
      final now = _now().toUtc();
      final firstOf = <String, DateTime>{};
      for (final answer in answers) {
        final (version, rows) = switch (answer) {
          PendingPrices() => (null, const <PriceRow>[]),
          FullPrices(:final seriesVersion, :final rows) => (
            seriesVersion,
            rows,
          ),
          TailPrices(:final seriesVersion, :final rows) => (
            seriesVersion,
            rows,
          ),
        };
        if (version == null) continue;
        final id = answer.instrumentId;
        final drop = _prices.delete(_prices.priceSnapshot)
          ..where((p) => p.instrumentId.equals(id));
        if (answer case TailPrices(:final from)) {
          drop.where((p) => p.asOf.isBiggerOrEqualValue(DateTime.parse(from)));
        }
        await drop.go();
        await _prices.batch((batch) {
          batch
            ..insertAll(_prices.priceSnapshot, [
              for (final row in rows)
                PriceSnapshotCompanion.insert(
                  id: uuidV4(),
                  instrumentId: id,
                  price: row.price,
                  currency: row.currency,
                  asOf: row.instant.toUtc(),
                  source: Value(row.source),
                  createdAt: now,
                ),
            ], mode: InsertMode.insertOrReplace)
            ..insert(
              _prices.priceSeries,
              PriceSeriesCompanion.insert(
                instrumentId: id,
                seriesVersion: version,
              ),
              mode: InsertMode.insertOrReplace,
            );
        });
        for (final row in rows) {
          if (row.currency == baseCurrency) continue;
          final at = row.instant.toUtc();
          final known = firstOf[row.currency];
          if (known == null || at.isBefore(known)) firstOf[row.currency] = at;
        }
      }
      return {
        for (final MapEntry(:key, :value) in firstOf.entries)
          key: value.toIso8601String(),
      };
    }),
  );

  Future<void> drop(String instrumentId) => _guard(
    () => _prices.transaction(() async {
      await (_prices.delete(
        _prices.priceSnapshot,
      )..where((p) => p.instrumentId.equals(instrumentId))).go();
      await (_prices.delete(
        _prices.priceSeries,
      )..where((s) => s.instrumentId.equals(instrumentId))).go();
    }),
  );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
