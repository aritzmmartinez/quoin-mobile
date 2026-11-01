import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

abstract interface class ImportRepository {
  /// Asks the user for a file; `Ok(null)` when they cancel.
  Future<Result<ImportFile?>> pickFile();

  /// Counts what [batch] would add without writing anything.
  Future<Result<ImportPreview>> preview(ImportBatch batch);

  /// Writes [batch] in one transaction: instruments without touching their
  /// manual fields, new events, and cash-funded rows the batch now knows to be
  /// in kind. The counts are taken inside the same transaction.
  Future<Result<ImportPreview>> commit(ImportBatch batch);

  /// An invented batch dated around [now]. Debug builds only.
  ImportBatch sampleBatch(DateTime now);
}
