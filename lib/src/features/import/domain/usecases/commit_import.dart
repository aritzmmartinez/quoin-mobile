import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';

class CommitImport {
  const CommitImport(this._repository);

  final ImportRepository _repository;

  Future<Result<ImportPreview>> call(ImportPreview preview) async {
    final batch = preview.batch;
    for (final event in batch.events) {
      if (ledgerWriteIssues(event).isNotEmpty) {
        return Err(
          InvalidLedgerEventFailure(
            day: dayOf(event.ts, preview.zone),
            type: ledgerTypeOf(event),
            currency: event.currency,
          ),
        );
      }
    }
    return switch (await _repository.commit(batch)) {
      Ok(:final value) => Ok(preview.counted(countOperations(batch, value))),
      Err(:final failure) => Err(failure),
    };
  }
}
