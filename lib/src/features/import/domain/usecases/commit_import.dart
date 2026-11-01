import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';

/// Writes a batch, or nothing: one event that breaks the ledger's rules stops
/// the whole import before the store is touched.
class CommitImport {
  const CommitImport(this._repository);

  final ImportRepository _repository;

  Future<Result<ImportPreview>> call(ImportBatch batch) async {
    for (final event in batch.events) {
      if (ledgerWriteIssues(event).isNotEmpty) {
        return Err(
          InvalidLedgerEventFailure(
            ts: event.ts,
            type: typeCodeOf(event),
            currency: event.currency,
          ),
        );
      }
    }
    return _repository.commit(batch);
  }
}

/// The ledger's `type` column for [event].
String typeCodeOf(LedgerEvent event) => switch (event) {
  TradeEvent(:final type) => type.code,
  DividendEvent() => 'DIVIDEND',
  CashEvent(:final type) => type.code,
};
