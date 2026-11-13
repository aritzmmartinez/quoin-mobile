import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/sync/data/datasources/pinned_client.dart';
import 'package:quoin/src/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';

const _tls = 'test/features/sync/tls';

String pinOf(String pem) {
  final body = pem
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('-----'))
      .join();
  return sha256.convert(base64.decode(body)).toString();
}

void main() {
  late HttpServer server;
  late String pin;
  final heard = <String>[];

  setUp(() async {
    heard.clear();
    final cert = File('$_tls/cert.pem').readAsStringSync();
    pin = pinOf(cert);
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      SecurityContext()
        ..useCertificateChainBytes(utf8.encode(cert))
        ..usePrivateKey('$_tls/key.pem'),
    );
    server.listen((request) async {
      heard.add('${request.method} ${request.uri.path}');
      await utf8.decoder.bind(request).join();
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          request.uri.path == '/v1/pair'
              ? '{"token":"device-token"}'
              : '{"versions":[1],"name":"Test PC"}',
        );
      await request.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  SyncEndpoint at(String sha256) =>
      SyncEndpoint(host: '127.0.0.1', port: server.port, sha256: sha256);

  test('the certificate with the pin is trusted, with no CA nor host '
      'name', () async {
    expect(await SyncRemoteDataSource().hello(at(pin)), [1]);
    expect(heard, ['GET /v1/hello']);
  });

  test('another certificate is refused before the token is sent', () async {
    final other = '0' * 64;

    await expectLater(
      SyncRemoteDataSource().pair(
        at(other),
        token: 'one-use-token',
        deviceId: 'dev-phone',
        name: 'Phone',
      ),
      throwsA(
        isA<PinMismatchException>().having(
          (e) => e.presented,
          'presented',
          pin,
        ),
      ),
    );
    expect(heard, isEmpty);
  });

  test('a client for several pins trusts any of them and says which '
      'answered', () async {
    final client = PinnedClient.anyOf({'0' * 64, pin});
    final response = await client.get(
      Uri(
        scheme: 'https',
        host: '127.0.0.1',
        port: server.port,
        path: '/v1/hello',
      ),
    );
    client.close();

    expect(response.statusCode, 200);
    expect(client.presented, pin);
    expect(heard, ['GET /v1/hello']);
  });

  test('a client for several pins refuses any other before a byte of the '
      'request', () async {
    final client = PinnedClient.anyOf({'0' * 64, '1' * 64});
    await expectLater(
      client.get(
        Uri(
          scheme: 'https',
          host: '127.0.0.1',
          port: server.port,
          path: '/v1/hello',
        ),
      ),
      throwsA(isA<PinMismatchException>()),
    );
    client.close();
    expect(heard, isEmpty);
  });

  test('a PC that is not listening is not found', () async {
    final port = server.port;
    await server.close(force: true);

    await expectLater(
      SyncRemoteDataSource().hello(
        SyncEndpoint(host: '127.0.0.1', port: port, sha256: pin),
      ),
      throwsA(isA<NetworkException>()),
    );
  });
}
