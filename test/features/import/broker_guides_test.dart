import 'package:flutter/painting.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';
import 'package:quoin/src/features/import/domain/repositories/import_repository.dart';
import 'package:quoin/src/features/import/domain/usecases/pick_import_file.dart';
import 'package:quoin/src/features/import/presentation/widgets/broker_guides.dart';
import 'package:quoin/src/ui/atoms/marked_span.dart';
import 'package:quoin_core/quoin_core.dart';

class _Picked implements ImportRepository {
  const _Picked(this.text);

  final String text;

  @override
  Future<Result<ImportFile?>> pickFile() async =>
      Ok(ImportFile(name: 'x.csv', size: text.length, text: text));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('every broker Quoin reads has one guide, with steps', () {
    expect(brokerGuides.map((g) => g.broker).toSet(), Broker.values.toSet());
    expect(brokerGuides.length, Broker.values.length);
    expect(brokerGuides.every((g) => g.steps.isNotEmpty), isTrue);
  });

  test(
    'a chosen file comes back with its broker, read from the header',
    () async {
      Future<Broker?> brokerOf(String text) async =>
          switch (await PickImportFile(_Picked(text))()) {
            Ok(:final value) => value?.broker,
            Err() => null,
          };
      expect(
        await brokerOf('datetime,type,transaction_id\n'),
        Broker.tradeRepublic,
      );
      expect(await brokerOf('txid,refid,time\n'), Broker.kraken);
      expect(await brokerOf('fecha,importe\n'), isNull);
    },
  );

  test('the header is read through a UTF-8 BOM and CRLF line ends', () {
    // Invented exports, as the picker hands them over: bytes, decoded first.
    Broker? brokerOf(List<int> bytes) => ImportFile(
      name: 'x.csv',
      size: bytes.length,
      text: decodeExport(bytes),
    ).recognized().broker;
    const bom = [0xEF, 0xBB, 0xBF];
    const tradeRepublic =
        'datetime,category,type,amount,currency,transaction_id\r\n'
        '2026-03-02T09:00:00Z,TRADING,BUY,-10,EUR,QSAMPLE-1\r\n';
    const kraken =
        'txid,refid,time,type,subtype,aclass,asset,wallet,amount,fee,balance'
        '\r\nTQSAMPLE,RQSAMPLE,2026-03-02 09:00:00,deposit,,currency,EUR,'
        'spot / main,10,0,10\r\n';
    for (final (csv, broker) in [
      (tradeRepublic, Broker.tradeRepublic),
      (kraken, Broker.kraken),
    ]) {
      expect(brokerOf([...bom, ...utf8.encode(csv)]), broker, reason: 'BOM');
      expect(brokerOf(utf8.encode(csv)), broker, reason: 'CRLF');
    }
    expect(brokerOf([...bom, ...utf8.encode('fecha,importe\r\n')]), isNull);
  });

  test('asterisks mark the strong parts and are dropped', () {
    const strong = TextStyle(fontWeight: FontWeight.w600);
    final span = starredSpan('Entra en *Perfil* (o *Cuenta*).', strong);
    expect(span.toPlainText(), 'Entra en Perfil (o Cuenta).');
    final parts = (span as TextSpan).children!.cast<TextSpan>();
    expect(
      [
        for (final p in parts)
          if (p.style == strong) p.text,
      ],
      ['Perfil', 'Cuenta'],
    );
  });
}
