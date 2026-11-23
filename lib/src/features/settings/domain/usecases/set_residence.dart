import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/domain/repositories/residence_repository.dart';

class SetResidence {
  const SetResidence(this._repository);

  final ResidenceRepository _repository;

  Future<Result<void>> call(Residence residence) => _repository.set(residence);
}
