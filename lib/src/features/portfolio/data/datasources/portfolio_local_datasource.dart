import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart' show ecbSource;

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/seed/sample_portfolio.dart';

final quoinDatabaseProvider = Provider<QuoinDatabase>(
  (ref) => throw UnimplementedError('quoinDatabaseProvider not overridden'),
);

final pricesDatabaseProvider = Provider<PricesDatabase>(
  (ref) => throw UnimplementedError('pricesDatabaseProvider not overridden'),
);

final portfolioLocalDataSourceProvider = Provider<PortfolioLocalDataSource>(
  (ref) => PortfolioLocalDataSource(
    ref.watch(quoinDatabaseProvider),
    ref.watch(pricesDatabaseProvider),
  ),
);

class PortfolioRows {
  const PortfolioRows({
    required this.settings,
    required this.instruments,
    required this.entries,
    required this.prices,
    required this.rates,
  });

  final SettingsRow settings;
  final List<InstrumentRow> instruments;
  final List<LedgerEntryRow> entries;
  final List<PriceSnapshotRow> prices;
  final List<FxRateRow> rates;
}

class PortfolioLocalDataSource {
  PortfolioLocalDataSource(this._db, this._prices, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final QuoinDatabase _db;
  final PricesDatabase _prices;
  final DateTime Function() _now;

  Future<PortfolioRows> read() => _guard(() async {
    final prices = await _prices.latestPrices().get();
    return _db.transaction(
      () async => PortfolioRows(
        settings: await _db.select(_db.settings).getSingle(),
        instruments: await _db.select(_db.instrument).get(),
        entries: await (_db.select(
          _db.ledgerEntry,
        )..orderBy([(e) => OrderingTerm.asc(e.ts)])).get(),
        prices: prices,
        rates: await (_db.select(
          _db.fxRate,
        )..where((r) => r.source.equals(ecbSource))).get(),
      ),
    );
  });

  Future<List<PriceSnapshotRow>> priceSeries(String instrumentId) =>
      _guard(() => _prices.seriesOf(instrumentId).get());

  Future<void> replaceWithSample(DateTime now) => _guard(() async {
    final sample = SamplePortfolio(now);
    await _db.transaction(() async {
      await _deleteAll();
      await _db.batch((batch) {
        batch
          ..insertAll(_db.instrument, sample.instruments)
          ..insertAll(_db.ledgerEntry, sample.entries);
      });
    });
    await _prices.transaction(() async {
      await _deletePrices();
      await _prices.batch(
        (batch) => batch.insertAll(_prices.priceSnapshot, sample.prices),
      );
    });
  });

  Future<void> setExposure(String id, String? kind, String? leafId) => _guard(
    () => _db.transaction(() async {
      final row = await (_db.select(
        _db.instrument,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (row == null) throw StorageException('No instrument $id');
      if (row.exposureKind == kind && row.exposureLeafId == leafId) return;
      final hlc = await _db.stamp(_now().millisecondsSinceEpoch);
      await (_db.update(_db.instrument)..where((i) => i.id.equals(id))).write(
        InstrumentCompanion(
          exposureKind: Value(kind),
          exposureLeafId: Value(leafId),
          exposureHlc: Value(hlc),
        ),
      );
    }),
  );

  Future<void> clear() => _guard(() async {
    await _db.transaction(_deleteAll);
    await _prices.transaction(_deletePrices);
  });

  Future<void> _deleteAll() async {
    await _db.delete(_db.ledgerEntry).go();
    await _db.delete(_db.fxRate).go();
    await _db.delete(_db.instrument).go();
  }

  Future<void> _deletePrices() async {
    await _prices.delete(_prices.priceSnapshot).go();
    await _prices.delete(_prices.priceSeries).go();
    await _prices.delete(_prices.krakenSeries).go();
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on StorageException {
      rethrow;
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
