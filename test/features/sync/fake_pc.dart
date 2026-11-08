import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin_core/quoin_core.dart';

/// A PC that answers the sync API as Quoin does (`docs/sync-api.md`), with
/// its store modelled by quoin_core's `merge` and `applyPlan`, the contract
/// both sides share. Tests script its prices and its failures.
class FakePc {
  FakePc(SyncState state, {this.nowMs = 1761600120000})
    : device = LocalDevice(state: state, lastHlc: null);

  static const deviceToken = 'device-token';
  static const qrToken = 'qr-token';

  LocalDevice device;
  final int nowMs;

  /// Every request, as `METHOD /path`.
  final log = <String>[];

  /// The body of every pairing and prices request.
  final bodies = <String, List<Object?>>{};

  List<int> versions = const [1];

  /// Answers queued per path, sent before any real one, as
  /// `(status, body, headers)`.
  final scripted = <String, List<(int, Object?, Map<String, String>)>>{};

  /// Runs once before the next `POST /v1/sync` is handled, as another write
  /// on the PC between the phone's read and its write would.
  void Function()? beforePush;

  /// Answers to `POST /v1/prices`, queued per instrument; with none left the
  /// PC answers a full empty series.
  final prices = <String, List<Map<String, Object?>>>{};

  String get etag =>
      '"${sha256.convert(utf8.encode(jsonEncode(device.state.toJson())))}"';

  late final http.Client client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    final key = '${request.method} $path';
    log.add(key);
    if (scripted[key] case [final first, ...]) {
      scripted[key]!.removeAt(0);
      final (status, body, headers) = first;
      return _json(status, body, headers);
    }

    final body = request.bodyBytes.isEmpty
        ? null
        : jsonDecode(
            utf8.decode(
              request.headers['content-encoding'] == 'gzip'
                  ? gzip.decode(request.bodyBytes)
                  : request.bodyBytes,
            ),
          );
    if (key == 'GET /v1/hello') {
      return _json(200, {'versions': versions, 'name': 'Test PC'});
    }
    if (key == 'POST /v1/pair') {
      (bodies[key] ??= []).add(body);
      return switch (body) {
        {'token': qrToken} => _json(200, {'token': deviceToken}),
        _ => _json(401, {'error': 'invalid-token'}),
      };
    }
    if (request.headers['authorization'] != 'Bearer $deviceToken' ||
        request.headers['x-quoin-device'] == null) {
      return _json(401, {'error': 'unauthorized'});
    }
    switch (key) {
      case 'GET /v1/sync':
        final (:exchange, device: _) = exportDevice(
          device,
          nowMs,
          deviceName: 'Test PC',
        );
        return _json(200, exchange.toJson(), {'etag': etag});
      case 'POST /v1/sync':
        beforePush?.call();
        beforePush = null;
        if (request.headers['if-match'] != etag) {
          return _json(409, {'error': 'state-changed'});
        }
        final incoming = parseExchange(body);
        if (incoming.deviceId != request.headers['x-quoin-device']) {
          return _json(403, {'error': 'device-mismatch'});
        }
        final plan = merge(device.state, incoming, const {});
        if (plan.conflicts.isNotEmpty) {
          return _json(200, {'status': 'conflicts', 'setAside': <String>[]});
        }
        final changes = plan.changesData;
        device = applyPlan(device, plan.apply, nowMs);
        return _json(200, {
          'status': changes ? 'applied' : 'up-to-date',
          'counts': planCounts(plan, device.state).toJson(),
          'setAside': [for (final row in plan.setAside) row.key],
        });
      case 'POST /v1/prices':
        (bodies[key] ??= []).add(body);
        final asked = (body! as Map<String, Object?>)['instruments']!;
        return _json(200, {
          'instruments': [
            for (final h in asked as List<Object?>)
              _price((h! as Map<String, Object?>)['instrumentId']! as String),
          ],
        });
    }
    return _json(404, {'error': 'not-found'});
  }

  Map<String, Object?> _price(String id) {
    final queue = prices[id];
    if (queue != null && queue.isNotEmpty) return queue.removeAt(0);
    return {
      'instrumentId': id,
      'kind': 'full',
      'seriesVersion': 'empty',
      'rows': <Object?>[],
    };
  }

  http.Response _json(
    int status,
    Object? body, [
    Map<String, String> headers = const {},
  ]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json', ...headers},
  );
}
