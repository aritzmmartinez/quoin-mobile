import 'package:quoin_core/src/decimal/dec.dart';

enum QuoteSource { yahoo, kraken }

QuoteSource quoteSourceOf(String symbol) =>
    symbol.contains('/') ? QuoteSource.kraken : QuoteSource.yahoo;

const _quoteCurrency = {'USDG': 'USD'};

String krakenSymbolFor(String code) => '$code/${_quoteCurrency[code] ?? 'EUR'}';

String? effectiveKrakenSymbol({
  required String type,
  required String id,
  required String? quoteSymbol,
}) {
  if (quoteSymbol != null && quoteSourceOf(quoteSymbol) == QuoteSource.kraken) {
    return quoteSymbol;
  }
  return type == 'CRYPTO' ? krakenSymbolFor(id) : null;
}

final class KrakenQuote {
  const KrakenQuote({
    required this.symbol,
    required this.price,
    required this.currency,
    required this.asOf,
  });

  final String symbol;
  final String price;
  final String currency;
  final DateTime asOf;

  Map<String, Object?> toJson() => {
        'symbol': symbol,
        'price': price,
        'currency': currency,
        'asOf': asOf.toIso8601String(),
      };
}

sealed class KrakenReading<T> {
  const KrakenReading();
}

final class KrakenRead<T> extends KrakenReading<T> {
  const KrakenRead(this.value);

  final T value;
}

final class KrakenError<T> extends KrakenReading<T> {
  const KrakenError(this.error);

  final String error;
}

const _unknownPair = {'EQuery:Unknown asset pair', 'EQuery:Invalid asset pair'};

final _decimal = RegExp(r'^\d+(\.\d+)?$');

typedef _Rows = ({List<Object?> rows, Object? last});

KrakenReading<_Rows?> _rowsOf(Object? json) {
  final body = json is Map<String, Object?> ? json : null;
  final error = body?['error'];
  if (error is! List<Object?>) return const KrakenError('no error field');
  if (error.isNotEmpty) {
    final errors = [for (final e in error) '$e'];
    return errors.every(_unknownPair.contains)
        ? const KrakenRead(null)
        : KrakenError(errors.join('; '));
  }
  final result = body?['result'];
  final keys = result is Map<String, Object?>
      ? [
          for (final k in result.keys)
            if (k != 'last') k
        ]
      : const <String>[];
  final rows = keys.length == 1 ? (result! as Map)[keys.single] : null;
  if (rows is! List<Object?>) return const KrakenError('no single pair');
  return KrakenRead((rows: rows, last: (result! as Map)['last']));
}

KrakenQuote _quoteOf(String symbol, String price, int seconds) => KrakenQuote(
      symbol: symbol,
      price: Dec.parse(price).toString(),
      currency: symbol.substring(symbol.indexOf('/') + 1),
      asOf: DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true),
    );

KrakenReading<List<KrakenQuote>> readKrakenOhlc(Object? json, String symbol) {
  final List<Object?> rows;
  final num last;
  switch (_rowsOf(json)) {
    case KrakenError(:final error):
      return KrakenError(error);
    case KrakenRead(value: null):
      return const KrakenRead([]);
    case KrakenRead(value: (rows: final r, last: final num l)):
      rows = r;
      last = l;
    case KrakenRead():
      return const KrakenError('no last');
  }
  final quotes = <KrakenQuote>[
    for (final row in rows)
      if (row case [final num time, _, _, _, final String close, ...]
          when time <= last && _decimal.hasMatch(close))
        _quoteOf(symbol, close, time.toInt()),
  ]..sort((a, b) => a.asOf.compareTo(b.asOf));
  return KrakenRead(quotes);
}

KrakenReading<KrakenQuote?> readKrakenTrade(Object? json, String symbol) {
  final Object? trade;
  switch (_rowsOf(json)) {
    case KrakenError(:final error):
      return KrakenError(error);
    case KrakenRead(:final value):
      trade = value == null || value.rows.isEmpty ? null : value.rows.last;
  }
  if (trade is! List<Object?>) return const KrakenRead(null);
  final price = trade.isEmpty ? null : trade[0];
  if (price is! String || !_decimal.hasMatch(price)) {
    return const KrakenError('no price');
  }
  final time = trade.length > 2 ? trade[2] : null;
  if (time is! num) return const KrakenError('no time');
  return KrakenRead(_quoteOf(symbol, price, time.floor()));
}
