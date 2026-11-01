import 'package:quoin_core/quoin_core.dart';

/// A file the user picked, decoded.
final class ImportFile {
  const ImportFile({
    required this.name,
    required this.size,
    required this.text,
  });

  final String name;

  /// In bytes, as stored.
  final int size;
  final String text;
}

/// A row the import leaves out, or writes but wants the user to know about.
/// [reason] is Quoin's code (`fx-unavailable`, `account-transfer`…).
final class ImportWarning {
  const ImportWarning({
    required this.reason,
    required this.ts,
    required this.type,
    this.subtype,
    this.instrument,
  });

  final String reason;
  final DateTime ts;

  /// The row's type and subtype as the broker wrote them.
  final String type;
  final String? subtype;
  final String? instrument;
}

/// An export read into the ledger's terms: the instruments it mentions, its
/// events already normalised and, for each event, the operation it belongs to
/// (a swap's two legs are one operation).
final class ImportBatch {
  ImportBatch({
    required this.total,
    required this.instruments,
    required this.events,
    List<int>? operationOf,
    this.warnings = const [],
  }) : operationOf =
           operationOf ??
           List.generate(events.length, (i) => i, growable: false),
       assert(operationOf == null || operationOf.length == events.length);

  /// Rows read from the file.
  final int total;
  final List<Instrument> instruments;
  final List<LedgerEvent> events;
  final List<int> operationOf;
  final List<ImportWarning> warnings;

  /// How many operations write at least one new event, and how many are
  /// already stored whole, as Quoin's `countOperations`. [existing] holds the
  /// stored (source, externalId) keys.
  ({int imported, int duplicates}) countAgainst(
    Set<(String, String)> existing,
  ) {
    final writes = <int, bool>{};
    for (var i = 0; i < events.length; i += 1) {
      final event = events[i];
      final id = event.externalId;
      final isNew =
          id == null || id.isEmpty || !existing.contains((event.source, id));
      writes[operationOf[i]] = (writes[operationOf[i]] ?? false) || isNew;
    }
    final imported = writes.values.where((isNew) => isNew).length;
    return (imported: imported, duplicates: writes.length - imported);
  }
}

/// A batch and what writing it would do, or did.
final class ImportPreview {
  const ImportPreview({
    required this.batch,
    required this.imported,
    required this.duplicates,
    required this.zone,
  });

  final ImportBatch batch;
  final int imported;
  final int duplicates;

  /// The residence's zone, the one dates are shown in.
  final String zone;
}
