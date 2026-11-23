import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';

Map<String, Object?> qr([Map<String, Object?> change = const {}]) => {
  'v': 1,
  'host': '192.168.1.20',
  'port': 3443,
  'sha256': 'AB' * 32,
  'token': 'one-use',
  'name': 'Test PC',
  ...change,
};

void main() {
  test('reads the QR, the pin in lowercase', () {
    final read = parsePairingQr(jsonEncode(qr()))!;
    expect(read.endpoint.host, '192.168.1.20');
    expect(read.endpoint.port, 3443);
    expect(read.endpoint.sha256, 'ab' * 32);
    expect(read.token, 'one-use');
    expect(read.name, 'Test PC');
  });

  test('refuses what is not a Quoin pairing QR of version 1', () {
    for (final text in [
      'https://example.com',
      '[]',
      jsonEncode(qr({'v': 2})),
      jsonEncode(qr({'port': 0})),
      jsonEncode(qr({'port': 70000})),
      jsonEncode(qr({'port': '3443'})),
      jsonEncode(qr({'sha256': 'ab' * 31})),
      jsonEncode(qr({'sha256': 'zz' * 32})),
      jsonEncode(qr({'token': ''})),
      jsonEncode(qr({'host': ''})),
      jsonEncode({...qr()}..remove('name')),
    ]) {
      expect(parsePairingQr(text), isNull, reason: text);
    }
  });
}
