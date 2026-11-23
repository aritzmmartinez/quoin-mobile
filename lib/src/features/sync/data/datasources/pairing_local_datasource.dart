import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:quoin/src/core/error/exceptions.dart';

final pairingLocalDataSourceProvider = Provider(
  (ref) => const PairingLocalDataSource(FlutterSecureStorage()),
);

class PairingLocalDataSource {
  const PairingLocalDataSource(this._storage);

  static const key = 'pairings';
  static const legacyKey = 'pairing';

  final FlutterSecureStorage _storage;

  Future<Map<String, Object?>> read() => _guard(() async {
    final text = await _storage.read(key: key);
    final legacy = await _storage.read(key: legacyKey);
    if (text != null) {
      if (legacy != null) await _storage.delete(key: legacyKey);
      return _object(text) ?? const {};
    }
    if (legacy == null) return const {};
    final moved = {
      'pcs': [?_object(legacy)],
      'pricesFrom': null,
    };
    await _storage.write(key: key, value: jsonEncode(moved));
    await _storage.delete(key: legacyKey);
    return moved;
  });

  Future<void> write(Map<String, Object?> pairings) =>
      _guard(() => _storage.write(key: key, value: jsonEncode(pairings)));

  static String detailKey(String sha256) => 'syncDetail:$sha256';

  Future<Map<String, Object?>?> readDetail(String sha256) => _guard(
    () async => switch (await _storage.read(key: detailKey(sha256))) {
      final text? => _object(text),
      null => null,
    },
  );

  Future<void> writeDetail(String sha256, Map<String, Object?> detail) =>
      _guard(
        () => _storage.write(key: detailKey(sha256), value: jsonEncode(detail)),
      );

  Future<void> deleteDetail(String sha256) =>
      _guard(() => _storage.delete(key: detailKey(sha256)));

  Map<String, Object?>? _object(String text) => switch (jsonDecode(text)) {
    final Map<String, Object?> json => json,
    _ => null,
  };

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
