import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';

class Unpair {
  const Unpair(this._repository);

  final SyncRepository _repository;

  Future<Result<void>> call(String sha256) async =>
      switch (await _repository.pairings()) {
        Ok(:final value) => _repository.savePairings(value.without(sha256)),
        Err(:final failure) => Err(failure),
      };
}
