import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

final importFileDataSourceProvider = Provider(
  (ref) => const ImportFileDataSource(),
);

class ImportFileDataSource {
  const ImportFileDataSource();

  static const _types = XTypeGroup(
    label: 'CSV',
    extensions: ['csv'],
    mimeTypes: [
      'text/csv',
      'text/comma-separated-values',
      'text/plain',
      'application/csv',
      'application/vnd.ms-excel',
      'application/octet-stream',
    ],
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'public.plain-text',
    ],
  );

  Future<ImportFile?> pick() async {
    final XFile? file;
    final List<int> bytes;
    try {
      file = await openFile(acceptedTypeGroups: const [_types]);
      if (file == null) return null;
      bytes = await file.readAsBytes();
    } on Exception catch (e) {
      throw FileException(e);
    }
    return ImportFile(
      name: file.name,
      size: bytes.length,
      text: decodeExport(bytes),
    );
  }
}

String decodeExport(List<int> bytes) {
  try {
    return decodeCsv(bytes);
  } on CsvFileError catch (e) {
    throw EncodingException(e);
  }
}
