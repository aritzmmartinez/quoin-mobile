import 'package:quoin_core/quoin_core.dart' show SyncDetail;

import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';

extension PairingModel on Pairing {
  Map<String, Object?> toJson() => {
    'host': endpoint.host,
    'port': endpoint.port,
    'sha256': endpoint.sha256,
    'token': token,
    'pcName': pcName,
    'pairedAt': pairedAt.toUtc().toIso8601String(),
    'lastSyncAt': lastSyncAt?.toUtc().toIso8601String(),
    'confirmed': confirmed,
    'pcDeviceId': pcDeviceId,
    'shared': shared,
  };
}

extension PairingsModel on Pairings {
  Map<String, Object?> toJson() => {
    'pcs': [for (final p in pcs) p.toJson()],
    'pricesFrom': pricesFrom,
  };
}

Pairing? pairingFromJson(Object? json) {
  if (json case {
    'host': final String host,
    'port': final int port,
    'sha256': final String sha256,
    'token': final String token,
    'pcName': final String pcName,
    'pairedAt': final String pairedAt,
    'lastSyncAt': final String? lastSyncAt,
    'confirmed': final bool confirmed,
  }) {
    final paired = DateTime.tryParse(pairedAt);
    final synced = lastSyncAt == null ? null : DateTime.tryParse(lastSyncAt);
    if (paired == null || (lastSyncAt != null && synced == null)) return null;
    return Pairing(
      endpoint: SyncEndpoint(host: host, port: port, sha256: sha256),
      token: token,
      pcName: pcName,
      pairedAt: paired,
      lastSyncAt: synced,
      confirmed: confirmed,
      pcDeviceId: json['pcDeviceId'] as String?,
      shared: json['shared'] == true,
    );
  }
  return null;
}

Pairings pairingsFromJson(Map<String, Object?> json) {
  final pcs = [
    for (final raw in json['pcs'] as List<Object?>? ?? const [])
      ?pairingFromJson(raw),
  ];
  final from = json['pricesFrom'] as String?;
  return Pairings(
    pcs: pcs,
    pricesFrom: pcs.any((p) => p.sha256 == from && !p.shared) ? from : null,
  );
}

extension LastSyncModel on LastSync {
  Map<String, Object?> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'toPhone': toPhone.toJson(),
    'toPc': toPc.toJson(),
  };
}

LastSync? lastSyncFromJson(Map<String, Object?>? json) => switch (json) {
  {'at': final String at} when DateTime.tryParse(at) != null => LastSync(
    at: DateTime.parse(at),
    toPhone: SyncDetail.fromJson(json['toPhone']),
    toPc: SyncDetail.fromJson(json['toPc']),
  ),
  _ => null,
};
