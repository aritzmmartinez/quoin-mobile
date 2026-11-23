import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';

/// Reads an export into a preview, as Quoin's `planWithRates`: plan with the
/// stored ECB rates; when rows lack one, fetch the missing series and plan
/// again. The broker comes from the header; there is no picker, on purpose.
class PlanImport {
  const PlanImport(this._repository, this._ensureRates);

  final ImportRepository _repository;
  final EnsureRates _ensureRates;

  Future<Result<ImportPreview>> call(
    ImportFile file, {
    required DateTime now,
  }) async {
    final broker = detectBroker(file.text);
    if (broker == null) return const Err(UnknownBrokerFailure());

    IngestContext context;
    switch (await _repository.context()) {
      case Ok(:final value):
        context = value;
      case Err(:final failure):
        return Err(failure);
    }
    MappedBatch batch;
    switch (_plan(broker, file.text, context)) {
      case Ok(:final value):
        batch = value;
      case Err(:final failure):
        return Err(failure);
    }

    var unavailable = const <String>[];
    var conflicts = const <RateConflict>[];
    if (batch.ratesNeeded.isNotEmpty) {
      switch (await _ensureRates(
        batch.ratesNeeded,
        now: now,
        zone: context.zone,
      )) {
        case Ok(:final value):
          unavailable = value.unavailable;
          conflicts = value.conflicts;
          context = IngestContext(
            zone: context.zone,
            rates: {...context.rates, ...value.book},
            prices: context.prices,
            names: context.names,
            rewardRefids: context.rewardRefids,
          );
        case Err(:final failure):
          return Err(failure);
      }
      switch (_plan(broker, file.text, context)) {
        case Ok(:final value):
          batch = value;
        case Err(:final failure):
          return Err(failure);
      }
    }

    switch (await _repository.existing(batch.events)) {
      case Ok(:final value):
        return Ok(
          ImportPreview(
            broker: broker,
            batch: batch,
            counts: countOperations(batch, value),
            zone: context.zone,
            ratesUnavailable: unavailable,
            rateConflicts: conflicts,
          ),
        );
      case Err(:final failure):
        return Err(failure);
    }
  }

  Result<MappedBatch> _plan(Broker broker, String csv, IngestContext context) {
    try {
      return Ok(planIngest(broker, csv, context));
    } on IngestRejection catch (rejection) {
      return Err(rejectionFailure(rejection));
    }
  }
}

ImportFailure rejectionFailure(IngestRejection rejection) =>
    switch (rejection) {
      CsvFileError(reason: FileErrorReason.invalidEncoding) =>
        const InvalidEncodingFailure(),
      CsvFileError(reason: FileErrorReason.unparseable) =>
        const UnparseableCsvFailure(),
      CsvFileError(reason: FileErrorReason.missingColumn, :final column) =>
        MissingColumnFailure(column ?? ''),
      CsvFileError(:final reason, :final row) => RowRejectedFailure(
        externalId: row?.externalId,
        position: row?.position,
        reason: reason.code,
      ),
      KrakenLegacyExport() => const KrakenLegacyExportFailure(),
      KrakenBalanceMismatch(:final asset, :final wallet, :final date) =>
        KrakenBalanceMismatchFailure(asset: asset, wallet: wallet, date: date),
      InvalidLedgerEvent(:final date, :final type, :final currency) =>
        InvalidLedgerEventFailure(day: date, type: type, currency: currency),
    };
