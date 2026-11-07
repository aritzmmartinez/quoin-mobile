import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'prices_database.g.dart';

@DriftDatabase(include: {'prices.drift'})
class PricesDatabase extends _$PricesDatabase {
  PricesDatabase(super.executor);

  PricesDatabase.open()
    : super(
        driftDatabase(
          name: 'quoin_prices',
          native: DriftNativeOptions(databaseDirectory: _directory),
        ),
      );

  static Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}prices')
        .create(recursive: true);
  }

  @override
  int get schemaVersion => 1;
}
