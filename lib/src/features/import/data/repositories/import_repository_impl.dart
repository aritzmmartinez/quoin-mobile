import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/seed/sample_import.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';

class ImportRepositoryImpl implements ImportRepository {
  const ImportRepositoryImpl(
    this._files,
    this._store,
    this._rates, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ImportFileDataSource _files;
  final ImportLocalDataSource _store;
  final FxLocalDataSource _rates;
  final DateTime Function() _now;

  @override
  Future<Result<ImportFile?>> pickFile() async {
    try {
      return Ok(await _files.pick());
    } on EncodingException {
      return const Err(InvalidEncodingFailure());
    } on FileException {
      return const Err(UnreadableFileFailure());
    }
  }

  @override
  Future<Result<IngestContext>> context() => _stored(() async {
    final residence = await _store.residence();
    final known = Residence.values.asNameMap()[residence];
    if (known == null) throw UnsupportedResidenceException(residence);
    // No prices: a reward or swap Kraken does not value is valued on the PC
    // only and arrives by sync, so each such row has one author and the two
    // sides never book it at different prices.
    return IngestContext(
      zone: jurisdictionOf(known).zone,
      rates: rateBookFrom(await _rates.all()),
      names: await _store.names(),
      rewardRefids: await _store.rewardRefids(),
    );
  });

  @override
  Future<Result<Set<(String, String)>>> existing(List<LedgerEvent> events) =>
      _stored(() => _store.existing(events));

  @override
  Future<Result<Set<(String, String)>>> commit(MappedBatch batch) =>
      _stored(() => _store.write(batch, _now()));

  @override
  ImportFile sampleFile(DateTime now) {
    final text = sampleImportCsv(now);
    return ImportFile(name: 'sample.csv', size: text.length, text: text);
  }

  Future<Result<T>> _stored<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on UnsupportedResidenceException catch (e) {
      return Err(UnsupportedResidenceFailure(e.residence));
    } on StorageException {
      return const Err(StorageFailure());
    }
  }
}
