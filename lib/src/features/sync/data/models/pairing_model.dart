import 'package:quoin/src/features/sync/domain/entities/pairing.dart';

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
  };
}

Pairing? pairingFromJson(Map<String, Object?> json) {
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
    );
  }
  return null;
}
