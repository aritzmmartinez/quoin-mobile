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
import 'package:quoin/src/features/import/presentation/widgets/broker_guides.dart';

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

    expect(find.text('Trade Republic · sample.csv'), findsOneWidget);
    expect(
      find.text('6 operaciones nuevas', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('No se ha podido consultar el BCE'),
      findsOneWidget,
    );
    expect(
      find.text('No son inversiones: se ignoran'),
      findsOneWidget,
      reason: 'card payments are a count of their own, not a warning',
    );
    expect(find.text('Advertencias'), findsNothing);
    expect(find.text('Clase de activo sin soporte'), findsOneWidget);
    expect(find.text('Sin soporte todavía'), findsNWidgets(2));
    expect(find.textContaining('Reparto de derechos'), findsOneWidget);
    expect(
      find.textContaining('INTERMEDIATE_SECURITIES'),
      findsNothing,
      reason: 'an unsupported row names its type in words',
    );
    expect(find.text('No se importan.'), findsOneWidget);
    expect(find.text('Con error'), findsOneWidget);
    expect(find.text('Fila 13'), findsOneWidget);
    await tester.ensureVisible(find.text('Otros descartes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otros descartes'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Saveback'),
      findsWidgets,
      reason: 'a broker row type is shown by name, never as its code',
    );
    expect(find.textContaining('BENEFITS_SAVEBACK'), findsNothing);

    await tester.ensureVisible(find.text('Ver detalle'));
    await tester.pumpAndSettle();
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
    expect(find.text('Ya importadas'), findsOneWidget);
    expect(
      find.textContaining('Nada que importar: ninguna operación'),
      findsOneWidget,
      reason: 'the set-aside operations are not duplicates',
    );
    final confirm = find.widgetWithText(FilledButton, 'Nada que importar');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });

  testWidgets('the review reads each text and each count on its own', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, prefs: {'locale': 'es'}, overrides: [offline]);
    await open(tester, Routes.importSample);

    void ownNode(Finder text, String label) {
      final node = tester.getSemantics(text);
      expect(node.label, label);
      expect(node.rect.height, lessThan(tester.getSize(text).height + 40));
    }

    for (final text in [
      'Trade Republic · sample.csv',
      'El resto ya estaba en tu cartera o no son inversiones.',
    ]) {
      ownNode(find.text(text), text);
    }
    final help = find.textContaining('Estas filas no se han importado');
    ownNode(help, tester.widget<Text>(help).data!);
    ownNode(find.text('Nuevas'), 'Nuevas, 6');
    ownNode(find.text('Ya importadas'), 'Ya importadas, 0');
    semantics.dispose();
  });

  testWidgets('step 1 joins the file and the guides; Continue waits for '
      'a file it recognises', (tester) async {
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

    expect(find.text('Sube tu CSV'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(find.byType(BrokerGuideRow), findsNWidgets(brokerGuides.length));
    expect(find.text('Desde la app · 4 pasos'), findsOneWidget);
    expect(
      find.text('Desde la web, no desde la app · 4 pasos'),
      findsOneWidget,
    );
    FilledButton continueButton() =>
        tester.widget(find.widgetWithText(FilledButton, 'Continuar'));
    expect(continueButton().onPressed, isNull, reason: 'no file yet');

    await tester.tap(find.text('Elige el CSV'));
    await tester.pumpAndSettle();
    expect(find.text('movimientos.csv'), findsOneWidget);
    expect(find.textContaining('No reconozco este export'), findsOneWidget);
    expect(find.text('Reconocido por las columnas del fichero'), findsNothing);
    expect(continueButton().onPressed, isNull, reason: 'nothing to read it as');

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige el CSV'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Sube tu CSV'), findsNothing);
    expect(find.text('Sin posiciones todavía'), findsOneWidget);
  });

  testWidgets('a broker guide opens its numbered steps', (tester) async {
    await pumpApp(tester, prefs: {'locale': 'es'});
    await open(tester, Routes.import);

    await tester.tap(find.text('Trade Republic'));
    await tester.pumpAndSettle();
    expect(find.text('Se exporta desde la app del móvil'), findsOneWidget);
    for (final step in ['1', '2', '3', '4']) {
      expect(find.text(step), findsOneWidget);
    }
    expect(
      find.text('Entra en Perfil (o Cuenta).', findRichText: true),
      findsOneWidget,
      reason: 'the asterisks mark what to tap and are not shown',
    );
    expect(find.textContaining('*', findRichText: true), findsNothing);
    expect(find.textContaining('las repetidas se detectan'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Se exporta desde la app del móvil'), findsNothing);
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
    await tester.tap(find.text('Elige el CSV'));
    await tester.pumpAndSettle();
    expect(
      find.text('Reconocido por las columnas del fichero'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Trade Republic · movimientos.csv'), findsOneWidget);
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
    await tester.tap(find.text('Elige el CSV'));
    await tester.pumpAndSettle();
    expect(
      find.text('Reconocido por las columnas del fichero'),
      findsOneWidget,
    );
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
    for (final target in ['Kraken', 'Entendido', 'Elige el CSV']) {
      await tester.ensureVisible(find.text(target));
      await tester.pumpAndSettle();
      await tester.tap(find.text(target));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('No reconozco este export'), findsOneWidget);
    Navigator.of(tester.element(find.text('Importar CSV'))).pop();
    await tester.pumpAndSettle();

    await open(tester, Routes.importSample);
    for (final fold in ['Otros descartes', 'Ver detalle']) {
      await tester.ensureVisible(find.text(fold));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fold));
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar 6 operaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Importación completada'), findsOneWidget);
  });
}
