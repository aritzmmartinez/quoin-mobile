import 'package:quoin_core/src/decimal/dec.dart';
import 'package:quoin_core/src/sync/exchange.dart' show isIsoInstant;

final class PriceRow {
  const PriceRow({
    required this.asOf,
    required this.price,
    required this.currency,
    required this.source,
  });

  final String asOf;
  final String price;
  final String currency;
  final String source;

  DateTime get instant => DateTime.parse(asOf);

  Map<String, Object?> toJson() =>
      {'asOf': asOf, 'price': price, 'currency': currency, 'source': source};
}

final class PriceHolding {
  const PriceHolding({
    required this.instrumentId,
    required this.seriesVersion,
    required this.last,
  });

  final String instrumentId;
  final String? seriesVersion;
  final String? last;

  Map<String, Object?> toJson() => {
        'instrumentId': instrumentId,
        'seriesVersion': seriesVersion,
        'last': last,
      };
}

PriceHolding holdingOf(
  String instrumentId,
  String? seriesVersion,
  List<PriceRow> rows,
) {
  if (rows.isEmpty) {
    return PriceHolding(
        instrumentId: instrumentId, seriesVersion: null, last: null);
  }
  var newest = rows.first;
  for (final row in rows.skip(1)) {
    if (row.instant.isAfter(newest.instant)) newest = row;
  }
  return PriceHolding(
    instrumentId: instrumentId,
    seriesVersion: seriesVersion,
    last: newest.asOf,
  );
}

sealed class PriceAnswer {
  const PriceAnswer(this.instrumentId);

  final String instrumentId;
}

final class PendingPrices extends PriceAnswer {
  const PendingPrices(super.instrumentId);
}

final class FullPrices extends PriceAnswer {
  const FullPrices(super.instrumentId,
      {required this.seriesVersion, required this.rows});

  final String seriesVersion;
  final List<PriceRow> rows;
}

final class TailPrices extends PriceAnswer {
  const TailPrices(
    super.instrumentId, {
    required this.seriesVersion,
    required this.from,
    required this.rows,
  });

  final String seriesVersion;
  final String from;
  final List<PriceRow> rows;
}

class InvalidPriceAnswer implements Exception {
  const InvalidPriceAnswer(this.issue);

  final String issue;

  @override
  String toString() => 'InvalidPriceAnswer: $issue';
}

PriceAnswer parsePriceAnswer(Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw const InvalidPriceAnswer('not an object');
  }
  String text(Map<String, Object?> map, String key) => switch (map[key]) {
        final String value when value.isNotEmpty => value,
        _ => throw InvalidPriceAnswer('$key is not a string'),
      };
  String instant(Map<String, Object?> map, String key) {
    final value = text(map, key);
    if (!isIsoInstant(value)) throw InvalidPriceAnswer('$key: $value');
    return value;
  }

  List<PriceRow> rows() => switch (raw['rows']) {
        final List<Object?> list => [
            for (final row in list)
              if (row is Map<String, Object?>)
                PriceRow(
                  asOf: instant(row, 'asOf'),
                  price: _decimal(text(row, 'price')),
                  currency: text(row, 'currency'),
                  source: text(row, 'source'),
                )
              else
                throw const InvalidPriceAnswer('a row is not an object'),
          ],
        _ => throw const InvalidPriceAnswer('rows is not a list'),
      };

  final id = text(raw, 'instrumentId');
  return switch (raw['kind']) {
    'pending' => PendingPrices(id),
    'full' =>
      FullPrices(id, seriesVersion: text(raw, 'seriesVersion'), rows: rows()),
    'tail' => TailPrices(
        id,
        seriesVersion: text(raw, 'seriesVersion'),
        from: instant(raw, 'from'),
        rows: rows(),
      ),
    final kind => throw InvalidPriceAnswer('kind $kind'),
  };
}

String _decimal(String value) {
  try {
    Dec.parse(value);
    return value;
  } on Object {
    throw InvalidPriceAnswer('price $value');
  }
}

List<PriceRow> applyPriceAnswer(List<PriceRow> rows, PriceAnswer answer) {
  final after = switch (answer) {
    PendingPrices() => rows,
    FullPrices(rows: final incoming) => incoming,
    TailPrices(:final from, rows: final incoming) => [
        for (final row in rows)
          if (row.instant.isBefore(DateTime.parse(from))) row,
        ...incoming,
      ],
  };
  return [...after]..sort((a, b) => a.instant.compareTo(b.instant));
}
