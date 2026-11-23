import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/import_repository_impl.dart';
import 'package:quoin_core/quoin_core.dart' show IngestContext;

import '../../helpers.dart';

void main() {
  test('an import never values a row with prices stored here', () async {
    final db = (await sampleStores()).database;
    addTearDown(db.close);

    final context = await ImportRepositoryImpl(
      const ImportFileDataSource(),
      ImportLocalDataSource(db),
      FxLocalDataSource(db),
    ).context();

    expect(
      context,
      isA<Ok<IngestContext>>().having((c) => c.value.prices, 'prices', isEmpty),
    );
  });
}
