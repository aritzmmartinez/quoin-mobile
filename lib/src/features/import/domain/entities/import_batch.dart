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
    required this.batch,
    required this.imported,
    required this.duplicates,
    required this.zone,
    this.ratesUnavailable = const [],
    this.rateConflicts = const [],
  });

  final MappedBatch batch;
  final int imported;
  final int duplicates;

  final String zone;
  final List<String> ratesUnavailable;
  final List<RateConflict> rateConflicts;

  ImportPreview counted(({int imported, int duplicates}) counts) =>
      ImportPreview(
        batch: batch,
        imported: counts.imported,
        duplicates: counts.duplicates,
        zone: zone,
        ratesUnavailable: ratesUnavailable,
        rateConflicts: rateConflicts,
      );
}
