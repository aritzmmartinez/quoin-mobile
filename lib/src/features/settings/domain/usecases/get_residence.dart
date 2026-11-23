import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/repositories/residence_repository.dart';

class GetResidence {
  const GetResidence(this._repository);

  final ResidenceRepository _repository;

  Future<Result<String>> call() => _repository.get();
}
