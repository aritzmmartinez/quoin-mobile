sealed class Failure {
  const Failure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

/// A remote service was unavailable; nothing the user can fix but wait.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Why an import stopped before writing anything.
sealed class ImportFailure extends Failure {
  const ImportFailure();
}

/// The picked file could not be opened.
final class UnreadableFileFailure extends ImportFailure {
  const UnreadableFileFailure();
}

/// The picked file is not UTF-8 text.
final class InvalidEncodingFailure extends ImportFailure {
  const InvalidEncodingFailure();
}

/// The file is not a comma-separated CSV: an unclosed quote, another
/// separator, a row with the wrong number of fields.
final class UnparseableCsvFailure extends ImportFailure {
  const UnparseableCsvFailure();
}

/// The header matches no broker Quoin reads, or more than one.
final class UnknownBrokerFailure extends ImportFailure {
  const UnknownBrokerFailure();
}

/// The broker was recognised, but this build cannot read its rows yet.
final class UnsupportedFormatFailure extends ImportFailure {
  const UnsupportedFormatFailure();
}

/// A row the import would write breaks the ledger's rules: a fault in how the
/// export was read, not in the file.
final class InvalidLedgerEventFailure extends ImportFailure {
  const InvalidLedgerEventFailure({
    required this.ts,
    required this.type,
    required this.currency,
  });

  final DateTime ts;
  final String type;
  final String currency;
}
