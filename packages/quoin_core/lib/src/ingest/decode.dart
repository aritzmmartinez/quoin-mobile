import 'dart:convert';

import 'reasons.dart';

// Written by code point: a byte order mark is invisible.
final _bom = String.fromCharCode(0xFEFF);

String decodeCsv(List<int> bytes) {
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw const CsvFileError(FileErrorReason.invalidEncoding);
  }
  return text.startsWith(_bom) ? text.substring(1) : text;
}
