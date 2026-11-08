import 'dart:convert';

final class SyncEndpoint {
  const SyncEndpoint({
    required this.host,
    required this.port,
    required this.sha256,
  });

  final String host;
  final int port;
  final String sha256;
}

final class PairingQr {
  const PairingQr({
    required this.endpoint,
    required this.token,
    required this.name,
  });

  final SyncEndpoint endpoint;
  final String token;
  final String name;
}

final _pin = RegExp(r'^[0-9a-fA-F]{64}$');

PairingQr? parsePairingQr(String text) {
  final Object? raw;
  try {
    raw = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (raw
      case {
        'v': 1,
        'host': final String host,
        'port': final int port,
        'sha256': final String sha256,
        'token': final String token,
        'name': final String name,
      }
      when host.isNotEmpty &&
          port > 0 &&
          port < 65536 &&
          _pin.hasMatch(sha256) &&
          token.isNotEmpty) {
    return PairingQr(
      endpoint: SyncEndpoint(
        host: host,
        port: port,
        sha256: sha256.toLowerCase(),
      ),
      token: token,
      name: name,
    );
  }
  return null;
}

final class Pairing {
  const Pairing({
    required this.endpoint,
    required this.token,
    required this.pcName,
    required this.pairedAt,
    this.lastSyncAt,
    this.confirmed = false,
  });

  final SyncEndpoint endpoint;
  final String token;
  final String pcName;
  final DateTime pairedAt;
  final DateTime? lastSyncAt;
  final bool confirmed;

  Pairing synced(DateTime at) => Pairing(
    endpoint: endpoint,
    token: token,
    pcName: pcName,
    pairedAt: pairedAt,
    lastSyncAt: at,
    confirmed: true,
  );
}
