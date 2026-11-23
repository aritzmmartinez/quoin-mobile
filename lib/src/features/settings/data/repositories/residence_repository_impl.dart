import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/settings/data/datasources/residence_local_datasource.dart';
import 'package:quoin/src/features/settings/domain/repositories/residence_repository.dart';

class ResidenceRepositoryImpl implements ResidenceRepository {
  const ResidenceRepositoryImpl(this._source);

  final ResidenceLocalDataSource _source;

  @override
  Future<Result<String>> get() async {
    try {
      return Ok(await _source.read());
    } on StorageException {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> set(Residence residence) async {
    try {
      await _source.write(residence.name);
      return const Ok(null);
    } on StorageException {
      return const Err(StorageFailure());
    }
  }
}
