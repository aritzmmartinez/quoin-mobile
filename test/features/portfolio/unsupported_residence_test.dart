import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/data/datasources/fx_local_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_local_datasource.dart';
import 'package:quoin/src/features/import/data/repositories/import_repository_impl.dart';
import 'package:quoin/src/features/portfolio/data/database/quoin_database.dart';
import 'package:quoin/src/features/portfolio/data/datasources/portfolio_local_datasource.dart';
import 'package:quoin/src/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';

import '../../helpers.dart';

const message =
    'Tu PC usa un territorio fiscal que esta versión de la app no conoce. '
    'Actualiza la app.';

Future<QuoinDatabase> unknownResidence() async {
  final db = memoryDatabase();
  await db.customStatement('UPDATE "Settings" SET "residence" = \'araba\'');
  return db;
}

void main() {
  test('the ledger says which residence it cannot read, not that '
      'storage failed', () async {
    final db = await unknownResidence();
    addTearDown(db.close);

    final loaded = await PortfolioRepositoryImpl(PortfolioLocalDataSource(db))
        .load();

    expect(
      loaded,
      isA<Err<Object?>>().having(
        (e) => e.failure,
        'failure',
        isA<UnsupportedResidenceFailure>().having(
          (f) => f.residence,
          'residence',
          'araba',
        ),
      ),
    );
  });

  test(
    'an import is refused with the same failure, not read as Bizkaia',
    () async {
      final db = await unknownResidence();
      addTearDown(db.close);

      final context = await ImportRepositoryImpl(
        const ImportFileDataSource(),
        ImportLocalDataSource(db),
        FxLocalDataSource(db),
      ).context();

      expect(
        context,
        isA<Err<Object?>>().having(
          (e) => e.failure,
          'failure',
          isA<UnsupportedResidenceFailure>(),
        ),
      );
    },
  );

  testWidgets('home, portfolio and the tax view say what to do', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      database: await unknownResidence(),
    );
    expect(find.text(message), findsOneWidget, reason: 'home');

    Future<void> openTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(QuoinBottomBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openTab('Cartera');
    expect(find.text(message), findsOneWidget, reason: 'portfolio');

    await openTab('Análisis');
    await tester.tap(find.text('Realizado'));
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget, reason: 'tax view');
    expect(find.text('No se ha podido leer la cartera'), findsNothing);
  });
}
