import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/models/portfolio_rows.dart';
import 'package:quoin/src/features/portfolio/domain/entities/portfolio_ledger.dart';
import 'package:quoin/src/features/portfolio/domain/entities/price_series.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/portfolio_repository.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  const PortfolioRepositoryImpl(this._source);

  final PortfolioLocalDataSource _source;

  @override
  Future<Result<PortfolioLedger>> load() async {
    try {
      return Ok((await _source.read()).toEntity());
    } on UnsupportedResidenceException catch (e) {
      return Err(UnsupportedResidenceFailure(e.residence));
    } on StorageException {
      return const Err(StorageFailure());
    } on UnreadableRow {
      return const Err(StorageFailure());
    } on DecimalError {
      return const Err(StorageFailure());
    } on ArgumentError {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<PriceSeries?>> priceSeries(String instrumentId) async {
    try {
      final rows = await _source.priceSeries(instrumentId);
      if (rows.isEmpty) return const Ok(null);
      final kraken = rows.any((r) => r.source.startsWith('KRAKEN'));
      return Ok(
        PriceSeries(
          history: [for (final row in rows) row.toEntity()],
          source: kraken ? PriceSource.kraken : PriceSource.pc,
        ),
      );
    } on StorageException {
      return const Err(StorageFailure());
    } on DecimalError {
      return const Err(StorageFailure());
    } on ArgumentError {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> loadSample(DateTime now) =>
      _write(() => _source.replaceWithSample(now));

  @override
  Future<Result<void>> setExposure(
    String id,
    ExposureKind? kind,
    String? leafId,
  ) => _write(() => _source.setExposure(id, kind?.code, leafId));

  @override
  Future<Result<void>> clear() => _write(_source.clear);

  Future<Result<void>> _write(Future<void> Function() body) async {
    try {
      await body();
      return const Ok(null);
    } on StorageException {
      return const Err(StorageFailure());
    }
  }
}
