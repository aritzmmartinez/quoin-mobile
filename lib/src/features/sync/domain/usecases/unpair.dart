import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/repositories/sync_repository.dart';

class Unpair {
  const Unpair(this._repository);

  final SyncRepository _repository;

  Future<Result<void>> call() => _repository.unpair();
}
