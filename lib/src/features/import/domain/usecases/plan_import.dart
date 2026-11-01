import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

/// Reads an export into a batch. The broker comes from the header; there is
/// no picker, on purpose.
class PlanImport {
  const PlanImport();

  Future<Result<ImportBatch>> call(ImportFile file) async {
    final broker = detectBroker(file.text);
    if (broker == null) return const Err(UnknownBrokerFailure());
    try {
      parseCsv(file.text);
    } on CsvFormatException {
      return const Err(UnparseableCsvFailure());
    }
    // The brokers' adapters are ported against Quoin's ingest contract; until
    // then a recognised export is reported, not guessed at.
    return const Err(UnsupportedFormatFailure());
  }
}
