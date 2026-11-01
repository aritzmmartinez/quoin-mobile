import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/usecases/plan_import.dart';

void main() {
  group('decodeExport', () {
    test('UTF-8 with and without a BOM reads the same', () {
      final text = 'name,type\nAcción,BUY\n';
      expect(decodeExport(utf8.encode(text)), text);
      expect(decodeExport([0xEF, 0xBB, 0xBF, ...utf8.encode(text)]), text);
    });

    test('a byte that is not UTF-8 rejects the file', () {
      expect(
        () => decodeExport([...utf8.encode('name\nAcci'), 0xF3, 0x6E]),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  group('PlanImport', () {
    Future<Failure> failureOf(String text) async {
      final result = await const PlanImport()(
        ImportFile(name: 'x.csv', size: text.length, text: text),
      );
      return (result as Err).failure;
    }

    test('a header with no broker is unknown', () async {
      expect(
        await failureOf('date,amount\n1,2\n'),
        isA<UnknownBrokerFailure>(),
      );
    });

    test('a broken CSV is unparseable', () async {
      expect(
        await failureOf('refid,type\n"x,BUY\n'),
        isA<UnparseableCsvFailure>(),
      );
      expect(
        await failureOf('refid,type\nx,BUY,extra\n'),
        isA<UnparseableCsvFailure>(),
      );
    });

    test('a recognised export waits for its adapter', () async {
      expect(
        await failureOf('datetime,type,transaction_id\n2026,BUY,t1\n'),
        isA<UnsupportedFormatFailure>(),
      );
    });
  });
}
