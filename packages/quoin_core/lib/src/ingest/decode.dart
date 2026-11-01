import 'dart:convert';

import 'reasons.dart';

String decodeCsv(List<int> bytes) {
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw const CsvFileError(FileErrorReason.invalidEncoding);
  }
  return text.startsWith('﻿') ? text.substring(1) : text;
}
