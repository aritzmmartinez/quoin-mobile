import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  test('a transaction_id column is Trade Republic', () {
    expect(
      detectBroker('datetime,type,transaction_id\n2026-01-01,BUY,x\n'),
      Broker.tradeRepublic,
    );
  });

  test('a refid column is Kraken', () {
    expect(detectBroker('txid,refid,time,type\n'), Broker.kraken);
  });

  test('columns are trimmed, lowercased and lose a BOM', () {
    expect(detectBroker('﻿RefID ,type\n'), Broker.kraken);
    expect(detectBroker('\n\n  Transaction_ID\n'), Broker.tradeRepublic);
  });

  test('both signatures, neither, or nothing at all is no broker', () {
    expect(detectBroker('refid,transaction_id\n'), isNull);
    expect(detectBroker('date,amount\n1,2\n'), isNull);
    expect(detectBroker(''), isNull);
  });

  test('only the header is read', () {
    expect(detectBroker('refid\n"unclosed\n'), Broker.kraken);
  });

  test('codes are the ones Quoin stores', () {
    expect(Broker.values.map((b) => b.code), ['trade-republic', 'kraken']);
  });
}
