import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:quoin/src/core/error/exceptions.dart';

final pairingLocalDataSourceProvider = Provider(
  (ref) => const PairingLocalDataSource(FlutterSecureStorage()),
);

class PairingLocalDataSource {
  const PairingLocalDataSource(this._storage);

  static const key = 'pairing';

  final FlutterSecureStorage _storage;

  Future<Map<String, Object?>?> read() => _guard(() async {
    final text = await _storage.read(key: key);
    if (text == null) return null;
    final json = jsonDecode(text);
    return json is Map<String, Object?> ? json : null;
  });

  Future<void> write(Map<String, Object?> pairing) =>
      _guard(() => _storage.write(key: key, value: jsonEncode(pairing)));

  Future<void> delete() => _guard(() => _storage.delete(key: key));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
