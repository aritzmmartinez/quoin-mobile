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
