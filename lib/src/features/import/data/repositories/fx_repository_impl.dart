import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/domain/repositories/fx_repository.dart';

class FxRepositoryImpl implements FxRepository {
  const FxRepositoryImpl(this._ecb, this._store);

  final EcbRemoteDataSource _ecb;
  final FxLocalDataSource _store;

  @override
  Future<Result<({String? first, String? last})>> span(String quote) =>
      _stored(() => _store.span(quote));

  @override
  Future<Result<List<FxRate>>> fetch(
    String quote,
    String from,
    String to,
  ) async {
    try {
      return Ok(await _ecb.rates(quote, from, to));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<FxWritePlan>> save(String quote, List<FxRate> rates) =>
      _stored(() => _store.save(quote, rates));

  @override
  Future<Result<RateBook>> book(List<String> quotes) =>
      _stored(() async => rateBookFrom(await _store.book(quotes)));

  Future<Result<T>> _stored<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on StorageException {
      return const Err(StorageFailure());
    }
  }
}
