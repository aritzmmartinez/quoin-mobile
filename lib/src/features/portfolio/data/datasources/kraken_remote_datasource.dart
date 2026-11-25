import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';

const krakenTimeout = Duration(seconds: 15);
const krakenSpacing = Duration(seconds: 1);

class KrakenQueue {
  KrakenQueue({
    this.spacing = krakenSpacing,
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final Duration spacing;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;
  Future<void> _tail = Future.value();
  DateTime? _last;

  Future<void> turn() {
    final mine = _tail.then((_) async {
      if (_last case final last?) {
        final wait = last.add(spacing).difference(_now());
        if (wait > Duration.zero) await _wait(wait);
      }
      _last = _now();
    });
    _tail = mine;
    return mine;
  }
}

final krakenQueueProvider = Provider((ref) => KrakenQueue());

final krakenRemoteDataSourceProvider = Provider(
  (ref) => KrakenRemoteDataSource(
    ref.watch(httpClientProvider),
    ref.watch(krakenQueueProvider),
  ),
);

Uri krakenUrl(String path, Map<String, String> query) =>
    Uri.https('api.kraken.com', '/0/public/$path', query);

class KrakenRemoteDataSource {
  const KrakenRemoteDataSource(
    this._client,
    this._queue, {
    this.timeout = krakenTimeout,
  });

  final http.Client _client;
  final KrakenQueue _queue;
  final Duration timeout;

  /// The closed daily candles after [since], or every one Kraken keeps (720)
  /// when it is null.
  Future<List<KrakenQuote>> candles(String symbol, DateTime? since) => _ask(
    krakenUrl('OHLC', {
      'pair': symbol,
      'interval': '1440',
      'since': since == null
          ? '0'
          : '${since.millisecondsSinceEpoch ~/ 1000 - 1}',
    }),
    (json) => readKrakenOhlc(json, symbol),
  );

  Future<KrakenQuote?> lastTrade(String symbol) => _ask(
    krakenUrl('Trades', {'pair': symbol, 'count': '1'}),
    (json) => readKrakenTrade(json, symbol),
  );

  Future<T> _ask<T>(Uri url, KrakenReading<T> Function(Object?) read) async {
    await _queue.turn();
    final http.Response response;
    try {
      response = await _client.get(url).timeout(timeout);
    } on Exception catch (e) {
      throw NetworkException(e);
    }
    if (response.statusCode != 200) {
      throw NetworkException(response.body, statusCode: response.statusCode);
    }
    final Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException catch (e) {
      throw NetworkException(e, statusCode: 200);
    }
    return switch (read(json)) {
      KrakenRead(:final value) => value,
      KrakenError(:final error) => throw NetworkException(
        error,
        statusCode: 200,
      ),
    };
  }
}
