import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

abstract interface class ImportRepository {
  Future<Result<ImportFile?>> pickFile();

  Future<Result<IngestContext>> context();

  Future<Result<Set<(String, String)>>> existing(List<LedgerEvent> events);

  Future<Result<Set<(String, String)>>> commit(MappedBatch batch);

  ImportFile sampleFile(DateTime now);
}
