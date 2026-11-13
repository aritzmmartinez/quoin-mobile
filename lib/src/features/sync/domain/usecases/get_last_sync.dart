import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';

class GetLastSync {
  const GetLastSync(this._repository);

  final SyncRepository _repository;

  Future<Result<LastSync?>> call(String sha256) => _repository.lastSync(sha256);
}
