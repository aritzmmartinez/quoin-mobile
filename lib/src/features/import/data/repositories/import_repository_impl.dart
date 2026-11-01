import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/seed/sample_import.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';

class ImportRepositoryImpl implements ImportRepository {
  const ImportRepositoryImpl(
    this._files,
    this._store, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ImportFileDataSource _files;
  final ImportLocalDataSource _store;
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
  Future<Result<ImportPreview>> preview(ImportBatch batch) async {
    try {
      final zone = await _zone();
      return Ok(_previewOf(batch, await _store.existing(batch.events), zone));
    } on StorageException {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<ImportPreview>> commit(ImportBatch batch) async {
    try {
      // Read before writing, so a bad residence fails with nothing stored.
      final zone = await _zone();
      return Ok(_previewOf(batch, await _store.write(batch, _now()), zone));
    } on StorageException {
      return const Err(StorageFailure());
    }
  }

  @override
  ImportBatch sampleBatch(DateTime now) => sampleImportBatch(now);

  Future<String> _zone() async {
    final residence = await _store.residence();
    final known = Residence.values.asNameMap()[residence];
    if (known == null) throw StorageException('residence $residence');
    return jurisdictionOf(known).zone;
  }

  ImportPreview _previewOf(
    ImportBatch batch,
    Set<(String, String)> existing,
    String zone,
  ) {
    final (:imported, :duplicates) = batch.countAgainst(existing);
    return ImportPreview(
      batch: batch,
      imported: imported,
      duplicates: duplicates,
      zone: zone,
    );
  }
}
