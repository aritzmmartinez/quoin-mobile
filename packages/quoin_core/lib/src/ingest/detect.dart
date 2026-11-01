import '../domain/coded.dart';
import 'csv.dart';

/// The brokers whose exports Quoin reads. There is no picker: the header says
/// which one a file comes from.
enum Broker with Coded {
  tradeRepublic('trade-republic'),
  kraken('kraken');

  const Broker(this.code);

  @override
  final String code;

  /// The column only this broker's export has.
  String get signature => switch (this) {
        Broker.tradeRepublic => 'transaction_id',
        Broker.kraken => 'refid',
      };
}

/// The broker whose signature column the header has, or null when it has none
/// or both. Columns are compared trimmed, lowercased and without a BOM.
Broker? detectBroker(String csv) {
  final header = csvRecords(csv).firstOrNull?.$2;
  if (header == null) return null;
  final columns = {
    for (final cell in header)
      cell.replaceFirst(RegExp('^﻿'), '').trim().toLowerCase(),
  };
  final matched = [
    for (final broker in Broker.values)
      if (columns.contains(broker.signature)) broker,
  ];
  return matched.length == 1 ? matched.single : null;
}
