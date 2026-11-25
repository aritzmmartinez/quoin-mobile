import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/prices_database.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/domain/entities/kraken_target.dart';

const krakenSource = 'KRAKEN';
const krakenLiveSource = 'KRAKEN_LIVE';

final krakenLocalDataSourceProvider = Provider(
  (ref) => KrakenLocalDataSource(
    ref.watch(quoinDatabaseProvider),
    ref.watch(pricesDatabaseProvider),
  ),
);

class KrakenLocalDataSource {
  KrakenLocalDataSource(this._db, this._prices, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final QuoinDatabase _db;
  final PricesDatabase _prices;
  final DateTime Function() _now;

  Future<List<KrakenTarget>> targets() => _guard(() async {
    final instruments = await (_db.select(
      _db.instrument,
    )..orderBy([(i) => OrderingTerm.asc(i.id)])).get();
    final origins = await _origins();
    return [
      for (final i in instruments)
        // Invented ids never leave the phone.
        if (!i.id.contains(sampleMarker))
          KrakenTarget(
            instrumentId: i.id,
            symbol: effectiveKrakenSymbol(
              type: i.type,
              id: i.id,
              quoteSymbol: i.quoteSymbol,
            ),
            origin: origins[i.id] ?? const NoOrigin(),
          ),
    ];
  });

  Future<String> residence() => _guard(
    () async => (await _db.select(_db.settings).getSingle()).residence,
  );

  Future<Map<String, String>> write(
    String instrumentId,
    KrakenStep step,
    List<KrakenQuote> candles,
    KrakenQuote? live,
  ) => _guard(
    () => _prices.transaction(() async {
      final origin =
          (await _origins(instrumentId))[instrumentId] ?? const NoOrigin();
      final (symbol, full) = switch (step) {
        KrakenFull(:final symbol) => (symbol, true),
        KrakenTail(:final symbol) => (symbol, false),
        KrakenLeave() || KrakenDrop() => (null, false),
      };
      final still = switch ((step, planKrakenStep(symbol, origin, _now()))) {
        (KrakenFull(), KrakenFull()) || (KrakenTail(), KrakenTail()) => true,
        _ => false,
      };
      if (symbol == null || !still) return const <String, String>{};

      final List<StoredPrice> stored;
      if (full) {
        await _deleteSeries(instrumentId);
        await (_prices.delete(
          _prices.priceSeries,
        )..where((s) => s.instrumentId.equals(instrumentId))).go();
        await _prices
            .into(_prices.krakenSeries)
            .insert(
              KrakenSeriesCompanion.insert(
                instrumentId: instrumentId,
                symbol: symbol,
              ),
            );
        stored = const [];
      } else {
        stored = [
          for (final row in await (_prices.select(
            _prices.priceSnapshot,
          )..where((p) => p.instrumentId.equals(instrumentId))).get())
            StoredPrice(row.asOf.toUtc(), live: row.source == krakenLiveSource),
        ];
      }

      final plan = planKrakenWrite(stored, candles, live);
      if (plan.remove.isNotEmpty) {
        await (_prices.delete(_prices.priceSnapshot)..where(
              (p) =>
                  p.instrumentId.equals(instrumentId) &
                  p.asOf.isIn(plan.remove),
            ))
            .go();
      }
      final now = _now().toUtc();
      PriceSnapshotCompanion row(KrakenQuote q, String source) =>
          PriceSnapshotCompanion.insert(
            id: '$instrumentId|${q.asOf.toUtc().toIso8601String()}',
            instrumentId: instrumentId,
            price: q.price,
            currency: q.currency,
            asOf: q.asOf.toUtc(),
            source: Value(source),
            createdAt: now,
          );
      await _prices.batch(
        (batch) => batch.insertAll(_prices.priceSnapshot, [
          for (final c in plan.candles) row(c, krakenSource),
          if (plan.live case final l?) row(l, krakenLiveSource),
        ], mode: InsertMode.insertOrReplace),
      );

      final firstOf = <String, DateTime>{};
      for (final q in [...plan.candles, ?plan.live]) {
        if (q.currency == baseCurrency) continue;
        final known = firstOf[q.currency];
        if (known == null || q.asOf.isBefore(known)) {
          firstOf[q.currency] = q.asOf;
        }
      }
      return {
        for (final MapEntry(:key, :value) in firstOf.entries)
          key: value.toUtc().toIso8601String(),
      };
    }),
  );

  Future<void> drop(String instrumentId) => _guard(
    () => _prices.transaction(() async {
      final held = await (_prices.select(
        _prices.krakenSeries,
      )..where((k) => k.instrumentId.equals(instrumentId))).getSingleOrNull();
      if (held != null) await _deleteSeries(instrumentId);
    }),
  );

  Future<void> dropAll() => _guard(
    () => _prices.transaction(() async {
      final ids = _prices.selectOnly(_prices.krakenSeries)
        ..addColumns([_prices.krakenSeries.instrumentId]);
      await (_prices.delete(
        _prices.priceSnapshot,
      )..where((p) => p.instrumentId.isInQuery(ids))).go();
      await _prices.delete(_prices.krakenSeries).go();
    }),
  );

  Future<void> _deleteSeries(String instrumentId) async {
    await (_prices.delete(
      _prices.priceSnapshot,
    )..where((p) => p.instrumentId.equals(instrumentId))).go();
    await (_prices.delete(
      _prices.krakenSeries,
    )..where((k) => k.instrumentId.equals(instrumentId))).go();
  }

  Future<Map<String, SeriesOrigin>> _origins([String? only]) async {
    final candle = _prices.priceSnapshot;
    final newest = candle.asOf.max();
    final candleQuery = _prices.selectOnly(candle)
      ..addColumns([candle.instrumentId, newest])
      ..where(candle.source.like('%\\_LIVE', escapeChar: r'\').not())
      ..groupBy([candle.instrumentId]);
    final pcQuery = _prices.select(_prices.priceSeries);
    final krakenQuery = _prices.select(_prices.krakenSeries);
    if (only != null) {
      candleQuery.where(candle.instrumentId.equals(only));
      pcQuery.where((s) => s.instrumentId.equals(only));
      krakenQuery.where((k) => k.instrumentId.equals(only));
    }
    final newestOf = {
      for (final row in await candleQuery.get())
        row.read(candle.instrumentId)!: row.read(newest)!.toUtc(),
    };
    return {
      for (final s in await pcQuery.get())
        s.instrumentId: PcOrigin(newestOf[s.instrumentId]),
      for (final k in await krakenQuery.get())
        k.instrumentId: KrakenOrigin(k.symbol, newestOf[k.instrumentId]),
    };
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
