import 'package:quoin_core/quoin_core.dart';

typedef RateConflict = ({String currency, String day});

final class ImportFile {
  const ImportFile({
    required this.name,
    required this.size,
    required this.text,
  });

  final String name;

  final int size;
  final String text;
}

final class ImportPreview {
  const ImportPreview({
    required this.broker,
    required this.batch,
    required this.counts,
    required this.zone,
    this.ratesUnavailable = const [],
    this.rateConflicts = const [],
  });

  final Broker broker;
  final MappedBatch batch;
  final OperationCounts counts;

  final String zone;
  final List<String> ratesUnavailable;
  final List<RateConflict> rateConflicts;

  int get toWrite => operationsToWrite(counts);

  ImportPreview counted(OperationCounts counts) => ImportPreview(
    broker: broker,
    batch: batch,
    counts: counts,
    zone: zone,
    ratesUnavailable: ratesUnavailable,
    rateConflicts: rateConflicts,
  );
}
