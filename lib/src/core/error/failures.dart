sealed class Failure {
  const Failure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

sealed class ImportFailure extends Failure {
  const ImportFailure();
}

final class UnreadableFileFailure extends ImportFailure {
  const UnreadableFileFailure();
}

final class InvalidEncodingFailure extends ImportFailure {
  const InvalidEncodingFailure();
}

final class UnparseableCsvFailure extends ImportFailure {
  const UnparseableCsvFailure();
}

final class UnknownBrokerFailure extends ImportFailure {
  const UnknownBrokerFailure();
}

final class MissingColumnFailure extends ImportFailure {
  const MissingColumnFailure(this.column);

  final String column;
}

final class RowRejectedFailure extends ImportFailure {
  const RowRejectedFailure({
    this.externalId,
    this.position,
    required this.reason,
  });

  final String? externalId;
  final int? position;
  final String reason;
}

final class KrakenLegacyExportFailure extends ImportFailure {
  const KrakenLegacyExportFailure();
}

final class KrakenBalanceMismatchFailure extends ImportFailure {
  const KrakenBalanceMismatchFailure({
    required this.asset,
    required this.wallet,
    required this.date,
  });

  final String asset;
  final String wallet;

  final String date;
}

final class InvalidLedgerEventFailure extends ImportFailure {
  const InvalidLedgerEventFailure({
    required this.day,
    required this.type,
    required this.currency,
  });

  final String day;
  final String type;
  final String currency;
}
