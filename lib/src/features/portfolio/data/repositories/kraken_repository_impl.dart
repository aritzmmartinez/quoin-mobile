import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/portfolio/data/datasources/kraken_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/datasources/kraken_remote_datasource.dart';
import 'package:quoin/src/features/portfolio/domain/entities/kraken_target.dart';
import 'package:quoin/src/features/portfolio/domain/repositories/kraken_repository.dart';

class KrakenRepositoryImpl implements KrakenRepository {
  const KrakenRepositoryImpl(this._remote, this._local);

  final KrakenRemoteDataSource _remote;
  final KrakenLocalDataSource _local;

  @override
  Future<Result<List<KrakenTarget>>> targets() => _run(_local.targets);

  @override
  Future<Result<String>> zone() => _run(() async {
    final residence = await _local.residence();
    final known = Residence.values.asNameMap()[residence];
    if (known == null) throw UnsupportedResidenceException(residence);
    return jurisdictionOf(known).zone;
  });

  @override
  Future<Result<List<KrakenQuote>>> candles(String symbol, DateTime? since) =>
      _run(() => _remote.candles(symbol, since));

  @override
  Future<Result<KrakenQuote?>> lastTrade(String symbol) =>
      _run(() => _remote.lastTrade(symbol));

  @override
  Future<Result<Map<String, String>>> write(
    String instrumentId,
    KrakenStep step,
    List<KrakenQuote> candles,
    KrakenQuote? live,
  ) => _run(() => _local.write(instrumentId, step, candles, live));

  @override
  Future<Result<void>> drop(String instrumentId) =>
      _run(() => _local.drop(instrumentId));

  @override
  Future<Result<void>> dropAll() => _run(_local.dropAll);

  Future<Result<T>> _run<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on NetworkException {
      return const Err(NetworkFailure());
    } on StorageException {
      return const Err(StorageFailure());
    } on UnsupportedResidenceException catch (e) {
      return Err(UnsupportedResidenceFailure(e.residence));
    }
  }
}
