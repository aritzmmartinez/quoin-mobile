import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:quoin/src/core/error/exceptions.dart';

class PinnedClient extends http.BaseClient {
  PinnedClient(this.pin, {Duration connectTimeout = defaultConnectTimeout}) {
    final io = HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..connectionTimeout = connectTimeout
      ..badCertificateCallback = (cert, host, port) {
        final ok = sha256.convert(cert.der).toString() == pin;
        if (!ok) _mismatch = true;
        return ok;
      };
    _inner = IOClient(io);
  }

  static const defaultConnectTimeout = Duration(seconds: 5);

  final String pin;
  late final IOClient _inner;
  var _mismatch = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request);
    } on Exception {
      if (_mismatch) throw const PinMismatchException();
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
