import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/sync/data/datasources/pinned_client.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/pc_state.dart';

final syncRemoteDataSourceProvider = Provider((ref) => SyncRemoteDataSource());

typedef ClientFor = http.Client Function(SyncEndpoint endpoint);

typedef Credentials = ({String token, String deviceId});

class SyncRemoteDataSource {
  SyncRemoteDataSource({
    ClientFor? clientFor,
    this.timeout = const Duration(seconds: 30),
    this.pairTimeout = const Duration(seconds: 75),
    Future<void> Function(Duration)? wait,
  }) : _clientFor = clientFor ?? ((e) => PinnedClient(e.sha256)),
       _wait = wait ?? Future<void>.delayed;

  final ClientFor _clientFor;
  final Duration timeout;
  final Duration pairTimeout;
  final Future<void> Function(Duration) _wait;
  static const longestWait = Duration(seconds: 5);

  Future<List<int>> hello(SyncEndpoint endpoint) async =>
      switch (await _json(endpoint, 'GET', '/v1/hello')) {
        {'versions': final List<Object?> versions} => [
          for (final v in versions)
            if (v is int) v,
        ],
        _ => throw const SyncHttpException(200, 'invalid-response'),
      };

  Future<String> pair(
    SyncEndpoint endpoint, {
    required String token,
    required String deviceId,
    required String name,
  }) async => switch (await _json(
    endpoint,
    'POST',
    '/v1/pair',
    body: {'token': token, 'deviceId': deviceId, 'name': name},
    timeout: pairTimeout,
    retry: false,
  )) {
    {'token': final String device} when device.isNotEmpty => device,
    _ => throw const SyncHttpException(200, 'invalid-response'),
  };

  Future<PcState> fetch(SyncEndpoint endpoint, Credentials who) async {
    final response = await _send(endpoint, 'GET', '/v1/sync', who: who);
    final etag = response.headers['etag'];
    if (etag == null || etag.isEmpty) {
      throw const SyncHttpException(200, 'invalid-response');
    }
    final bytes = response.bodyBytes;
    try {
      final exchange = await Isolate.run(
        () => parseExchange(jsonDecode(utf8.decode(bytes))),
      );
      return PcState(exchange: exchange, etag: etag);
    } on UnsupportedSchemaVersion catch (e) {
      final found = e.found;
      throw SyncHttpException(
        200,
        'unsupported-schema-version',
        update: found is int && found > syncSchemaVersion ? 'client' : 'server',
      );
    } on Exception {
      throw const SyncHttpException(200, 'invalid-exchange');
    }
  }

  Future<PushResult> push(
    SyncEndpoint endpoint,
    Credentials who,
    Exchange exchange, {
    required String etag,
  }) async {
    final body = await _json(
      endpoint,
      'POST',
      '/v1/sync',
      who: who,
      headers: {'If-Match': etag},
      body: exchange.toJson(),
    );
    final status = switch (body) {
      {'status': 'applied'} => PushStatus.applied,
      {'status': 'up-to-date'} => PushStatus.upToDate,
      {'status': 'conflicts'} => PushStatus.conflicts,
      _ => throw const SyncHttpException(200, 'invalid-response'),
    };
    return PushResult(
      status: status,
      setAside: switch (body) {
        {'setAside': final List<Object?> keys} => [
          for (final k in keys)
            if (k is String) k,
        ],
        _ => const [],
      },
    );
  }

  Future<List<PriceAnswer>> prices(
    SyncEndpoint endpoint,
    Credentials who,
    List<PriceHolding> holdings,
  ) async {
    final response = await _send(
      endpoint,
      'POST',
      '/v1/prices',
      who: who,
      body: {
        'instruments': [for (final h in holdings) h.toJson()],
      },
    );
    final bytes = response.bodyBytes;
    try {
      return await Isolate.run(
        () => switch (jsonDecode(utf8.decode(bytes))) {
          {'instruments': final List<Object?> answers} => [
            for (final a in answers) parsePriceAnswer(a),
          ],
          _ => throw const InvalidPriceAnswer('no instruments'),
        },
      );
    } on Exception {
      throw const SyncHttpException(200, 'invalid-response');
    }
  }

  Future<Object?> _json(
    SyncEndpoint endpoint,
    String method,
    String path, {
    Credentials? who,
    Map<String, String> headers = const {},
    Object? body,
    Duration? timeout,
    bool retry = true,
  }) async {
    final response = await _send(
      endpoint,
      method,
      path,
      who: who,
      headers: headers,
      body: body,
      timeout: timeout,
      retry: retry,
    );
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw SyncHttpException(response.statusCode, 'invalid-response');
    }
  }

  Future<http.Response> _send(
    SyncEndpoint endpoint,
    String method,
    String path, {
    Credentials? who,
    Map<String, String> headers = const {},
    Object? body,
    Duration? timeout,
    bool retry = true,
  }) async {
    Future<http.Response> once() => _sendOnce(
      endpoint,
      method,
      path,
      who: who,
      headers: headers,
      body: body,
      timeout: timeout ?? this.timeout,
    );
    try {
      return await once();
    } on SyncHttpException catch (e) {
      final wait = e.retryAfter;
      if (!retry ||
          (e.status != 503 && e.status != 429) ||
          wait == null ||
          wait > longestWait) {
        rethrow;
      }
      await _wait(wait);
      return once();
    }
  }

  Future<http.Response> _sendOnce(
    SyncEndpoint endpoint,
    String method,
    String path, {
    required Credentials? who,
    required Map<String, String> headers,
    required Object? body,
    required Duration timeout,
  }) async {
    final url = Uri(
      scheme: 'https',
      host: endpoint.host,
      port: endpoint.port,
      path: path,
    );
    final request = http.Request(method, url)
      ..headers.addAll({
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip',
        if (who != null) ...{
          'Authorization': 'Bearer ${who.token}',
          'X-Quoin-Device': who.deviceId,
        },
        ...headers,
      });
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..headers['Content-Encoding'] = 'gzip'
        ..bodyBytes = gzip.encode(utf8.encode(jsonEncode(body)));
    }
    final client = _clientFor(endpoint);
    final http.Response response;
    try {
      response = await http.Response.fromStream(await client.send(request))
          .timeout(timeout);
    } on PinMismatchException {
      rethrow;
    } on Exception catch (e) {
      throw NetworkException(e);
    } finally {
      client.close();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw _refusal(response);
  }
}

SyncHttpException _refusal(http.Response response) {
  Object? body;
  try {
    body = jsonDecode(utf8.decode(response.bodyBytes));
  } on FormatException {
    body = null;
  }
  final seconds = int.tryParse(response.headers['retry-after'] ?? '');
  return SyncHttpException(
    response.statusCode,
    switch (body) {
      {'error': final String code} => code,
      _ => 'http-${response.statusCode}',
    },
    retryAfter: seconds == null ? null : Duration(seconds: seconds),
    update: switch (body) {
      {'update': final String side} => side,
      _ => null,
    },
  );
}
