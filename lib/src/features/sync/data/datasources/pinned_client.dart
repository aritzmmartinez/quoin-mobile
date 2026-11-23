import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:quoin/src/core/error/exceptions.dart';

class PinnedClient extends http.BaseClient {
  PinnedClient(String pin, {Duration connectTimeout = defaultConnectTimeout})
    : this.anyOf({pin}, connectTimeout: connectTimeout);

  PinnedClient.anyOf(
    this.pins, {
    Duration connectTimeout = defaultConnectTimeout,
  }) {
    final io = HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..connectionTimeout = connectTimeout
      ..badCertificateCallback = (cert, host, port) {
        final sha = sha256.convert(cert.der).toString();
        presented = sha;
        return pins.contains(sha);
      };
    _inner = IOClient(io);
  }

  static const defaultConnectTimeout = Duration(seconds: 5);

  final Set<String> pins;
  late final IOClient _inner;
  String? presented;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request);
    } on Exception {
      if (presented case final sha? when !pins.contains(sha)) {
        throw PinMismatchException(sha);
      }
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
