import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

typedef Json = Map<String, Object?>;

void main() {
  final contract = jsonDecode(
    File('test/contract/sync-pairing.json').readAsStringSync(),
  ) as Json;

  group('sync pairing contract', () {
    for (final raw in contract['cases']! as List<Object?>) {
      final c = raw! as Json;
      test(c['name']! as String, () {
        expect(
          pairingCode(c['token']! as String, c['deviceId']! as String),
          (c['expect']! as Json)['code'],
        );
      });
    }
  });
}
