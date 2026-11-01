import '../domain/coded.dart';

enum Broker with Coded {
  tradeRepublic('trade-republic'),
  kraken('kraken');

  const Broker(this.code);

  @override
  final String code;

  String get signature => switch (this) {
        Broker.tradeRepublic => 'transaction_id',
        Broker.kraken => 'refid',
      };
}

final _lineEnd = RegExp(r'\r?\n');
final _separator = RegExp('[,;\t|]');
final _quoted = RegExp(r'^"(.*)"$');

Broker? detectBroker(String csv) {
  final text = csv.startsWith('﻿') ? csv.substring(1) : csv;
  final header =
      text.split(_lineEnd).where((line) => line.trim().isNotEmpty).firstOrNull;
  if (header == null) return null;
  final columns = {
    for (final cell in header.split(_separator))
      cell
          .trim()
          .replaceFirstMapped(_quoted, (m) => m[1]!)
          .trim()
          .toLowerCase(),
  };
  final matched = [
    for (final broker in Broker.values)
      if (columns.contains(broker.signature)) broker,
  ];
  return matched.length == 1 ? matched.single : null;
}
