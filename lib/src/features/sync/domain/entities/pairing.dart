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
    this.pcDeviceId,
    this.shared = false,
  });

  final SyncEndpoint endpoint;
  final String token;
  final String pcName;
  final DateTime pairedAt;
  final DateTime? lastSyncAt;
  final bool confirmed;

  final String? pcDeviceId;
  final bool shared;

  String get sha256 => endpoint.sha256;

  Pairing copy({
    SyncEndpoint? endpoint,
    String? pcName,
    DateTime? lastSyncAt,
    bool? confirmed,
    String? pcDeviceId,
    bool? shared,
  }) => Pairing(
    endpoint: endpoint ?? this.endpoint,
    token: token,
    pcName: pcName ?? this.pcName,
    pairedAt: pairedAt,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    confirmed: confirmed ?? this.confirmed,
    pcDeviceId: pcDeviceId ?? this.pcDeviceId,
    shared: shared ?? this.shared,
  );

  Pairing synced(DateTime at) => copy(lastSyncAt: at, confirmed: true);
}

final class Pairings {
  const Pairings({this.pcs = const [], this.pricesFrom});

  final List<Pairing> pcs;
  final String? pricesFrom;

  Pairing? of(String sha256) =>
      pcs.where((p) => p.sha256 == sha256).firstOrNull;

  Pairing? twinOf(Pairing pc) => pcs
      .where(
        (p) =>
            p.sha256 != pc.sha256 &&
            !p.shared &&
            p.pcDeviceId != null &&
            p.pcDeviceId == pc.pcDeviceId,
      )
      .firstOrNull;

  Pairings put(Pairing pairing) => Pairings(
    pcs: [
      for (final p in pcs)
        if (p.sha256 == pairing.sha256) pairing else p,
      if (of(pairing.sha256) == null) pairing,
    ],
    pricesFrom: pairing.shared && pricesFrom == pairing.sha256
        ? null
        : pricesFrom,
  );

  Pairings without(String sha256) => Pairings(
    pcs: [
      for (final p in pcs)
        if (p.sha256 != sha256) p,
    ],
    pricesFrom: pricesFrom == sha256 ? null : pricesFrom,
  );

  Pairings pricesFromPc(String? sha256) =>
      Pairings(pcs: pcs, pricesFrom: sha256);
}
