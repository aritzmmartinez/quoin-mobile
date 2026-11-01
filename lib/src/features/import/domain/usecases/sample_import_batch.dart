import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';

/// An invented batch to walk the wizard through. Debug builds only.
class SampleImportBatch {
  const SampleImportBatch(this._repository);

  final ImportRepository _repository;

  ImportBatch call(DateTime now) => _repository.sampleBatch(now);
}
