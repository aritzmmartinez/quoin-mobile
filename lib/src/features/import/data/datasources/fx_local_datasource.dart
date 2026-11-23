import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart'
    show FxRateCompanion, QuoinDatabase;
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/models/portfolio_rows.dart';

final fxLocalDataSourceProvider = Provider(
  (ref) => FxLocalDataSource(ref.watch(quoinDatabaseProvider)),
);

class FxLocalDataSource {
  const FxLocalDataSource(this._db);

  final QuoinDatabase _db;

  Future<({String? first, String? last})> span(String quote) =>
      _guard(() async {
        final day = _db.fxRate.day;
        final query = _db.selectOnly(_db.fxRate)
          ..addColumns([day.min(), day.max()])
          ..where(_series(quote));
        final row = await query.getSingle();
        return (first: row.read(day.min()), last: row.read(day.max()));
      });

  /// Saves [rates] as [planFxWrite] says, in one transaction.
  Future<FxWritePlan> save(String quote, List<FxRate> rates) => _guard(
    () => _db.transaction(() async {
      final days = [for (final rate in rates) rate.day];
      final stored = await (_db.select(
        _db.fxRate,
      )..where((r) => _series(quote) & r.day.isIn(days))).get();
      final plan = planFxWrite(
        (source: ecbSource, base: baseCurrency, quote: quote),
        [for (final row in stored) row.toEntity()],
        rates,
      );
      final now = DateTime.now().toUtc();
      await _db.batch(
        (batch) => batch.insertAll(_db.fxRate, [
          for (final rate in plan.write)
            FxRateCompanion.insert(
              id: uuidV4(),
              base: rate.base,
              quote: rate.quote,
              day: rate.day,
              rate: rate.rate.text,
              source: rate.source,
              createdAt: now,
            ),
        ]),
      );
      return plan;
    }),
  );

  Future<List<FxRate>> book(List<String> quotes) => _guard(() async {
    final rows =
        await (_db.select(_db.fxRate)..where(
              (r) =>
                  r.source.equals(ecbSource) &
                  r.base.equals(baseCurrency) &
                  r.quote.isIn(quotes),
            ))
            .get();
    return [for (final row in rows) row.toEntity()];
  });

  Future<List<FxRate>> all() => _guard(() async {
    final rows =
        await (_db.select(_db.fxRate)..where(
              (r) => r.source.equals(ecbSource) & r.base.equals(baseCurrency),
            ))
            .get();
    return [for (final row in rows) row.toEntity()];
  });

  Expression<bool> _series(String quote) =>
      _db.fxRate.source.equals(ecbSource) &
      _db.fxRate.base.equals(baseCurrency) &
      _db.fxRate.quote.equals(quote);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
