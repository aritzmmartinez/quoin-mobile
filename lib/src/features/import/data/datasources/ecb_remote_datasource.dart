import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final ecbRemoteDataSourceProvider = Provider(
  (ref) => EcbRemoteDataSource(ref.watch(httpClientProvider)),
);

const ecbTimeout = Duration(seconds: 60);

final _ecbCode = RegExp(r'^[A-Z]{3}$');

Uri ecbRatesUrl(String quote, String from, String to) => Uri.https(
  'data-api.ecb.europa.eu',
  '/service/data/EXR/D.$quote.$baseCurrency.SP00.A',
  {
    'startPeriod': from,
    'endPeriod': to,
    'format': 'csvdata',
    'detail': 'dataonly',
  },
);

class EcbRemoteDataSource {
  const EcbRemoteDataSource(this._client, {this.timeout = ecbTimeout});

  final http.Client _client;
  final Duration timeout;

  Future<List<FxRate>> rates(String quote, String from, String to) async {
    if (!_ecbCode.hasMatch(quote)) return const [];
    final http.Response response;
    try {
      response = await _client
          .get(ecbRatesUrl(quote, from, to))
          .timeout(timeout);
    } on Exception catch (e) {
      throw NetworkException(e);
    }
    final body = response.body;
    if (response.statusCode == 404 && _isNotFound(body)) return const [];
    if (response.statusCode != 200) {
      throw NetworkException(body, statusCode: response.statusCode);
    }
    try {
      return parseEcbCsv(body, quote);
    } on Exception catch (e) {
      throw NetworkException(e, statusCode: response.statusCode);
    }
  }
}

bool _isNotFound(String body) {
  try {
    final json = jsonDecode(body);
    return json is Map && json['title'] == 'Not Found';
  } on FormatException {
    return false;
  }
}

const _columns = [
  'FREQ',
  'CURRENCY',
  'CURRENCY_DENOM',
  'TIME_PERIOD',
  'OBS_VALUE',
];

final _positiveDecimal = RegExp(r'^\d+(\.\d+)?$');

List<FxRate> parseEcbCsv(String body, String quote) {
  if (body.trim().isEmpty) return const [];
  final table = parseCsv(body);
  final missing = _columns.where((c) => !table.fields.contains(c)).toList();
  if (missing.isNotEmpty) {
    throw FormatException('ECB CSV is missing ${missing.join(', ')}');
  }

  final rates = <FxRate>[];
  for (final (index, row) in table.rows.indexed) {
    final at = 'ECB CSV row ${index + 2}';
    if (row['FREQ'] != 'D') {
      throw FormatException('$at: frequency ${row['FREQ']}');
    }
    if (row['CURRENCY'] != quote) {
      throw FormatException(
        '$at: currency ${row['CURRENCY']}, asked for $quote',
      );
    }
    if (row['CURRENCY_DENOM'] != baseCurrency) {
      throw FormatException('$at: denominator ${row['CURRENCY_DENOM']}');
    }
    final day = row['TIME_PERIOD']!;
    try {
      CalendarDate.parse(day);
    } on RangeError {
      throw FormatException('$at: day "$day"');
    }
    final value = row['OBS_VALUE']!;
    if (value.isEmpty) continue;
    if (!_positiveDecimal.hasMatch(value) || !Dec.parse(value).isPositive) {
      throw FormatException('$at: rate "$value"');
    }
    rates.add(
      FxRate(
        source: ecbSource,
        base: baseCurrency,
        quote: quote,
        day: day,
        rate: Dec.parse(value),
      ),
    );
  }
  return rates..sort((a, b) => a.day.compareTo(b.day));
}
