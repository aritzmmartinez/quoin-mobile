import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

final importFileDataSourceProvider = Provider(
  (ref) => const ImportFileDataSource(),
);

/// Picks a file through the system's document picker (the Storage Access
/// Framework on Android: no storage permission) and decodes it.
class ImportFileDataSource {
  const ImportFileDataSource();

  // Broad on purpose: providers label CSV files inconsistently, and a file
  // that is not an export is caught by its header, with a reason.
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

/// UTF-8, with or without a byte order mark. Strict: a byte that is not UTF-8
/// rejects the file instead of turning into a replacement character.
String decodeExport(List<int> bytes) {
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException catch (e) {
    throw EncodingException(e);
  }
  return text.startsWith('﻿') ? text.substring(1) : text;
}
