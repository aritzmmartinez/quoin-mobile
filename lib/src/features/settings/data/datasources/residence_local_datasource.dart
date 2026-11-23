import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart'
    show quoinDatabaseProvider;

final residenceLocalDataSourceProvider = Provider<ResidenceLocalDataSource>(
  (ref) => ResidenceLocalDataSource(ref.watch(quoinDatabaseProvider)),
);

class ResidenceLocalDataSource {
  ResidenceLocalDataSource(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final QuoinDatabase _db;
  final DateTime Function() _now;

  Future<String> read() => _guard(
    () async => (await _db.select(_db.settings).getSingle()).residence,
  );

  /// A residence never chosen has no mark, and choosing the one it already
  /// holds is still a choice: it is marked so it travels to the PC. Saving it
  /// again unchanged writes nothing.
  Future<void> write(String residence) => _guard(
    () => _db.transaction(() async {
      final row = await _db.select(_db.settings).getSingle();
      if (row.residence == residence && row.residenceHlc != null) return;
      final hlc = await _db.stamp(_now().millisecondsSinceEpoch);
      await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(
          residence: Value(residence),
          residenceHlc: Value(hlc),
        ),
      );
    }),
  );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw StorageException(e);
    }
  }
}
