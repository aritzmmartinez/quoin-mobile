import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';

class PickImportFile {
  const PickImportFile(this._repository);

  final ImportRepository _repository;

  Future<Result<ImportFile?>> call() => _repository.pickFile();
}
