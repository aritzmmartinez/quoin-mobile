import '../domain/coded.dart';

enum DiscardReason with Coded {
  swapUnpriced('swap-unpriced', affectsPosition: true),
  cryptoTransfer('crypto-transfer', affectsPosition: true),
  rewardUnpriced('reward-unpriced', affectsPosition: true),
  fxUnavailable('fx-unavailable', affectsPosition: true),
  invalidCryptoCode('invalid-crypto-code', affectsPosition: true),
  earnReturnUnverified('earn-return-unverified', affectsPosition: true),
  internalMove('internal-move', affectsPosition: false),
  cardSpending('card-spending', affectsPosition: false),
  savebackUnpaired('saveback-unpaired', affectsPosition: false),
  unsupportedAssetClass('unsupported-asset-class', affectsPosition: true),
  unsupported('unsupported', affectsPosition: false);

  const DiscardReason(this.code, {required this.affectsPosition});

  @override
  final String code;

  final bool affectsPosition;
}

enum NoticeReason with Coded {
  accountTransfer('account-transfer'),
  internalBookedAsReward('internal-booked-as-reward');

  const NoticeReason(this.code);

  @override
  final String code;
}

enum RowErrorReason with Coded {
  invalidDate('invalid-date'),
  invalidNumber('invalid-number'),
  missingInstrument('missing-instrument'),
  wrongFieldCount('wrong-field-count'),
  unexpected('unexpected');

  const RowErrorReason(this.code);

  @override
  final String code;
}

enum FileErrorReason with Coded {
  invalidEncoding('invalid-encoding'),
  unparseable('unparseable'),
  missingColumn('missing-column'),
  invalidNumber('invalid-number'),
  wrongFieldCount('wrong-field-count');

  const FileErrorReason(this.code);

  @override
  final String code;
}

final class DiscardDetail {
  const DiscardDetail({
    required this.date,
    required this.type,
    this.subtype,
    this.instrument,
    this.unpriced,
    this.affectsPosition,
  });

  final String date;
  final String type;
  final String? subtype;
  final String? instrument;

  final List<String>? unpriced;

  final bool? affectsPosition;
}

final class RowRef {
  const RowRef({this.externalId, this.position, this.date, this.type});

  factory RowRef.of(
      String? externalId, int position, String? date, String? type) {
    final id = externalId?.trim() ?? '';
    return RowRef(
      externalId: id.isEmpty ? null : id,
      position: id.isEmpty ? position : null,
      date: date,
      type: type,
    );
  }

  final String? externalId;
  final int? position;
  final String? date;
  final String? type;
}

final class RowError {
  const RowError(this.row, this.reason);

  final RowRef row;
  final RowErrorReason reason;
}

sealed class IngestRejection implements Exception {
  const IngestRejection();
}

final class CsvFileError extends IngestRejection {
  const CsvFileError(this.reason, {this.column, this.row});

  final FileErrorReason reason;

  final String? column;

  final RowRef? row;

  @override
  String toString() => 'The file cannot be imported: ${reason.code}';
}

final class KrakenLegacyExport extends IngestRejection {
  const KrakenLegacyExport();
}

final class KrakenBalanceMismatch extends IngestRejection {
  const KrakenBalanceMismatch(this.asset, this.wallet, this.date);

  final String asset;
  final String wallet;

  final String date;
}

final class InvalidLedgerEvent extends IngestRejection {
  const InvalidLedgerEvent(this.date, this.type, this.currency);

  final String date;
  final String type;
  final String currency;
}

final class MissingInstrument implements Exception {
  const MissingInstrument();
}
