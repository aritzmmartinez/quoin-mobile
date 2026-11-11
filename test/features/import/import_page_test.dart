import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quoin/src/app/app.dart';
import 'package:quoin/src/app/router.dart';
import 'package:quoin/src/features/import/data/datasources/ecb_remote_datasource.dart';
import 'package:quoin/src/features/import/data/datasources/import_file_datasource.dart';
import 'package:quoin/src/features/import/domain/entities/import_batch.dart';

import '../../helpers.dart';

class _Files implements ImportFileDataSource {
  const _Files(this.text);

  final String text;

  @override
  Future<ImportFile?> pick() async =>
      ImportFile(name: 'movimientos.csv', size: text.length, text: text);
}

final offline = httpClientProvider.overrideWithValue(
  MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  Future<void> open(WidgetTester tester, String location) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuoinApp)),
    );
    // Not awaited: the route's future completes when it is popped.
    container.read(routerProvider).push<void>(location).ignore();
    await tester.pumpAndSettle();
  }

  testWidgets('the sample batch goes through review, import and done', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {'locale': 'es'}, overrides: [offline]);
    await open(tester, Routes.importSample);

    expect(find.text('Revisa antes de importar'), findsOneWidget);
    expect(find.text('6'), findsOneWidget, reason: 'new operations');
    expect(find.text('5'), findsOneWidget, reason: 'warnings and errors');
    expect(
      find.textContaining('No se ha podido consultar el BCE'),
      findsOneWidget,
    );
    expect(find.text('Pagos con tarjeta'), findsOneWidget);
    expect(find.text('Clase de activo sin soporte'), findsOneWidget);
    expect(find.text('Con error'), findsOneWidget);
    expect(find.text('fila 12'), findsOneWidget);
    expect(
      find.textContaining('· Saveback'),
      findsWidgets,
      reason: 'a broker row type is shown by name, never as its code',
    );
    expect(find.textContaining('BENEFITS_SAVEBACK'), findsNothing);

    await tester.tap(find.text('Ver detalle'));
    await tester.pumpAndSettle();
    expect(find.text('Fondo Ejemplo Mundial'), findsWidgets);

    await tester.tap(find.text('Importar 6 operaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Importación completada'), findsOneWidget);
    expect(
      find.text('Se han guardado 6 operaciones en tu cartera'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver cartera actualizada'));
    await tester.pumpAndSettle();
    expect(find.text('Fondo Ejemplo Mundial'), findsOneWidget);

    await open(tester, Routes.importSample);
    expect(
      find.text(
        'Las operaciones duplicadas ya estaban en el registro y se omitirán',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nada que importar: ninguna operación'),
      findsOneWidget,
      reason: 'the set-aside operations are not duplicates',
    );
    final confirm = find.widgetWithText(FilledButton, 'Nada que importar');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });

  testWidgets('an unknown file opens the modal and nothing is written', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      overrides: [
        importFileDataSourceProvider.overrideWithValue(
          const _Files('fecha,importe\n2026-03-02,10\n'),
        ),
      ],
    );
    await open(tester, Routes.import);

    expect(find.text('Cómo exportar tus movimientos'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toca para seleccionar archivo'));
    await tester.pumpAndSettle();
    expect(find.text('movimientos.csv'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo procesar el archivo'), findsOneWidget);
    expect(find.textContaining('No reconozco este export'), findsOneWidget);
    expect(find.text('Tu cartera actual no se ha modificado.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Toca para seleccionar archivo'), findsOneWidget);

    await tester.tap(find.text('Toca para seleccionar archivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Cómo exportar tus movimientos'), findsNothing);
    expect(find.text('Aún no has importado ningún movimiento'), findsOneWidget);
  });

  testWidgets('a saveback pair that cannot be read is one failed operation, '
      'the saveback nested under its purchase', (tester) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      overrides: [
        importFileDataSourceProvider.overrideWithValue(
          const _Files(
            'datetime,category,type,asset_class,name,symbol,shares,price,'
            'amount,fee,tax,currency,transaction_id\n'
            '2025-12-01T08:00:00Z,CASH,BENEFITS_SAVEBACK,,,,,,15,,-2.85,EUR,'
            'QSAMPLE-s2\n'
            '2025-12-02T09:00:00Z,TRADING,BUY,FUND,Fondo QSAMPLE,,0.1215,100,'
            '-12.15,,,EUR,QSAMPLE-b2\n',
          ),
        ),
      ],
    );
    await open(tester, Routes.import);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toca para seleccionar archivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('QSAMPLE-b2'), findsOneWidget);
    expect(find.text('QSAMPLE-s2'), findsNothing);
    expect(find.textContaining('misma operación: Saveback'), findsOneWidget);
    expect(
      find.textContaining('Nada que importar: ninguna operación'),
      findsOneWidget,
    );
  });

  testWidgets('an old Kraken export is refused, naming why', (tester) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      overrides: [
        importFileDataSourceProvider.overrideWithValue(
          const _Files('txid,refid,time,type\nT1,R1,2026-03-02,trade\n'),
        ),
      ],
    );
    await open(tester, Routes.import);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toca para seleccionar archivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('export antiguo de Kraken'), findsOneWidget);
    expect(find.text('Tu cartera actual no se ha modificado.'), findsOneWidget);
  });

  testWidgets('every step fits at 200 % text size', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      overrides: [
        offline,
        importFileDataSourceProvider.overrideWithValue(
          const _Files('fecha,importe\n'),
        ),
      ],
    );
    await open(tester, Routes.import);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toca para seleccionar archivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Importar CSV'))).pop();
    await tester.pumpAndSettle();

    await open(tester, Routes.importSample);
    await tester.tap(find.text('Ver detalle'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar 6 operaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Importación completada'), findsOneWidget);
  });
}
