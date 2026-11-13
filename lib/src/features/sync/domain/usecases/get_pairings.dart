import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';

class GetPairings {
  const GetPairings(this._repository);

  final SyncRepository _repository;

  Future<Result<Pairings>> call() => _repository.pairings();
}
